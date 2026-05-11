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
raw_data <- read.csv("All_GPUs.csv", stringsAsFactors = FALSE)

# Khảo sát sơ bộ dữ liệu (Chạy các dòng này để xem kết quả trên console)
str(raw_data)
summary(raw_data)
colSums(is.na(raw_data))

# ==========================================================
# PHÂN TÍCH HỖ TRỢ: Tỷ lệ dữ liệu khuyết theo 34 thuộc tính
# Xuất Hình minh họa cho mục 2.2 báo cáo (justify quy trình lọc biến)
# ==========================================================
if (!dir.exists("figures")) dir.create("figures")

# Đếm cả NA và chuỗi rỗng / không hợp lệ (vd: "-", "")
missing_count <- sapply(raw_data, function(col) {
  if (is.character(col)) {
    cleaned <- str_trim(col)
    sum(is.na(col) | cleaned == "" | cleaned == "-")
  } else {
    sum(is.na(col))
  }
})
missing_pct <- round(100 * missing_count / nrow(raw_data), 2)

kept_vars <- c("Release_Price", "Max_Power", "Memory", "Memory_Bus",
               "Core_Speed", "Release_Date", "Manufacturer", "Memory_Type")

missing_df <- data.frame(
  variable = names(missing_pct),
  pct = as.numeric(missing_pct),
  kept = names(missing_pct) %in% kept_vars
)
missing_df <- missing_df[order(-missing_df$pct), ]

bar_colors <- with(missing_df,
  ifelse(kept, "#2c7fb8",
    ifelse(pct >= 30, "#e34a33", "#bdbdbd")))

png("figures/missing_data_ratio.png", type = "cairo",
    width = 2400, height = 2400, res = 300)
par(mar = c(5, 11, 4, 2))
barplot(rev(missing_df$pct),
        names.arg = rev(missing_df$variable),
        horiz = TRUE, las = 1,
        col = rev(bar_colors),
        xlim = c(0, 100),
        xlab = "Tỷ lệ dữ liệu khuyết (%)",
        main = "Tỷ lệ dữ liệu khuyết của 34 thuộc tính (N = 3.406)",
        cex.names = 0.7, cex.main = 1.05)
abline(v = 30, col = "red", lty = 2, lwd = 1.5)
legend("bottomright",
       legend = c("Biến được chọn (8)", "Bị loại (thiếu >= 30%)", "Bị loại (lý do khác)"),
       fill = c("#2c7fb8", "#e34a33", "#bdbdbd"),
       cex = 0.85, bty = "n")
dev.off()
cat("\n--- Đã xuất figures/missing_data_ratio.png ---\n")

# BƯỚC 2: CHỌN LỌC, ĐỔI TÊN VÀ ÉP KIỂU DỮ LIỆU

# --- 2.1: Chọn cột và đổi tên ---
df <- raw_data %>%
  select(Release_Price, Max_Power, Memory, Memory_Bus,
         Core_Speed, Release_Date, Manufacturer, Memory_Type) %>%
  rename(
    release_price = Release_Price, tdp          = Max_Power,
    memory_size   = Memory,        memory_bus   = Memory_Bus,
    core_speed    = Core_Speed,    release_date = Release_Date,
    manufacturer  = Manufacturer,  memory_type  = Memory_Type
  )

# --- 2.2: Gộp nhãn ATI -> AMD ---
df <- df %>%
  mutate(
    manufacturer = ifelse(str_trim(manufacturer) == "ATI", "AMD",
                          str_trim(manufacturer))
  )
cat("\n--- 2.2: Kiểm tra nhãn manufacturer sau khi gộp ATI -> AMD ---\n")
print(table(df$manufacturer))

# --- 2.3: Trích xuất số từ chuỗi có đơn vị ---
df <- df %>%
  mutate(
    release_price = as.numeric(str_extract(release_price, "\\d+\\.?\\d*")),
    tdp           = as.numeric(str_extract(tdp,           "\\d+\\.?\\d*")),
    memory_size   = as.numeric(str_extract(memory_size,   "\\d+\\.?\\d*")),
    memory_bus    = as.numeric(str_extract(memory_bus,    "\\d+\\.?\\d*")),
    core_speed    = as.numeric(str_extract(core_speed,    "\\d+\\.?\\d*"))
  )

