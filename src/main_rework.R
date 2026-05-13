library(stringr)
library(car)
library(lmtest)
library(dplyr)

# Thiết lập thư mục làm việc về vị trí chứa script
local({
  file_flag <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_flag) > 0) {
    # Rscript: sử dụng đối số --file=
    setwd(dirname(normalizePath(sub("^--file=", "", file_flag[1]))))
  } else if (!file.exists("All_GPUs.csv") && file.exists("src/All_GPUs.csv")) {
    # VSCode interactive từ gốc workspace: di chuyển vào thư mục src/
    setwd("src")
  }
})

# BƯỚC 1: TẢI VÀ KHẢO SÁT SƠ BỘ DỮ LIỆU
# Đọc file dữ liệu thô: 3.406 quan sát x 34 biến
raw_data <- read.csv("All_GPUs.csv",
  stringsAsFactors = FALSE,
)

# Khảo sát sơ bộ dữ liệu (Bỏ comment để xem kết quả trên console)
# str(raw_data)
# summary(raw_data)
# print(colSums(is.na(raw_data)))

# QUY TRÌNH XỬ LÝ MỚI BẮT ĐẦU TỪ ĐÂY

# --------- CHỌN LỌC BIẾN BAN ĐẦU ----------

kept_vars <- c(
  "Name", "Release_Price", "Max_Power", "Memory", "Memory_Bandwidth",
  "Core_Speed", "Release_Date", "Manufacturer", "Memory_Type"
)

# ==========================================================
# VẼ BIỂU ĐỒ TỶ LỆ DỮ LIỆU KHUYẾT (MISSING DATA)
# ==========================================================
if (!dir.exists("figures")) {
  dir.create("figures")
}

# Đếm NA và các chuỗi rỗng/không hợp lệ
missing_count <- sapply(raw_data, function(col) {
  if (is.character(col)) {
    cleaned <- str_trim(col)
    sum(is.na(col) | cleaned == "" | cleaned == "-")
  } else {
    sum(is.na(col))
  }
})
missing_pct <- round(100 * missing_count / nrow(raw_data), 2)

missing_df <- data.frame(
  variable = names(missing_pct),
  pct = as.numeric(missing_pct),
  kept = names(missing_pct) %in% kept_vars
)
missing_df <- missing_df[order(-missing_df$pct), ]

# Phân loại biến để trực quan hóa
other_vars <- missing_df[!missing_df$kept & missing_df$pct < 30, ]
avg_other_pct <- mean(other_vars$pct)
other_count <- nrow(other_vars)

missing_df_plot <- rbind(
  missing_df[missing_df$kept | missing_df$pct >= 30, ],
  data.frame(
    variable = paste("Trung bình các biến khác", sprintf("(%d)", other_count)),
    pct = avg_other_pct,
    kept = FALSE
  )
)

# Thiết lập màu sắc cho biểu đồ (Xanh: Giữ, Đỏ: Loại >= 30%, Xám: Khác)
bar_colors_plot <- with(
  missing_df_plot,
  ifelse(kept, "#2c7fb8",
    ifelse(pct >= 30, "#e34a33", "#bdbdbd")
  )
)

# Xuất biểu đồ tỷ lệ dữ liệu khuyết
png("figures/missing_data_ratio.png",
  type = "cairo",
  width = 2400, height = 1400, res = 300
)
par(mar = c(5, 15, 4, 2))
barplot(rev(missing_df_plot$pct),
  names.arg = rev(missing_df_plot$variable),
  horiz = TRUE, las = 1,
  col = rev(bar_colors_plot),
  xlim = c(0, 100),
  xlab = "Tỷ lệ dữ liệu khuyết (%)",
  main = paste("Tỷ lệ dữ liệu khuyết (N =", nrow(raw_data), ")"),
  cex.names = 0.85, cex.main = 1.05
)
abline(v = 30, col = "red", lty = 2, lwd = 1.5)
legend("bottomright",
  legend = c("Biến được chọn", "Bị loại (thiếu >= 30%)", "Các biến khác"),
  fill = c("#2c7fb8", "#e34a33", "#bdbdbd"),
  cex = 0.85, bty = "n"
)
dev.off()
cat("\n--- Đã xuất figures/missing_data_ratio.png ---\n")

