library(stringr)
library(car)
library(lmtest)
library(dplyr)

# Set working directory về thư mục chứa script
local({
  file_flag <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_flag) > 0) {
    # Rscript: dùng --file= arg
    setwd(dirname(normalizePath(sub("^--file=", "", file_flag[1]))))
  } else if (!file.exists("All_GPUs.csv") && file.exists("src/All_GPUs.csv")) {
    # VSCode interactive từ workspace root: nhảy vào src/
    setwd("src")
  }
})

# BƯỚC 1: TẢI VÀ KHẢO SÁT SƠ BỘ DỮ LIỆU
# Đọc file dữ liệu thô
raw_data <- read.csv("All_GPUs.csv",
  stringsAsFactors = FALSE,
)

# Khảo sát sơ bộ dữ liệu (Chạy các dòng này để xem kết quả trên console)
# str(raw_data)
# summary(raw_data)
# print(colSums(is.na(raw_data)))

# NEW FLOW START HERE

# --------- INITIAL VAR SELECT ----------

kept_vars <- c(
  "Name", "Release_Price", "Max_Power", "Memory", "Memory_Bandwidth",
  "Core_Speed", "Release_Date", "Manufacturer", "Memory_Type"
)

selected_data <- raw_data %>% select(all_of(kept_vars))

# -------- CLEANING -----------

# Replace all empty strings, hyphens, and "N/A" with NA for all character columns and remove leading/trailing whitespace
selected_data <- selected_data %>%
  mutate(across(
    where(is.character),
    ~ ifelse(str_trim(.) %in% c("", "-", "NA", "N/A"), NA, str_trim(.))
  ))


# REMOVE ALL INTEL GPUS, THIS TIME (2017) INTEL DOESN'T CONTRIBUTE MUCH TO GPU MARKET, SO REMOVE COMPLETELY
clean_data <- selected_data %>% filter(Manufacturer != "Intel")

# Remove all Empty Release_Price rows
clean_data <- clean_data %>% filter(!is.na(Release_Price))

# Replace "ATI" with "AMD" in Manufacturer column
clean_data <- clean_data %>%
  mutate(Manufacturer = str_replace(Manufacturer, "ATI", "AMD"))

# Remove irrelevant GPU models (Quadro, Crossfire, SLI, not released, Titan)
clean_data <- clean_data %>%
  filter(!str_detect(Name, regex("Quadro|Crossfire|SLI|not[ .]released|Titan", ignore_case = TRUE)))

num_row_clean <- nrow(clean_data)

cat("Dữ liệu sau khi làm sạch: N =", num_row_clean, "\n")


# ------------ Parsing Year and Columns with Units --------------

# Extract Year from Release_Date And rename to Release_Year and remove Release_Date
clean_data <- clean_data %>%
  mutate(Release_Year = as.integer(format(as.Date(Release_Date, "%d-%b-%Y"), "%Y"))) %>%
  select(-Release_Date)

# Extract numeric values from columns with units and convert to numeric type
clean_data <- clean_data %>%
  mutate(
    Release_Price = as.numeric(str_extract(Release_Price, "\\d+\\.?\\d*")),
    Max_Power = as.numeric(str_extract(Max_Power, "\\d+\\.?\\d*")),
    Memory = as.numeric(str_extract(Memory, "\\d+\\.?\\d*")),
    Memory_Bandwidth = as.numeric(str_extract(Memory_Bandwidth, "\\d+\\.?\\d*")),
    Core_Speed = as.numeric(str_extract(Core_Speed, "\\d+\\.?\\d*"))
  )

# ------ Convert strings to factors ------

clean_data <- clean_data %>%
  mutate(
    Manufacturer = as.factor(Manufacturer),
    Memory_Type = as.factor(Memory_Type)
  )

# ---------------- Split Training and Testing Set (9/1 ratio) -----------
set.seed(2026252) # For reproducibility
train_indices <- sample(1:nrow(clean_data), size = 0.9 * nrow(clean_data))

train_data <- clean_data[train_indices, ]
test_data <- clean_data[-train_indices, ]

cat("Dữ liệu sau khi chia: Train (N = ", nrow(train_data), "), Test (N = ", nrow(test_data), ")\n", sep = "")