# --- 2.4: Parse chuỗi ngày tháng -> năm ---
df <- df %>%
  mutate(
    release_year = as.integer(
      format(as.Date(str_trim(release_date), "%d-%b-%Y"), "%Y"))
  ) %>%
  select(-release_date)

cat("\n--- 2: Cấu trúc df sau khi hoàn thành Bước 2 ---\n")
str(df)

# BƯỚC 3 & 4: XỬ LÝ NGOẠI LỆ, LOẠI BỎ INTEL VÀ GIÁ TRỊ KHUYẾT
# 4.1: Lọc dữ liệu trước 
df_clean <- df %>% 
  filter(!is.na(release_price)) %>%            # Giữ lại các dòng có giá
  filter(manufacturer != "Intel")              # Loại bỏ hãng Intel

df_clean$manufacturer <- factor(df_clean$manufacturer)

#  3.1: Định nghĩa hàm tính ngoại lệ chuẩn theo lý thuyết Final ---
count_outliers_by_raw_bounds <- function(raw_vec, clean_vec) {
  raw_vec <- na.omit(raw_vec)
  q1 <- quantile(raw_vec, 0.25)
  q3 <- quantile(raw_vec, 0.75)
  iqr <- q3 - q1
  upper_bound <- q3 + 1.5 * iqr
  
  # Đếm xem trong tập sạch có bao nhiêu giá trị vượt ngưỡng của tập thô
  return(sum(clean_vec > upper_bound, na.rm = TRUE))
}

#  3.2: Thống kê kết quả để đưa vào báo cáo ---
cat("\n--- THỐNG KÊ NGOẠI LỆ (Dựa trên ranh giới tập thô N=3406) ---\n")
cat("Số lượng ngoại lệ release_price trong mẫu phân tích:", 
    count_outliers_by_raw_bounds(df$release_price, df_clean$release_price), "\n")

cat("Số lượng ngoại lệ tdp trong mẫu phân tích:", 
    count_outliers_by_raw_bounds(df$tdp, df_clean$tdp), "\n")

cat("Số lượng ngoại lệ core_speed trong mẫu phân tích:", 
    count_outliers_by_raw_bounds(df$core_speed, df_clean$core_speed), "\n")

#  3.3: Vẽ Boxplot minh họa (Dùng tập df_clean N=556) ---
png("figures/boxplot_outliers.png", type="cairo", width=900, height=400, res=120)
par(mfrow=c(1,3))
boxplot(df_clean$release_price, main="Giá (N=556)", col="lightblue", ylab="USD")
boxplot(df_clean$tdp, main="TDP (N=556)", col="lightgreen", ylab="Watts")
boxplot(df_clean$core_speed, main="Core Speed (N=556)", col="salmon", ylab="MHz")
par(mfrow=c(1,1))
dev.off()
# Hàm tự tạo để tìm Mode 
get_mode <- function(v) {
  uniqv <- unique(na.omit(v))
  uniqv[which.max(tabulate(match(v, uniqv)))]
}

# 4.2 & 4.3 Điền khuyết 
df_clean <- df_clean %>%
  mutate(
    # Biến số liên tục: điền Median (bền vững với phân phối lệch phải)
    tdp = ifelse(is.na(tdp), median(tdp, na.rm = TRUE), tdp),
    core_speed = ifelse(is.na(core_speed), median(core_speed, na.rm = TRUE), core_speed),
    release_year = ifelse(is.na(release_year), median(release_year, na.rm = TRUE), release_year),

    # Biến số rời rạc: điền Mode để đảm bảo giá trị điền vào là chuẩn phần cứng thực tế
    # (median của số chẵn quan sát có thể cho ra giá trị trung gian không tồn tại, vd: 320 bit)
    memory_size = ifelse(is.na(memory_size), get_mode(memory_size), memory_size),
    memory_bus = ifelse(is.na(memory_bus), get_mode(memory_bus), memory_bus),

    # Biến phân loại: điền Mode
    memory_type = ifelse(is.na(memory_type) | memory_type == "", get_mode(memory_type), memory_type),
    manufacturer = ifelse(is.na(as.character(manufacturer)) | as.character(manufacturer) == "",
                          get_mode(as.character(manufacturer)), as.character(manufacturer))
  )