selected_data <- raw_data %>% select(all_of(kept_vars))

# -------- LÀM SẠCH DỮ LIỆU -----------

# Thay thế các chuỗi rỗng, dấu gạch ngang và "N/A" thành giá trị NA thực sự
selected_data <- selected_data %>%
  mutate(across(
    where(is.character),
    ~ ifelse(str_trim(.) %in% c("", "-", "NA", "N/A"), NA, str_trim(.))
  ))


# Loại bỏ các GPU của Intel (Tại thời điểm 2017 Intel chưa đóng góp nhiều vào thị trường card rời)
clean_data <- selected_data %>% filter(Manufacturer != "Intel")

# Loại bỏ các dòng không có giá niêm yết (biến phụ thuộc Y)
clean_data <- clean_data %>% filter(!is.na(Release_Price))

# Đồng nhất nhãn: chuyển "ATI" thành "AMD"
clean_data <- clean_data %>%
  mutate(Manufacturer = str_replace(Manufacturer, "ATI", "AMD"))

# Loại bỏ các mẫu GPU không phù hợp (Quadro, Crossfire, SLI, chưa phát hành, Titan)
clean_data <- clean_data %>%
  filter(!str_detect(Name, regex("Quadro|Crossfire|SLI|not[ .]released|Titan", ignore_case = TRUE)))

num_row_clean <- nrow(clean_data)

cat("Dữ liệu sau khi làm sạch sơ bộ: N =", num_row_clean, "\n")


# ------------ Xử lý Năm phát hành và Trích xuất số từ chuỗi --------------

# Tách Năm từ cột Release_Date, đổi tên thành Release_Year và xóa cột gốc
clean_data <- clean_data %>%
  mutate(Release_Year = as.integer(format(as.Date(Release_Date, "%d-%b-%Y"), "%Y"))) %>%
  select(-Release_Date)

# Trích xuất giá trị số từ các cột có đơn vị (MHz, MB, Watt...)
clean_data <- clean_data %>%
  mutate(
    Release_Price = as.numeric(str_extract(Release_Price, "\\d+\\.?\\d*")),
    Max_Power = as.numeric(str_extract(Max_Power, "\\d+\\.?\\d*")),
    Memory = as.numeric(str_extract(Memory, "\\d+\\.?\\d*")),
    Memory_Bandwidth = as.numeric(str_extract(Memory_Bandwidth, "\\d+\\.?\\d*")),
    Core_Speed = as.numeric(str_extract(Core_Speed, "\\d+\\.?\\d*"))
  )

# ------ Chuyển đổi các biến định danh sang kiểu Factor ------

clean_data <- clean_data %>%
  mutate(
    Manufacturer = as.factor(Manufacturer),
    Memory_Type = as.factor(Memory_Type)
  )

# ------------------ NHẬN DIỆN NGOẠI LAI (RANH GIỚI TUKEY) -----------------
cat("\n--- NHẬN DIỆN NGOẠI LAI (Tukey 1.5 * IQR) ---\n")
calc_tukey <- function(vec) {
  v <- na.omit(vec)
  q1 <- quantile(v, 0.25)
  q3 <- quantile(v, 0.75)
  iqr <- q3 - q1
  list(q1 = q1, q3 = q3, iqr = iqr, lower = q1 - 1.5 * iqr, upper = q3 + 1.5 * iqr)
}

price_bnd <- calc_tukey(clean_data$Release_Price)

cat(sprintf("Ranh giới Release_Price (N=%d):\n", nrow(clean_data)))
cat(sprintf(
  "Q1=%.0f, Q3=%.0f, IQR=%.0f, Ngưỡng trên=%.2f\n",
  price_bnd$q1, price_bnd$q3, price_bnd$iqr, price_bnd$upper
))

outliers_count <- sum(clean_data$Release_Price > price_bnd$upper, na.rm = TRUE)
cat(sprintf(
  "=> Phát hiện %d quan sát là ngoại lai (Giá > %.2f)\n",
  outliers_count, price_bnd$upper
))