# ------------------ IMPUTATION  -----------------
# 1. Trích xuất VRAM trực tiếp từ cột Name (Feature Extraction)
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

# 2. Fallback: Điền Mode/Median bằng tham số từ tập Train (Tránh Data Leakage)
get_mode <- function(v) {
  uniqv <- unique(na.omit(v))
  uniqv[which.max(tabulate(match(v, uniqv)))]
}

# TÍNH TOÁN THAM SỐ IMPUTATION TỪ TẬP TRAIN
impute_params <- list(
  Memory = get_mode(train_data$Memory),
  Memory_Type = get_mode(train_data$Memory_Type),
  Manufacturer = get_mode(train_data$Manufacturer),
  Core_Speed = median(train_data$Core_Speed, na.rm = TRUE),
  Release_Year = median(train_data$Release_Year, na.rm = TRUE),
  Max_Power = median(train_data$Max_Power, na.rm = TRUE),
  Memory_Bandwidth = median(train_data$Memory_Bandwidth, na.rm = TRUE)
)

# HÀM ÁP DỤNG THAM SỐ ĐIỀN NA
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

# Áp dụng cho cả 2 tập dữ liệu
train_data <- apply_imputation(train_data, impute_params)
test_data <- apply_imputation(test_data, impute_params)

# In ra số dòng NA sau khi xử lý
cat("Số dòng NA của train_data sau imputation:\n")
cat(paste(names(train_data), colSums(is.na(train_data)), sep = ": ", collapse = ", "), "\n")
cat("Số dòng NA của test_data sau imputation:\n")
cat(paste(names(test_data), colSums(is.na(test_data)), sep = ": ", collapse = ", "), "\n")

# ------------------ PRE-TRANSFORMATION -----------------
# Lấy log của Bandwidth TRƯỚC khi chuẩn hóa để tránh lỗi log số âm
train_data <- train_data %>% mutate(log_Memory_Bandwidth = log(Memory_Bandwidth))
test_data <- test_data %>% mutate(log_Memory_Bandwidth = log(Memory_Bandwidth))


# ------------------ MLR vs Log-Linear ---------
# 1A. Xây dựng model MLR cơ bản (Linear)
mlr_model_linear <- lm(
  `Release_Price` ~ `Max_Power` + `Memory` + `Memory_Bandwidth` +
    `Core_Speed` + Manufacturer + `Memory_Type` + `Release_Year`,
  data = train_data
)

# 1B. Xây dựng model MLR Nâng cao (Log-Linear)
mlr_model_log <- lm(
  log(`Release_Price`) ~ `Max_Power` + `Memory` + `log_Memory_Bandwidth` +
    `Core_Speed` + Manufacturer + `Memory_Type` + `Release_Year`,
  data = train_data
)

# 2. Kiểm tra VIF để phát hiện đa cộng tuyến
check_vif <- function(name, model) {
  vif_values <- vif(model)

  cat("\n--- Kiểm tra VIF (", name, ") ---\n")
  print(vif_values)
}

check_vif("MLR Cơ bản", mlr_model_linear)
check_vif("Log-Linear", mlr_model_log)

