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

# Tầng 3: xác định biến bị loại do tỷ lệ khuyết >= 30%
# Bỏ qua biến phụ thuộc (Y) Release_Price vì dòng chứa NA sẽ bị xóa ở bước sau
dropped_high_missing <- names(missing_pct[missing_pct >= 30 & names(missing_pct) != "Release_Price"])
cat("\n--- Biến có tỷ lệ khuyết >= 30% (tầng 3) ---\n")
cat(paste(dropped_high_missing, collapse = ", "), "\n")

# Bắt buộc giữ Y và 7 biến X còn lại sau khi trừ đi các biến ở tầng 1, 2
kept_vars <- c("Release_Price", "Max_Power", "Memory", "Memory_Bus",
               "Core_Speed", "Release_Date", "Manufacturer", "Memory_Type")

missing_df <- data.frame(
  variable = names(missing_pct),
  pct = as.numeric(missing_pct),
  kept = names(missing_pct) %in% kept_vars
)
missing_df <- missing_df[order(-missing_df$pct), ]

# Gộp các biến xám: tính trung bình missing % của chúng
other_vars <- missing_df[!missing_df$kept & missing_df$pct < 30, ]
avg_other_pct <- mean(other_vars$pct)
other_count <- nrow(other_vars)

# Tạo bảng hiển thị: biến giữ + biến đỏ + 1 hàng "Các biến khác"
missing_df_plot <- rbind(
  missing_df[missing_df$kept | missing_df$pct >= 30, ],
  data.frame(
    variable = paste("Trung bình các biến khác", sprintf("(%d)", other_count)),
    pct = avg_other_pct,
    kept = FALSE
  )
)

bar_colors_plot <- with(missing_df_plot,
  ifelse(kept, "#2c7fb8",
    ifelse(pct >= 30, "#e34a33", "#bdbdbd")))

png("figures/missing_data_ratio.png", type = "cairo",
    width = 2400, height = 1400, res = 300)
par(mar = c(5, 15, 4, 2))
barplot(rev(missing_df_plot$pct),
        names.arg = rev(missing_df_plot$variable),
        horiz = TRUE, las = 1,
        col = rev(bar_colors_plot),
        xlim = c(0, 100),
        xlab = "Tỷ lệ dữ liệu khuyết (%)",
        main = "Tỷ lệ dữ liệu khuyết (N = 3.406)",
        cex.names = 0.85, cex.main = 1.05)
abline(v = 30, col = "red", lty = 2, lwd = 1.5)
legend("bottomright",
       legend = c("Biến được chọn (8)", "Bị loại (thiếu >= 30%)", "Các biến khác"),
       fill = c("#2c7fb8", "#e34a33", "#bdbdbd"),
       cex = 0.85, bty = "n")
dev.off()
cat("\n--- Đã xuất figures/missing_data_ratio.png ---\n")

# BƯỚC 2: CHỌN LỌC, ĐỔI TÊN VÀ ÉP KIỂU DỮ LIỆU

# --- 2.1: Chọn cột và đổi tên ---
df <- raw_data %>%
  select(Name, Release_Price, Max_Power, Memory, Memory_Bus,
         Core_Speed, Release_Date, Manufacturer, Memory_Type) %>%
  rename(
    name          = Name,
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

# BƯỚC 3: NHẬN DIỆN VÀ LOẠI BỎ NGOẠI LỆ (IQR TRÊN TẬP GỐC)

# 3.1: Tính ranh giới Tukey cho CÁC BIẾN SỐ LIÊN TỤC trên tập thô (trước mọi lọc và điền khuyết)
calc_tukey <- function(vec) {
  v <- na.omit(vec)
  q1 <- quantile(v, 0.25); q3 <- quantile(v, 0.75); iqr <- q3 - q1
  list(q1=q1, q3=q3, iqr=iqr, lower=q1-1.5*iqr, upper=q3+1.5*iqr)
}

price_bnd  <- calc_tukey(df$release_price)

cat(sprintf("\n--- Ranh giới Tukey release_price (tập thô N=%d) ---\n", nrow(df)))
cat(sprintf("release_price: Q1=%.0f,  Q3=%.0f,  IQR=%.0f,  Ngưỡng trên=%.2f\n",
            price_bnd$q1,  price_bnd$q3,  price_bnd$iqr,  price_bnd$upper))

# BƯỚC 4: LOẠI BỎ QUAN SÁT KHÔNG HỢP LỆ VÀ ĐIỀN GIÁ TRỊ KHUYẾT

# 4.1: Lọc dữ liệu: bỏ NA giá, Intel, và TẤT CẢ ngoại lệ IQR (tiền xử lý trước mô hình)
n_has_price_no_intel <- nrow(df %>% filter(!is.na(release_price), manufacturer != "Intel"))
df_clean <- df %>%
  filter(!is.na(release_price)) %>%
  filter(manufacturer != "Intel") %>%
  filter(release_price <= price_bnd$upper)

cat(sprintf("\n=> Số quan sát ban đầu (có giá, không Intel): %d\n", n_has_price_no_intel))
cat(sprintf("=> Sau khi loại tất cả ngoại lệ IQR: %d (đã loại %d quan sát)\n",
            nrow(df_clean), n_has_price_no_intel - nrow(df_clean)))

df_clean$manufacturer <- factor(df_clean$manufacturer)
N_clean <- nrow(df_clean)

# 3.2: Boxplot trực quan hóa ranh giới ngoại lai trên tập thô
png("figures/boxplot_outliers.png", type="cairo", width=900, height=400, res=120)
par(mfrow=c(1,3))
boxplot(df$release_price, main="Giá (Tập thô, Log-scale)", col="lightblue", ylab="USD (log scale)", log="y")
abline(h = price_bnd$upper, col="red", lty=2, lwd=2) # Vẽ ranh giới Tukey
boxplot(df$tdp,           main="TDP (Tập thô)", col="lightgreen", ylab="Watts")
boxplot(df$core_speed,    main="Core Speed (Tập thô)", col="salmon", ylab="MHz")
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
      main = sprintf("Ma trận tương quan Pearson giữa các biến số (N = %d)", N_clean))
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