# Trực quan hóa ngoại lai qua Boxplot
if (!dir.exists("figures")) dir.create("figures")
png("figures/boxplot_outliers.png", type = "cairo", width = 1600, height = 800, res = 200)
par(mfrow = c(1, 2), mar = c(5, 5, 4, 2))
boxplot(clean_data$Release_Price,
  main = "Phân phối giá (Thang đo gốc)",
  col = "lightblue", ylab = "USD", outline = TRUE
)
abline(h = price_bnd$upper, col = "red", lty = 2, lwd = 2)

boxplot(clean_data$Release_Price,
  main = "Phân phối giá (Thang đo Log)",
  col = "lightgreen", ylab = "USD (log scale)", log = "y", outline = TRUE
)
abline(h = price_bnd$upper, col = "red", lty = 2, lwd = 2)
par(mfrow = c(1, 1))
dev.off()
cat("--- Đã xuất figures/boxplot_outliers.png ---\n")

# Cấu hình BẬT/TẮT chế độ loại bỏ ngoại lai (True = Xóa, False = Giữ lại)
REMOVE_OUTLIERS <- TRUE
if (REMOVE_OUTLIERS) {
  clean_data <- clean_data %>% filter(Release_Price <= price_bnd$upper | is.na(Release_Price))
  cat(sprintf("=> Đã loại bỏ ngoại lai. Dữ liệu còn lại: %d quan sát\n", nrow(clean_data)))
} else {
  cat("=> Quyết định GIỮ LẠI các ngoại lai để huấn luyện mô hình.\n")
}

# ---------------- Chia tập dữ liệu Huấn luyện và Kiểm tra (tỷ lệ 9:1) -----------
set.seed(2026252) # Đảm bảo tính tái lập kết quả
train_indices <- sample(1:nrow(clean_data), size = 0.9 * nrow(clean_data))

train_data <- clean_data[train_indices, ]
test_data <- clean_data[-train_indices, ]

cat("Dữ liệu sau khi chia: Train (N = ", nrow(train_data), "), Test (N = ", nrow(test_data), ")\n", sep = "")

# ------------------ ĐIỀN KHUYẾT DỮ LIỆU (IMPUTATION) -----------------
# 1. Trích xuất dung lượng VRAM trực tiếp từ tên GPU (Feature Extraction)
extract_vram <- function(df) {
  df %>%
    mutate(
      mem_str = str_extract(Name, regex("\\b(\\d+)\\s*(GB|G|MB)\\b", ignore_case = TRUE)),
      mem_val = as.numeric(str_extract(mem_str, "\\d+")),
      mem_val = ifelse(str_detect(mem_str, regex("GB|G\\b", ignore_case = TRUE)), mem_val * 1024, mem_val),
      Memory = ifelse(is.na(Memory) & !is.na(mem_val), mem_val, Memory)
    ) %>%
    select(-mem_str, -mem_val)
}

train_data <- extract_vram(train_data)
test_data <- extract_vram(test_data)

# 2. Phương án dự phòng: Điền Mode/Median bằng tham số từ tập Train (Tránh rò rỉ dữ liệu - Data Leakage)
get_mode <- function(v) {
  uniqv <- unique(na.omit(v))
  uniqv[which.max(tabulate(match(v, uniqv)))]
}

# Tính toán các tham số điền khuyết dựa trên tập huấn luyện (Train)
impute_params <- list(
  Memory = get_mode(train_data$Memory),
  Memory_Type = get_mode(train_data$Memory_Type),
  Manufacturer = get_mode(train_data$Manufacturer),
  Core_Speed = median(train_data$Core_Speed, na.rm = TRUE),
  Release_Year = median(train_data$Release_Year, na.rm = TRUE),
  Max_Power = median(train_data$Max_Power, na.rm = TRUE),
  Memory_Bandwidth = median(train_data$Memory_Bandwidth, na.rm = TRUE)
)

# Hàm áp dụng các tham số đã tính để điền giá trị NA
apply_imputation <- function(df, params) {
  df %>% mutate(
    Memory = replace(Memory, is.na(Memory), params$Memory),
    Memory_Type = replace(Memory_Type, is.na(Memory_Type), params$Memory_Type),
    Manufacturer = replace(Manufacturer, is.na(Manufacturer), params$Manufacturer),
    Core_Speed = replace(Core_Speed, is.na(Core_Speed), params$Core_Speed),
    Release_Year = replace(Release_Year, is.na(Release_Year), params$Release_Year),
    Max_Power = replace(Max_Power, is.na(Max_Power), params$Max_Power),
    Memory_Bandwidth = replace(Memory_Bandwidth, is.na(Memory_Bandwidth), params$Memory_Bandwidth)
  )
}