# ==========================================================
# PHÂN TÍCH HỖ TRỢ: Ma trận tương quan giữa các biến số được chọn
# Xuất Hình minh họa cho mục 2.2 báo cáo (kiểm chứng quan hệ với giá Y)
# ==========================================================
numeric_subset <- df_clean %>%
  select(release_price, tdp, memory_size, memory_bus, core_speed, release_year)

cor_matrix <- cor(numeric_subset, use = "complete.obs")
display_labels <- c("Giá phát hành", "TDP", "Dung lượng RAM",
                    "Băng thông bus", "Xung nhịp lõi", "Năm phát hành")
colnames(cor_matrix) <- display_labels
rownames(cor_matrix) <- display_labels

png("figures/correlation_matrix.png", type = "cairo",
    width = 2000, height = 1800, res = 300)
par(mar = c(8, 8, 4, 5))

n_cor <- ncol(cor_matrix)
img_data <- t(cor_matrix[n_cor:1, ])

image(1:n_cor, 1:n_cor, img_data,
      col = colorRampPalette(c("#2166ac", "#f7f7f7", "#b2182b"))(100),
      breaks = seq(-1, 1, length.out = 101),
      axes = FALSE, xlab = "", ylab = "",
      main = "Ma trận tương quan Pearson giữa các biến số (N = 556)")
axis(1, at = 1:n_cor, labels = colnames(cor_matrix), las = 2, cex.axis = 0.85)
axis(2, at = 1:n_cor, labels = rev(colnames(cor_matrix)), las = 1, cex.axis = 0.85)

for (i in 1:n_cor) {
  for (j in 1:n_cor) {
    val <- cor_matrix[i, j]
    text_col <- ifelse(abs(val) > 0.6, "white", "black")
    text(j, n_cor - i + 1, sprintf("%.2f", val), cex = 0.95, col = text_col)
  }
}
dev.off()
cat("\n--- Đã xuất figures/correlation_matrix.png ---\n")

# BƯỚC 5: MÃ HÓA BIẾN PHÂN LOẠI

df_clean <- df_clean %>%
  mutate(
    manufacturer = as.factor(manufacturer),
    memory_type = as.factor(memory_type)
  )


cat("\n--- KIỂM TRA ĐỘ SẠCH CỦA DỮ LIỆU ---\n")
cat("Số lượng giá trị khuyết (NA) còn lại:\n")
print(colSums(is.na(df_clean))) 

cat("\n--- KIỂM TRA CẤU TRÚC BIẾN (FACTOR CHECK) ---\n")
# str() giúp xác nhận manufacturer/memory_type đã là Factor chưa
str(df_clean)
# BƯỚC 6: CHUẨN HÓA DỮ LIỆU 

df_final <- df_clean %>%
  mutate(
    tdp = scale(tdp)[,1],
    core_speed = scale(core_speed)[,1],
    memory_size = scale(memory_size)[,1],
    memory_bus = scale(memory_bus)[,1]
    # Biến release_year được giữ nguyên không chuẩn hóa theo đúng lý thuyết
  )

# Xem kết quả sau khi hoàn thành 6 bước
summary(df_final)

cat("\n--- KIỂM TRA KẾT QUẢ CHUẨN HÓA Z-SCORE ---\n")
stats_check <- df_final %>%
  summarise(
    Mean_TDP = round(mean(tdp), 2),
    SD_TDP = sd(tdp),
    Mean_Core = round(mean(core_speed), 2),
    SD_Core = sd(core_speed)
  )
print(stats_check)
# BƯỚC 7: XÂY DỰNG MÔ HÌNH THỐNG KÊ

# install.packages(c("car", "lmtest", "sandwich", "rstatix"))
library(car)      # Kiểm định VIF, Levene
library(lmtest)   # Kiểm định Breusch-Pagan
library(sandwich) # Robust Standard Errors
library(rstatix)  # Games-Howell test

# ==========================================================
# 7.1. MÔ HÌNH HỒI QUY TUYẾN TÍNH BỘI (CẬP NHẬT THEO FINAL)
# ==========================================================

