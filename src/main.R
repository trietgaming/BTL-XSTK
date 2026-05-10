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

# BƯỚC 2: CHỌN LỌC CỘT VÀ ÉP KIỂU DỮ LIỆU

# Chọn lọc 8 biến chính và đổi tên cho giống mô tả trong lý thuyết
df <- raw_data %>%
  select(Release_Price, Max_Power, Memory, Memory_Bus, Core_Speed, Release_Date, Manufacturer, Memory_Type, Memory_Speed) %>%
  rename(
    release_price = Release_Price,
    tdp = Max_Power,
    memory_size = Memory,
    memory_bus = Memory_Bus,
    core_speed = Core_Speed,
    release_date = Release_Date,
    manufacturer = Manufacturer,
    memory_type = Memory_Type,
    memory_speed = Memory_Speed
  )

# Xử lý chuỗi, ép kiểu số và gộp nhãn ATI -> AMD
df <- df %>%
  mutate(
    # Gộp ATI vào AMD trước khi thực hiện các bước khác
    manufacturer = ifelse(str_trim(manufacturer) == "ATI", "AMD", str_trim(manufacturer)),
        release_price = as.numeric(str_extract(release_price, "\\d+\\.?\\d*")),
    tdp = as.numeric(str_extract(tdp, "\\d+\\.?\\d*")),
    memory_size = as.numeric(str_extract(memory_size, "\\d+\\.?\\d*")),
    memory_bus = as.numeric(str_extract(memory_bus, "\\d+\\.?\\d*")),
    core_speed = as.numeric(str_extract(core_speed, "\\d+\\.?\\d*")),
        release_date = str_trim(release_date),
    release_year = as.integer(format(as.Date(release_date, format="%d-%b-%Y"), "%Y"))
  ) %>%
  select(-release_date) 

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
boxplot(df_clean$release_price, main="Gia (N=556)", col="lightblue", ylab="USD")
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
    # Điền NA bằng Median cho biến số liên tục
    tdp = ifelse(is.na(tdp), median(tdp, na.rm = TRUE), tdp),
    memory_size = ifelse(is.na(memory_size), median(memory_size, na.rm = TRUE), memory_size),
    memory_bus = ifelse(is.na(memory_bus), median(memory_bus, na.rm = TRUE), memory_bus),
    core_speed = ifelse(is.na(core_speed), median(core_speed, na.rm = TRUE), core_speed),
    release_year = ifelse(is.na(release_year), median(release_year, na.rm = TRUE), release_year),
    
    # Điền NA bằng Mode cho biến phân loại
    memory_type = ifelse(is.na(memory_type) | memory_type == "", get_mode(memory_type), memory_type),
    manufacturer = ifelse(is.na(as.character(manufacturer)) | as.character(manufacturer) == "",
                          get_mode(as.character(manufacturer)), as.character(manufacturer))
  )
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
     main="Bieu do so sanh gia thuc te voi gia du doan",
     xlab="Gia thuc te (USD)",
     ylab="Gia du doan (USD)",
     pch=19,
     col=rgb(0.2, 0.4, 0.6, 0.5))
# Kẻ đường y=x để làm tham chiếu lý tưởng
abline(0, 1, col="red", lwd=2)
dev.off()

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