# Áp dụng điền khuyết cho cả hai tập dữ liệu
train_data <- apply_imputation(train_data, impute_params)
test_data <- apply_imputation(test_data, impute_params)

# Kiểm tra số lượng giá trị NA sau khi xử lý
cat("Số dòng NA của train_data sau khi điền khuyết:\n")
cat(paste(names(train_data), colSums(is.na(train_data)), sep = ": ", collapse = ", "), "\n")
cat("Số dòng NA của test_data sau khi điền khuyết:\n")
cat(paste(names(test_data), colSums(is.na(test_data)), sep = ": ", collapse = ", "), "\n")

# ------------------ TIỀN BIẾN ĐỔI DỮ LIỆU -----------------
# Thực hiện Log-transform cho biến Bandwidth trước khi chuẩn hóa
train_data <- train_data %>% mutate(log_Memory_Bandwidth = log(Memory_Bandwidth))
test_data <- test_data %>% mutate(log_Memory_Bandwidth = log(Memory_Bandwidth))


# ------------------ SO SÁNH MÔ HÌNH MLR VÀ LOG-LINEAR ---------
# 1A. Xây dựng mô hình hồi quy tuyến tính bội cơ bản (Linear)
mlr_model_linear <- lm(
  `Release_Price` ~ `Max_Power` + `Memory` + `Memory_Bandwidth` +
    `Core_Speed` + Manufacturer + `Memory_Type` + `Release_Year`,
  data = train_data
)

# 1B. Xây dựng mô hình hồi quy Log-Linear (Nâng cao)
mlr_model_log <- lm(
  log(`Release_Price`) ~ `Max_Power` + `Memory` + `log_Memory_Bandwidth` +
    `Core_Speed` + Manufacturer + `Memory_Type` + `Release_Year`,
  data = train_data
)

# 2. Kiểm tra chỉ số VIF để phát hiện đa cộng tuyến
check_vif <- function(name, model) {
  vif_values <- vif(model)

  cat("\n--- Kiểm tra VIF (", name, ") ---\n")
  print(vif_values)
}

check_vif("MLR Cơ bản", mlr_model_linear)
check_vif("Log-Linear", mlr_model_log)

# ------------------ CÁC KIỂM ĐỊNH THỐNG KÊ CHO BÁO CÁO LATEX ---------
cat("\n\n===========================================\n")
cat("KIỂM ĐỊNH THỐNG KÊ (DÀNH CHO BÁO CÁO LATEX)\n")
cat("===========================================\n")

# 1. Welch's ANOVA: So sánh giá phát hành trung bình giữa Nvidia và AMD
cat("\n--- 1. Kiểm định Welch's ANOVA (Giá ~ Hãng sản xuất) ---\n")
anova_result <- oneway.test(Release_Price ~ Manufacturer, data = train_data, var.equal = FALSE)
print(anova_result)

# Thống kê chi tiết theo từng hãng
amd_prices <- train_data$Release_Price[train_data$Manufacturer == "AMD"]
nv_prices <- train_data$Release_Price[train_data$Manufacturer == "Nvidia"]
cat(sprintf(
  "AMD: n=%d, mean=%.2f, median=%.2f, sd=%.2f\n",
  length(amd_prices), mean(amd_prices, na.rm = TRUE), median(amd_prices, na.rm = TRUE), sd(amd_prices, na.rm = TRUE)
))
cat(sprintf(
  "NVIDIA: n=%d, mean=%.2f, median=%.2f, sd=%.2f\n",
  length(nv_prices), mean(nv_prices, na.rm = TRUE), median(nv_prices, na.rm = TRUE), sd(nv_prices, na.rm = TRUE)
))