#  1: Mô hình sơ bộ để phát hiện đa cộng tuyến 
cat("\n--- 1. MÔ HÌNH SƠ BỘ VÀ KIỂM ĐỊNH ĐA CỘNG TUYẾN (VIF) ---\n")
# Chạy mô hình có memory_type để chứng minh VIF > 5
mlr_model_initial <- lm(release_price ~ tdp + memory_size + memory_bus + 
                          core_speed + manufacturer + memory_type + release_year, data = df_final)

# Sử dụng chuẩn VIF < 5 thay vì VIF < 10 theo đúng lý thuyết
vif_initial <- vif(mlr_model_initial)
print(vif_initial)
cat("=> Phát hiện memory_type có VIF cao (sẽ bị loại bỏ).\n")

# Giai đoạn 2: Xây dựng Mô hình chính thức (Log-Linear, không memory_type) ---
cat("\n--- 2. MÔ HÌNH LOG-LINEAR CHÍNH THỨC (Đã loại memory_type) ---\n")
log_model_final <- lm(log(release_price) ~ tdp + memory_size + memory_bus + 
                        core_speed + manufacturer + release_year, data = df_final)

summary(log_model_final)


# Giai đoạn 3: Các kiểm định bắt buộc trên mô hình chính thức ---

cat("\n--- 3a. KIỂM ĐỊNH LẠI VIF TRÊN MÔ HÌNH CHÍNH THỨC ---\n")
# Đảm bảo toàn bộ VIF hiện tại đều < 5
print(vif(log_model_final))

cat("\n--- 3b. KIỂM ĐỊNH PHƯƠNG SAI SAI SỐ (Breusch-Pagan) ---\n")
print(bptest(log_model_final))

cat("\n--- 3c. KIỂM ĐỊNH PHÂN PHỐI CHUẨN PHẦN DƯ (Shapiro-Wilk) ---\n")
# Kiểm tra xem log() đã cải thiện phần dư chưa
print(shapiro.test(residuals(log_model_final)))


# Giai đoạn 4: Trực quan hóa kết quả
cat("\n--- 4. VẼ BIỂU ĐỒ SO SÁNH THỰC TẾ & DỰ ĐOÁN ---\n")
# Dùng exp() để đưa giá trị log về lại tiền USD để so sánh
predicted_values <- exp(predict(log_model_final)) 
actual_values <- df_final$release_price

# Vẽ scatter plot
png("figures/scatter_actual_vs_predicted.png", type="cairo", width=700, height=600, res=120)
plot(actual_values, predicted_values,
     main="Biểu đồ so sánh giá thực tế với giá dự đoán",
     xlab="Giá thực tế (USD)",
     ylab="Giá dự đoán (USD)",
     pch=19,
     col=rgb(0.2, 0.4, 0.6, 0.5))
# Kẻ đường y=x để làm tham chiếu lý tưởng
abline(0, 1, col="red", lwd=2)
dev.off()

# --- BIỂU ĐỒ CHẨN ĐOÁN PHẦN DƯ (Residuals vs Fitted + Q-Q Plot) ---
cat("\n--- 5. VẼ BIỂU ĐỒ CHẨN ĐOÁN PHẦN DƯ ---\n")
png("figures/diagnostic_residuals.png", type = "cairo",
    width = 1800, height = 800, res = 200)
par(mfrow = c(1, 2), mar = c(5, 5, 4, 2))

# Panel trái: Residuals vs Fitted
fitted_vals <- fitted(log_model_final)
resid_vals <- residuals(log_model_final)
plot(fitted_vals, resid_vals,
     main = "Phần dư vs. Giá trị ước lượng",
     xlab = "Giá trị ước lượng (log-scale)",
     ylab = "Phần dư (Residuals)",
     pch = 19, col = rgb(0.2, 0.4, 0.6, 0.4),
     cex.lab = 1.1, cex.main = 1.15)
abline(h = 0, col = "red", lwd = 2, lty = 2)
lines(lowess(fitted_vals, resid_vals), col = "#e34a33", lwd = 2)

# Panel phải: Q-Q Plot
qqnorm(resid_vals,
       main = "Q-Q Plot phần dư",
       pch = 19, col = rgb(0.2, 0.4, 0.6, 0.4),
       cex.lab = 1.1, cex.main = 1.15)
qqline(resid_vals, col = "red", lwd = 2)