cat("\n--- THỐNG KÊ MÔ TẢ RELEASE_PRICE (sau khi lọc) ---\n")
cat(sprintf("N = %d\n", N_clean))
cat(sprintf("Mean  = %.2f\n", mean(df_clean$release_price)))
cat(sprintf("Median= %.2f\n", median(df_clean$release_price)))
cat(sprintf("SD    = %.2f\n", sd(df_clean$release_price)))
cat(sprintf("Max   = %.2f\n", max(df_clean$release_price)))
cat(sprintf("Min   = %.2f\n", min(df_clean$release_price)))

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

# --- 7.1.1: Mô hình đầy đủ (7 biến, Y gốc) → kiểm định VIF ---
cat("\n--- 7.1.1. MÔ HÌNH ĐẦY ĐỦ & KIỂM ĐỊNH VIF ---\n")
mlr_model_initial <- lm(release_price ~ tdp + memory_size + memory_bus +
                          core_speed + manufacturer + memory_type + release_year,
                        data = df_final)
vif_initial <- vif(mlr_model_initial)
print(vif_initial)
cat("=> memory_type GVIF =", round(vif_initial["memory_type", "GVIF"], 2),
    "> 5: loại biến, xây lại mô hình.\n")

# --- 7.1.2: Mô hình cơ sở (Y gốc, đã loại memory_type) → kiểm định giả định OLS ---
cat("\n--- 7.1.2. MÔ HÌNH CƠ SỞ (Y gốc, 6 biến) & KIỂM ĐỊNH GIẢ ĐỊNH OLS ---\n")
mlr_model_base <- lm(release_price ~ tdp + memory_size + memory_bus +
                       core_speed + manufacturer + release_year, data = df_final)
summary(mlr_model_base)

cat("\n--- VIF lần 2 (xác nhận tất cả < 5) ---\n")
print(vif(mlr_model_base))

# --- 7.1.3: Lọc ngoại lai cấu trúc từ phần dư mô hình cơ sở ---
cat("\n--- 7.1.3. LỌC NGOẠI LAI CẤU TRÚC (Standardized Residuals) ---\n")
std_res_base <- rstandard(mlr_model_base)
outlier_mask <- abs(std_res_base) > 2.5 &
  grepl("(?i)Quadro|Crossfire|Dual[ .]Core|Hydro[ .]Copper|not[ .]released",
        df_final$name, perl = TRUE)
n_structural <- sum(outlier_mask)
cat(sprintf("=> Phát hiện %d ngoại lai cấu trúc (Quadro/Crossfire/Hydro Copper/not released).\n",
            n_structural))

df_final_clean <- df_final[!outlier_mask, ]
N_final <- nrow(df_final_clean)
cat(sprintf("=> Tập dữ liệu chính thức: N = %d (loại %d quan sát)\n",
            N_final, N_clean - N_final))

cat("\n--- 7.1.4. MÔ HÌNH LOG-LINEAR CHÍNH THỨC (N = ", N_final, ") ---\n", sep="")
log_model_final <- lm(log(release_price) ~ tdp + memory_size + memory_bus +
                        core_speed + manufacturer + release_year, data = df_final_clean)
summary(log_model_final)

# Kiểm định lại giả định trên mô hình log-linear final
cat("\n--- VIF (mô hình log-linear, xác nhận < 5) ---\n")
print(vif(log_model_final))

cat("\n--- Breusch-Pagan (mô hình log-linear) ---\n")
print(bptest(log_model_final))

cat("\n--- Shapiro-Wilk (mô hình log-linear) ---\n")
print(shapiro.test(residuals(log_model_final)))