# 2. Kiểm định Phương sai đồng nhất (Breusch-Pagan Test) cho mô hình Log-Linear
cat("\n--- 2. Kiểm định Breusch-Pagan (Homoscedasticity) cho Log-Linear ---\n")
bp_test_result <- bptest(mlr_model_log)
print(bp_test_result)

# 3. Kiểm định Phân phối chuẩn của Phần dư (Shapiro-Wilk Test)
cat("\n--- 3. Kiểm định Shapiro-Wilk (Normality of Residuals) ---\n")
# Shapiro-Wilk hoạt động tốt nhất khi n <= 5000
shapiro_test_result <- shapiro.test(residuals(mlr_model_log))
print(shapiro_test_result)

# 4. Tính toán Độ xiên (Skewness) của biến Release_Price
cat("\n--- 4. Độ xiên (Skewness) của Giá gốc ---\n")
price_vals <- na.omit(train_data$Release_Price)
n_sk <- length(price_vals)
skew_val <- (n_sk / ((n_sk - 1) * (n_sk - 2))) * sum(((price_vals - mean(price_vals)) / sd(price_vals))^3)
cat(sprintf("Skewness = %.4f\n", skew_val))

# ------------------ ĐÁNH GIÁ MÔ HÌNH TRÊN TẬP KIỂM TRA (TEST SET) ---------
evaluate_model_on_test <- function(name, model, test_df, is_log_model = FALSE) {
  # Dự đoán dựa trên dữ liệu mới
  predictions <- suppressWarnings(predict(model, newdata = test_df))

  # Nếu là mô hình Log-Linear, thực hiện mũ hóa (exp) để chuyển về đơn vị USD
  if (is_log_model) {
    predictions <- exp(predictions)
  }

  actuals <- test_df$Release_Price

  # Lọc các kết quả dự đoán hợp lệ
  valid <- !is.na(predictions) & !is.na(actuals)
  preds_valid <- predictions[valid]
  acts_valid <- actuals[valid]

  # Tính toán các chỉ số sai số (RMSE, MAE)
  rmse <- sqrt(mean((preds_valid - acts_valid)^2))
  mae <- mean(abs(preds_valid - acts_valid))

  # Tính R-squared trên tập kiểm tra (Out-of-sample)
  ssr <- sum((acts_valid - preds_valid)^2)
  sst <- sum((acts_valid - mean(acts_valid))^2)
  r2 <- 1 - (ssr / sst)

  cat("\n--- Đánh giá Mô hình", name, "trên Tập Test ---\n")
  cat(sprintf("Số mẫu dự đoán hợp lệ: %d / %d\n", sum(valid), nrow(test_df)))
  cat(sprintf("RMSE (Root Mean Squared Error): %.2f $\n", rmse))
  cat(sprintf("MAE (Mean Absolute Error):      %.2f $\n", mae))
  cat(sprintf("R-squared (Out-of-sample):      %.4f\n", r2))

  return(list(RMSE = rmse, MAE = mae, R2 = r2))
}

# Thực thi đánh giá cho cả hai loại mô hình
evaluate_model_on_test("MLR Cơ bản (Linear)", mlr_model_linear, test_data, is_log_model = FALSE)
evaluate_model_on_test("MLR Nâng cao (Log-Linear)", mlr_model_log, test_data, is_log_model = TRUE)

# ------------------ CHUẨN HÓA DỮ LIỆU (PHÂN TÍCH ĐỘ QUAN TRỌNG CỦA BIẾN) ---------
# Tính toán các tham số chuẩn hóa (Z-score: mean=0, sd=1)
scale_params <- list(
  Max_Power = list(mean = mean(train_data$Max_Power, na.rm = TRUE), sd = sd(train_data$Max_Power, na.rm = TRUE)),
  Memory = list(mean = mean(train_data$Memory, na.rm = TRUE), sd = sd(train_data$Memory, na.rm = TRUE)),
  log_Memory_Bandwidth = list(mean = mean(train_data$log_Memory_Bandwidth, na.rm = TRUE), sd = sd(train_data$log_Memory_Bandwidth, na.rm = TRUE)),
  Core_Speed = list(mean = mean(train_data$Core_Speed, na.rm = TRUE), sd = sd(train_data$Core_Speed, na.rm = TRUE)),
  Release_Year = list(mean = mean(train_data$Release_Year, na.rm = TRUE), sd = sd(train_data$Release_Year, na.rm = TRUE))
)