# ------------------ Testing MLR on Test Set ---------
evaluate_model_on_test <- function(name, model, test_df, is_log_model = FALSE) {
  # Lưu ý: test_df cần trải qua cùng quá trình Imputation và Standardization như train_data
  # Hàm này thực hiện dự đoán trên các dòng không bị NA ở các biến độc lập

  predictions <- suppressWarnings(predict(model, newdata = test_df))

  # Nếu mô hình dự đoán theo Logarit, ta phải mũ hóa (exp) ngược lại để đưa về USD
  if (is_log_model) {
    predictions <- exp(predictions)
  }

  actuals <- test_df$Release_Price

  # Lọc các dòng dự đoán hợp lệ (không NA)
  valid <- !is.na(predictions) & !is.na(actuals)
  preds_valid <- predictions[valid]
  acts_valid <- actuals[valid]

  # Tính toán các chỉ số
  rmse <- sqrt(mean((preds_valid - acts_valid)^2))
  mae <- mean(abs(preds_valid - acts_valid))

  # R-squared out-of-sample
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

# Chạy thử nghiệm 2 mô hình với test_data
evaluate_model_on_test("MLR Cơ bản (Linear)", mlr_model_linear, test_data, is_log_model = FALSE)
evaluate_model_on_test("MLR Nâng cao (Log-Linear)", mlr_model_log, test_data, is_log_model = TRUE)

# ------------------ STANDARDIZATION (Feature Importance Analysis) ---------
# Tạo một bản sao dữ liệu đã chuẩn hóa (mean=0, sd=1) chỉ để phân tích tác động các biến
scale_params <- list(
  Max_Power = list(mean = mean(train_data$Max_Power, na.rm = TRUE), sd = sd(train_data$Max_Power, na.rm = TRUE)),
  Memory = list(mean = mean(train_data$Memory, na.rm = TRUE), sd = sd(train_data$Memory, na.rm = TRUE)),
  log_Memory_Bandwidth = list(mean = mean(train_data$log_Memory_Bandwidth, na.rm = TRUE), sd = sd(train_data$log_Memory_Bandwidth, na.rm = TRUE)),
  Core_Speed = list(mean = mean(train_data$Core_Speed, na.rm = TRUE), sd = sd(train_data$Core_Speed, na.rm = TRUE)),
  Release_Year = list(mean = mean(train_data$Release_Year, na.rm = TRUE), sd = sd(train_data$Release_Year, na.rm = TRUE))
)

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

# Xây dựng lại mô hình trên dữ liệu đã chuẩn hóa để lấy hệ số (Estimate)
mlr_model_scaled <- lm(
  log(`Release_Price`) ~ `Max_Power` + `Memory` + `log_Memory_Bandwidth` +
    `Core_Speed` + Manufacturer + `Memory_Type` + `Release_Year`,
  data = train_data_scaled
)

cat("\n--- Tác động của các biến (Feature Importance) trên Mô hình Chuẩn hóa ---\n")
print(summary(mlr_model_scaled))

# NEW FLOW END HERE

# ===========================================
# DỰ ĐOÁN GIÁ GPU MỚI (OUT-OF-SAMPLE)
# ===========================================
# Lưu ý: Các GPU đời mới dùng GDDR6, nhưng tập train cũ chỉ tới GDDR5X, 
# nên ta map GDDR6 -> GDDR5X để mô hình hiểu được kiến trúc tốc độ cao.
# Băng thông (Memory_Bandwidth) được tính bằng GB/s.

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

# 1. Tiền xử lý: Lấy log(Memory_Bandwidth) hệt như lúc train
new_gpus <- new_gpus %>% mutate(log_Memory_Bandwidth = log(Memory_Bandwidth))

# 2. Dự đoán bằng mô hình Log-Linear và Linear (KHÔNG SCALE)
new_preds_linear <- predict(mlr_model_linear, newdata = new_gpus)
new_preds_log <- exp(predict(mlr_model_log, newdata = new_gpus)) # Nhớ dùng hàm exp() để đảo ngược log(Price) về USD

# Tính phần trăm sai lệch
lin_pct <- round((new_preds_linear - new_gpus$Release_Price) / new_gpus$Release_Price * 100, 1)
log_pct <- round((new_preds_log - new_gpus$Release_Price) / new_gpus$Release_Price * 100, 1)

# Format hiển thị (VD: +5%, -10%)
lin_pct_str <- ifelse(lin_pct > 0, paste0("+", lin_pct, "%"), paste0(lin_pct, "%"))
log_pct_str <- ifelse(log_pct > 0, paste0("+", log_pct, "%"), paste0(log_pct, "%"))

cat("\n\n===========================================\n")
cat("DỰ ĐOÁN GIÁ GPU MỚI (OUT-OF-SAMPLE - VÌ KHOA HỌC)\n")
cat("===========================================\n")
result_df <- data.frame(
  GPU = new_gpus$Name,
  ThucTe = paste0(new_gpus$Release_Price, "$"),
  Linear = paste0(round(new_preds_linear, 0), "$ (", lin_pct_str, ")"),
  LogLinear = paste0(round(new_preds_log, 0), "$ (", log_pct_str, ")")
)
print(result_df)

# Xuất dữ liệu đã lọc ra CSV
# Xóa file cũ nếu tồn tại
unlink("output.csv")
write.csv(train_data, "output.csv", row.names = FALSE)