# Giai đoạn 4: Trực quan hóa kết quả
cat("\n--- 4. VẼ BIỂU ĐỒ SO SÁNH THỰC TẾ & DỰ ĐOÁN ---\n")
# Dùng exp() để đưa giá trị log về lại tiền USD để so sánh
predicted_values <- exp(predict(log_model_final))
actual_values <- df_final_clean$release_price

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
hist(df_final_clean$release_price,
     breaks = 40, col = "#2c7fb8", border = "white",
     main = "Phân phối giá phát hành (USD)",
     xlab = "Giá (USD)", ylab = "Tần suất",
     cex.lab = 1.1, cex.main = 1.15)
abline(v = median(df_final_clean$release_price), col = "red", lwd = 2, lty = 2)
abline(v = mean(df_final_clean$release_price), col = "#e34a33", lwd = 2, lty = 3)
legend("topright",
       legend = c(paste0("Median = $", round(median(df_final_clean$release_price))),
                  paste0("Mean = $", round(mean(df_final_clean$release_price)))),
       col = c("red", "#e34a33"), lty = c(2, 3), lwd = 2,
       cex = 0.85, bty = "n")

# Panel phải: Phân phối log(giá)
hist(log(df_final_clean$release_price),
     breaks = 30, col = "#41ae76", border = "white",
     main = "Phân phối log(giá phát hành)",
     xlab = "log(Giá)", ylab = "Tần suất",
     cex.lab = 1.1, cex.main = 1.15)
abline(v = median(log(df_final_clean$release_price)), col = "red", lwd = 2, lty = 2)
abline(v = mean(log(df_final_clean$release_price)), col = "#e34a33", lwd = 2, lty = 3)
legend("topright",
       legend = c(paste0("Median = ", round(median(log(df_final_clean$release_price)), 2)),
                  paste0("Mean = ", round(mean(log(df_final_clean$release_price)), 2))),
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
boxplot(release_price ~ manufacturer, data = df_final_clean,
        col = c("#e34a33", "#2c7fb8"),
        main = sprintf("Phân phối giá phát hành theo hãng sản xuất (N = %d)", N_final),
        xlab = "Hãng sản xuất",
        ylab = "Giá phát hành (USD)",
        cex.lab = 1.15, cex.main = 1.2,
        outline = TRUE, notch = TRUE)

# Thêm mean marker
amd_mean <- mean(df_final_clean$release_price[df_final_clean$manufacturer == "AMD"])
nv_mean <- mean(df_final_clean$release_price[df_final_clean$manufacturer == "Nvidia"])
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



# 2. Thực hiện Welch's ANOVA
cat("\n--- 2. KẾT QUẢ KIỂM ĐỊNH WELCH'S ANOVA ---\n")
anova_result <- oneway.test(release_price ~ manufacturer, data = df_final_clean, var.equal = FALSE)
print(anova_result)

cat("\nLưu ý: Không thực hiện hậu kiểm (Post-hoc) vì chỉ còn 2 nhóm NVIDIA và AMD.\n")
cat("Kết quả ANOVA này về mặt toán học tương đương với Welch's T-test.\n")

# --- IN THỐNG KÊ CHI TIẾT CHO LATEX ---
cat("\n===== THỐNG KÊ CHO LATEX =====\n")
cat(sprintf("N_total = %d\n", N_final))
amd_data  <- df_final_clean$release_price[df_final_clean$manufacturer == "AMD"]
nv_data   <- df_final_clean$release_price[df_final_clean$manufacturer == "Nvidia"]
cat(sprintf("AMD:    n=%d, mean=%.2f, median=%.2f, sd=%.2f\n",
            length(amd_data), mean(amd_data), median(amd_data), sd(amd_data)))
cat(sprintf("NVIDIA: n=%d, mean=%.2f, median=%.2f, sd=%.2f\n",
            length(nv_data), mean(nv_data), median(nv_data), sd(nv_data)))
cat(sprintf("Chênh lệch mean NVIDIA - AMD = %.2f\n", mean(nv_data) - mean(amd_data)))

cat("\n--- Hệ số hồi quy Log-Linear ---\n")
coef_summary <- summary(log_model_final)$coefficients
print(round(coef_summary, 6))
cat(sprintf("R2        = %.4f\n", summary(log_model_final)$r.squared))
cat(sprintf("Adj R2    = %.4f\n", summary(log_model_final)$adj.r.squared))
cat(sprintf("F-stat    = %.2f\n", summary(log_model_final)$fstatistic[1]))
cat(sprintf("df1=%d, df2=%d\n", summary(log_model_final)$fstatistic[2],
            summary(log_model_final)$fstatistic[3]))

cat("\n--- Tác động % của từng biến ---\n")
coef_vals <- coef_summary[-1, "Estimate"]
pct_effect <- (exp(coef_vals) - 1) * 100
for (nm in names(pct_effect)) cat(sprintf("  %s: %.2f%%\n", nm, pct_effect[nm]))

cat("\n--- Skewness giá gốc ---\n")
price_vals <- df_final_clean$release_price
n_sk <- length(price_vals)
skew_val <- (n_sk / ((n_sk-1)*(n_sk-2))) * sum(((price_vals - mean(price_vals))/sd(price_vals))^3)
cat(sprintf("Skewness = %.4f\n", skew_val))
cat("===== KẾT THÚC THỐNG KÊ =====\n")