# Hàm áp dụng chuẩn hóa cho tập dữ liệu
apply_scaling <- function(df, params) {
  df %>% mutate(
    Max_Power = (Max_Power - params$Max_Power$mean) / params$Max_Power$sd,
    Memory = (Memory - params$Memory$mean) / params$Memory$sd,
    log_Memory_Bandwidth = (log_Memory_Bandwidth - params$log_Memory_Bandwidth$mean) / params$log_Memory_Bandwidth$sd,
    Core_Speed = (Core_Speed - params$Core_Speed$mean) / params$Core_Speed$sd,
    Release_Year = (Release_Year - params$Release_Year$mean) / params$Release_Year$sd
  )
}

train_data_scaled <- apply_scaling(train_data, scale_params)

# Tái xây dựng mô hình trên dữ liệu chuẩn hóa để so sánh hệ số (Feature Importance)
mlr_model_scaled <- lm(
  log(`Release_Price`) ~ `Max_Power` + `Memory` + `log_Memory_Bandwidth` +
    `Core_Speed` + Manufacturer + `Memory_Type` + `Release_Year`,
  data = train_data_scaled
)

cat("\n--- Tác động của các biến (Feature Importance) trên Mô hình Chuẩn hóa ---\n")
print(summary(mlr_model_scaled))

# QUY TRÌNH MỚI KẾT THÚC TẠI ĐÂY

# ===========================================
# DỰ ĐOÁN GIÁ GPU MỚI (NGOÀI TẬP DỮ LIỆU)
# ===========================================
# Lưu ý: Các GPU đời mới sử dụng chuẩn GDDR6, ta tạm thời ánh xạ sang GDDR5X
# để mô hình có thể xử lý dựa trên kiến trúc bộ nhớ tốc độ cao.

new_gpus <- data.frame(
  Name = c("GeForce GTX 1660", "Radeon RX 590", "GeForce RTX 3060"),
  Max_Power = c(120, 175, 170),
  Memory = c(6144, 8192, 12288),
  Memory_Bandwidth = c(192, 256, 360),
  Core_Speed = c(1530, 1469, 1320),
  Manufacturer = c("Nvidia", "AMD", "Nvidia"),
  Memory_Type = c("GDDR5", "GDDR5", "GDDR5X"),
  Release_Year = c(2019, 2018, 2021),
  Release_Price = c(219, 279, 329)
)

# 1. Tiền xử lý: Chuyển đổi Bandwidth sang thang Log tương tự tập huấn luyện
new_gpus <- new_gpus %>% mutate(log_Memory_Bandwidth = log(Memory_Bandwidth))

# 2. Thực hiện dự đoán bằng cả hai mô hình (sử dụng đơn vị gốc, không chuẩn hóa)
new_preds_linear <- predict(mlr_model_linear, newdata = new_gpus)
new_preds_log <- exp(predict(mlr_model_log, newdata = new_gpus))

# Tính toán sai số phần trăm so với giá thực tế
lin_pct <- round((new_preds_linear - new_gpus$Release_Price) / new_gpus$Release_Price * 100, 1)
log_pct <- round((new_preds_log - new_gpus$Release_Price) / new_gpus$Release_Price * 100, 1)

# Định dạng hiển thị (Ví dụ: +5%, -10%)
lin_pct_str <- ifelse(lin_pct > 0, paste0("+", lin_pct, "%"), paste0(lin_pct, "%"))
log_pct_str <- ifelse(log_pct > 0, paste0("+", log_pct, "%"), paste0(log_pct, "%"))

cat("\n\n===========================================\n")
cat("DỰ ĐOÁN GIÁ GPU MỚI (OUT-OF-SAMPLE)\n")
cat("===========================================\n")
result_df <- data.frame(
  GPU = new_gpus$Name,
  ThucTe = paste0(new_gpus$Release_Price, "$"),
  Linear = paste0(round(new_preds_linear, 0), "$ (", lin_pct_str, ")"),
  LogLinear = paste0(round(new_preds_log, 0), "$ (", log_pct_str, ")")
)
print(result_df)