par(mfrow = c(1, 1))
dev.off()
cat("--- Đã xuất figures/diagnostic_residuals.png ---\n")

# --- BIỂU ĐỒ PHÂN PHỐI GIÁ: GỐC vs LOG ---
cat("\n--- 6. VẼ BIỂU ĐỒ PHÂN PHỐI GIÁ (Gốc vs Log) ---\n")
png("figures/price_distribution_compare.png", type = "cairo",
    width = 1800, height = 800, res = 200)
par(mfrow = c(1, 2), mar = c(5, 5, 4, 2))

# Panel trái: Phân phối giá gốc
hist(df_final$release_price,
     breaks = 40, col = "#2c7fb8", border = "white",
     main = "Phân phối giá phát hành (USD)",
     xlab = "Giá (USD)", ylab = "Tần suất",
     cex.lab = 1.1, cex.main = 1.15)
abline(v = median(df_final$release_price), col = "red", lwd = 2, lty = 2)
abline(v = mean(df_final$release_price), col = "#e34a33", lwd = 2, lty = 3)
legend("topright",
       legend = c(paste0("Median = $", round(median(df_final$release_price))),
                  paste0("Mean = $", round(mean(df_final$release_price)))),
       col = c("red", "#e34a33"), lty = c(2, 3), lwd = 2,
       cex = 0.85, bty = "n")

# Panel phải: Phân phối log(giá)
hist(log(df_final$release_price),
     breaks = 30, col = "#41ae76", border = "white",
     main = "Phân phối log(giá phát hành)",
     xlab = "log(Giá)", ylab = "Tần suất",
     cex.lab = 1.1, cex.main = 1.15)
abline(v = median(log(df_final$release_price)), col = "red", lwd = 2, lty = 2)
abline(v = mean(log(df_final$release_price)), col = "#e34a33", lwd = 2, lty = 3)
legend("topright",
       legend = c(paste0("Median = ", round(median(log(df_final$release_price)), 2)),
                  paste0("Mean = ", round(mean(log(df_final$release_price)), 2))),
       col = c("red", "#e34a33"), lty = c(2, 3), lwd = 2,
       cex = 0.85, bty = "n")

par(mfrow = c(1, 1))
dev.off()
cat("--- Đã xuất figures/price_distribution_compare.png ---\n")

# --- BOXPLOT SO SÁNH GIÁ NVIDIA vs AMD ---
cat("\n--- 7. VẼ BOXPLOT SO SÁNH GIÁ NVIDIA vs AMD ---\n")
png("figures/boxplot_nvidia_vs_amd.png", type = "cairo",
    width = 1400, height = 900, res = 200)
par(mar = c(5, 5, 4, 2))
boxplot(release_price ~ manufacturer, data = df_final,
        col = c("#e34a33", "#2c7fb8"),
        main = "Phân phối giá phát hành theo hãng sản xuất (N = 556)",
        xlab = "Hãng sản xuất",
        ylab = "Giá phát hành (USD)",
        cex.lab = 1.15, cex.main = 1.2,
        outline = TRUE, notch = TRUE)

# Thêm mean marker
amd_mean <- mean(df_final$release_price[df_final$manufacturer == "AMD"])
nv_mean <- mean(df_final$release_price[df_final$manufacturer == "NVIDIA"])
points(1, amd_mean, pch = 18, col = "yellow", cex = 2)
points(2, nv_mean, pch = 18, col = "yellow", cex = 2)
legend("topright",
       legend = c(paste0("Mean AMD = $", round(amd_mean)),
                  paste0("Mean NVIDIA = $", round(nv_mean)),
                  "Notch = 95% CI of Median"),
       pch = c(18, 18, NA), col = c("yellow", "yellow", NA),
       cex = 0.85, bty = "n")
dev.off()
cat("--- Đã xuất figures/boxplot_nvidia_vs_amd.png ---\n")

# --- BIỂU ĐỒ TẦM QUAN TRỌNG HỆ SỐ (Coefficient Importance) ---
cat("\n--- 8. VẼ BIỂU ĐỒ TẦM QUAN TRỌNG HỆ SỐ ---\n")
coef_df <- summary(log_model_final)$coefficients
# Lọc bỏ Intercept, lấy tên biến và hệ số
var_names <- rownames(coef_df)[-1]
var_coefs <- coef_df[-1, "Estimate"]
var_pct <- (exp(var_coefs) - 1) * 100