# ==========================================================
# PHẦN TRỰC QUAN HÓA (XUẤT BIỂU ĐỒ CHO BÁO CÁO LATEX)
# ==========================================================
cat("\n\n===========================================\n")
cat("TẠO CÁC BIỂU ĐỒ (LƯU VÀO THƯ MỤC figures/)\n")
cat("===========================================\n")

if (!dir.exists("figures")) {
  dir.create("figures")
}

# 1. BIỂU ĐỒ MA TRẬN TƯƠNG QUAN PEARSON
numeric_subset <- train_data %>%
  select(Release_Price, Max_Power, Memory, Memory_Bandwidth, Core_Speed, Release_Year)

cor_matrix <- cor(numeric_subset, use = "complete.obs")
display_labels <- c(
  "Giá phát hành", "TDP (Công suất)", "Dung lượng RAM",
  "Băng thông", "Xung nhịp lõi", "Năm phát hành"
)
colnames(cor_matrix) <- display_labels
rownames(cor_matrix) <- display_labels

png("figures/correlation_matrix.png",
  type = "cairo",
  width = 2200, height = 2000, res = 300
)
par(mar = c(10, 10, 4, 5))
n_cor <- ncol(cor_matrix)
img_data <- t(cor_matrix[n_cor:1, ])
image(1:n_cor, 1:n_cor, img_data,
  col = colorRampPalette(c("#2166ac", "#f7f7f7", "#b2182b"))(100),
  breaks = seq(-1, 1, length.out = 101),
  axes = FALSE, xlab = "", ylab = "",
  main = paste("Ma trận tương quan Pearson (N =", nrow(train_data), ")")
)
axis(1, at = 1:n_cor, labels = colnames(cor_matrix), las = 2, cex.axis = 0.9)
axis(2, at = 1:n_cor, labels = rev(colnames(cor_matrix)), las = 1, cex.axis = 0.9)
for (i in 1:n_cor) {
  for (j in 1:n_cor) {
    val <- cor_matrix[i, j]
    text_col <- ifelse(abs(val) > 0.6, "white", "black")
    text(j, n_cor - i + 1, sprintf("%.2f", val), cex = 1.1, col = text_col)
  }
}
dev.off()
cat("--- Đã xuất figures/correlation_matrix.png ---\n")

# 2. CÁC BIỂU ĐỒ CHẨN ĐOÁN PHẦN DƯ
png("figures/diagnostic_residuals.png",
  type = "cairo",
  width = 1800, height = 800, res = 200
)
par(mfrow = c(1, 2), mar = c(5, 5, 4, 2))
fitted_vals <- fitted(mlr_model_log)
resid_vals <- residuals(mlr_model_log)

plot(fitted_vals, resid_vals,
  main = "Phần dư vs. Giá trị ước lượng (Log-Linear)",
  xlab = "Giá trị ước lượng (thang log)", ylab = "Phần dư (Residuals)",
  pch = 19, col = rgb(0.2, 0.4, 0.6, 0.4), cex.lab = 1.1, cex.main = 1.15
)
abline(h = 0, col = "red", lwd = 2, lty = 2)
lines(lowess(fitted_vals, resid_vals), col = "#e34a33", lwd = 2)

qqnorm(resid_vals,
  main = "Q-Q Plot phần dư",
  pch = 19, col = rgb(0.2, 0.4, 0.6, 0.4), cex.lab = 1.1, cex.main = 1.15
)
qqline(resid_vals, col = "red", lwd = 2)
par(mfrow = c(1, 1))
dev.off()
cat("--- Đã xuất figures/diagnostic_residuals.png ---\n")

# 3. BIỂU ĐỒ SO SÁNH PHÂN PHỐI GIÁ (GỐC vs LOG)
png("figures/price_distribution_compare.png",
  type = "cairo",
  width = 1800, height = 800, res = 200
)
par(mfrow = c(1, 2), mar = c(5, 5, 4, 2))
hist(train_data$Release_Price,
  breaks = 40, col = "#2c7fb8", border = "white",
  main = "Phân phối giá phát hành (USD)", xlab = "Giá (USD)", ylab = "Tần suất"
)
log_prices <- log(train_data$Release_Price[!is.na(train_data$Release_Price)])
hist(log_prices,
  breaks = 30, col = "#41ae76", border = "white",
  main = "Phân phối log(giá phát hành)", xlab = "log(Giá)", ylab = "Tần suất"
)
par(mfrow = c(1, 1))
dev.off()
cat("--- Đã xuất figures/price_distribution_compare.png ---\n")

# 4. BIỂU ĐỒ ĐỘ QUAN TRỌNG CỦA CÁC HỆ SỐ HỒI QUY
coef_df <- summary(mlr_model_scaled)$coefficients
var_names <- rownames(coef_df)[-1]
var_pct <- (exp(coef_df[-1, "Estimate"]) - 1) * 100
display_names_map <- list(
  Max_Power = "TDP (Công suất)", Memory = "Dung lượng RAM",
  log_Memory_Bandwidth = "Băng thông (Log)", Core_Speed = "Xung nhịp lõi",
  ManufacturerNvidia = "Hãng NVIDIA", Release_Year = "Năm phát hành"
)
display_mapped <- sapply(var_names, function(x) ifelse(!is.null(display_names_map[[x]]), display_names_map[[x]], x))
ord <- order(abs(var_pct))
var_pct_sorted <- var_pct[ord]
display_sorted <- display_mapped[ord]
bar_cols <- ifelse(var_pct_sorted > 0, "#2c7fb8", "#e34a33")

png("figures/coefficient_importance.png",
  type = "cairo",
  width = 2000, height = 1200, res = 200
)
par(mar = c(5, 12, 4, 4))
bp <- barplot(var_pct_sorted,
  names.arg = display_sorted, horiz = TRUE, las = 1,
  col = bar_cols, border = NA, main = "Tác động của các biến lên giá GPU (%)",
  xlab = "Thay đổi giá (%) khi tăng 1 đơn vị chuẩn hóa",
  xlim = c(min(var_pct_sorted) - 10, max(var_pct_sorted) + 15)
)
text(var_pct_sorted, bp,
  labels = paste0(ifelse(var_pct_sorted > 0, "+", ""), round(var_pct_sorted, 1), "%"),
  pos = ifelse(var_pct_sorted > 0, 4, 2), cex = 0.85, font = 2
)
dev.off()
cat("--- Đã xuất figures/coefficient_importance.png ---\n")

# 5. BIỂU ĐỒ TẦN SUẤT PHẦN DƯ (RESIDUAL HISTOGRAM)
png("figures/residual_histogram.png",
  type = "cairo",
  width = 1200, height = 800, res = 200
)
hist(resid_vals,
  breaks = 35, col = "#756bb1", border = "white",
  main = "Phân phối phần dư của Log-Linear", xlab = "Phần dư", freq = FALSE
)
curve(dnorm(x, mean = mean(resid_vals), sd = sd(resid_vals)), add = TRUE, col = "red", lwd = 2)
dev.off()
cat("--- Đã xuất figures/residual_histogram.png ---\n")

# 6. BIỂU ĐỒ PHÂN TÁN SO SÁNH GIÁ THỰC TẾ VÀ DỰ ĐOÁN
png("figures/scatter_actual_vs_predicted.png", type = "cairo", width = 1200, height = 1000, res = 150)
par(mar = c(5, 5, 4, 2))
predicted_values <- exp(fitted_vals) # Chuyển đổi ngược từ log() về USD
actual_values <- train_data$Release_Price

plot(actual_values, predicted_values,
  main = "So sánh Giá Thực tế vs Giá Dự đoán (USD)",
  xlab = "Giá thực tế (USD)",
  ylab = "Giá dự đoán (USD)",
  pch = 19,
  col = rgb(0.2, 0.4, 0.6, 0.5),
  xlim = c(0, max(actual_values)),
  ylim = c(0, max(predicted_values))
)
abline(0, 1, col = "red", lwd = 2) # Đường chuẩn y = x
dev.off()
cat("--- Đã xuất figures/scatter_actual_vs_predicted.png ---\n")

# Xuất dữ liệu đã xử lý sạch ra file CSV
# Ghi đè file cũ nếu tồn tại
# unlink("output.csv")
# write.csv(train_data, "output.csv", row.names = FALSE)