# Nhãn tiếng Việt cho biểu đồ
display_names <- c("TDP (Công suất)", "Dung lượng RAM", "Băng thông Bus",
                   "Xung nhịp lõi", "Hãng NVIDIA", "Năm phát hành")

# Sắp xếp theo độ lớn tuyệt đối
ord <- order(abs(var_pct))
var_pct_sorted <- var_pct[ord]
display_sorted <- display_names[ord]
bar_cols <- ifelse(var_pct_sorted > 0, "#2c7fb8", "#e34a33")

png("figures/coefficient_importance.png", type = "cairo",
    width = 1800, height = 1000, res = 200)
par(mar = c(5, 10, 4, 4))
bp <- barplot(var_pct_sorted,
              names.arg = display_sorted,
              horiz = TRUE, las = 1,
              col = bar_cols, border = NA,
              main = "Tác động của từng biến lên giá GPU (%)",
              xlab = "Thay đổi giá (%) khi tăng 1 đơn vị",
              cex.names = 0.95, cex.lab = 1.1, cex.main = 1.15,
              xlim = c(min(var_pct_sorted) - 5, max(var_pct_sorted) + 12))
# Thêm nhãn giá trị
text(var_pct_sorted, bp, labels = paste0(ifelse(var_pct_sorted > 0, "+", ""),
     round(var_pct_sorted, 1), "%"),
     pos = ifelse(var_pct_sorted > 0, 4, 2), cex = 0.85, font = 2)
abline(v = 0, col = "gray40", lwd = 1.5, lty = 2)
legend("bottomright",
       legend = c("Tác động tăng giá", "Tác động giảm giá"),
       fill = c("#2c7fb8", "#e34a33"), cex = 0.85, bty = "n")
dev.off()
cat("--- Đã xuất figures/coefficient_importance.png ---\n")

# --- HISTOGRAM PHẦN DƯ ---
cat("\n--- 9. VẼ HISTOGRAM PHẦN DƯ ---\n")
png("figures/residual_histogram.png", type = "cairo",
    width = 1200, height = 800, res = 200)
par(mar = c(5, 5, 4, 2))
hist(resid_vals,
     breaks = 35, col = "#756bb1", border = "white",
     main = "Phân phối phần dư của mô hình Log-Linear",
     xlab = "Phần dư", ylab = "Tần suất",
     cex.lab = 1.1, cex.main = 1.15, freq = FALSE)
# Overlay đường cong phân phối chuẩn lý tưởng
curve(dnorm(x, mean = mean(resid_vals), sd = sd(resid_vals)),
      add = TRUE, col = "red", lwd = 2)
legend("topright",
       legend = c("Phần dư thực tế", "Phân phối chuẩn lý tưởng"),
       fill = c("#756bb1", NA), border = c("white", NA),
       lty = c(NA, 1), col = c(NA, "red"), lwd = c(NA, 2),
       cex = 0.85, bty = "n")
dev.off()
cat("--- Đã xuất figures/residual_histogram.png ---\n")


# 7.2. PHÂN TÍCH PHƯƠNG SAI (WELCH'S ANOVA) - CẬP NHẬT FINAL

# 1. Kiểm định tính đồng nhất phương sai (Levene's Test)
cat("\n--- 1. KIỂM ĐỊNH ĐỒNG NHẤT PHƯƠNG SAI (Levene's Test) ---\n")
print(leveneTest(release_price ~ manufacturer, data = df_final))

# 2. Thực hiện Welch's ANOVA 
# Do vi phạm đồng nhất phương sai và mẫu lớn (N=556), dùng Welch's ANOVA là tối ưu
cat("\n--- 2. KẾT QUẢ KIỂM ĐỊNH WELCH'S ANOVA ---\n")
anova_result <- oneway.test(release_price ~ manufacturer, data = df_final, var.equal = FALSE)
print(anova_result)

cat("\nLưu ý: Không thực hiện hậu kiểm (Post-hoc) vì chỉ còn 2 nhóm NVIDIA và AMD.\n")
cat("Kết quả ANOVA này về mặt toán học tương đương với Welch's T-test.\n")