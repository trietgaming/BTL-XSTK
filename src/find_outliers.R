setwd("C:/Users/Triet/OneDrive - MSFT/Documents/latexdev/src")
source("main.R")

cat("\n\n===========================================\n")
cat("TRUY VẾT CÁC GPU DỊ BIỆT (OUTLIERS)\n")
cat("===========================================\n")

# Lấy lại tên GPU từ raw_data dựa trên row indices (filter của dplyr giữ lại row indices)
# Chú ý: main.R không giữ Name, nhưng ta có thể match theo release_price, tdp, core_speed... 
# Cách an toàn nhất là ta join ngược lại bằng các thuộc tính

raw_data$original_id <- 1:nrow(raw_data)

# Tái tạo lại các bước từ main.R nhưng giữ nguyên cột Name
df_with_name <- raw_data %>%
  select(Name, Release_Price, Max_Power, Memory, Memory_Bus, Core_Speed, Release_Date, Manufacturer) %>%
  rename(
    name          = Name,
    release_price = Release_Price, tdp          = Max_Power,
    memory_size   = Memory,        memory_bus   = Memory_Bus,
    core_speed    = Core_Speed,    release_date = Release_Date,
    manufacturer  = Manufacturer
  ) %>%
  mutate(manufacturer = ifelse(stringr::str_trim(manufacturer) == "ATI", "AMD", stringr::str_trim(manufacturer))) %>%
  mutate(
    release_price = as.numeric(stringr::str_extract(release_price, "\\d+\\.?\\d*")),
    tdp           = as.numeric(stringr::str_extract(tdp,           "\\d+\\.?\\d*")),
    memory_size   = as.numeric(stringr::str_extract(memory_size,   "\\d+\\.?\\d*")),
    memory_bus    = as.numeric(stringr::str_extract(memory_bus,    "\\d+\\.?\\d*")),
    core_speed    = as.numeric(stringr::str_extract(core_speed,    "\\d+\\.?\\d*")),
    release_year  = as.integer(format(as.Date(stringr::str_trim(release_date), "%d-%b-%Y"), "%Y"))
  )

# Lọc y như main.R
price_raw_vec <- na.omit(df_with_name$release_price)
price_upper   <- quantile(price_raw_vec, 0.75) + 1.5 * IQR(price_raw_vec)

df_clean_named <- df_with_name %>%
  filter(!is.na(release_price), manufacturer != "Intel", release_price <= price_upper) %>%
  mutate(
    tdp = ifelse(is.na(tdp), median(tdp, na.rm = TRUE), tdp),
    core_speed = ifelse(is.na(core_speed), median(core_speed, na.rm = TRUE), core_speed)
  )

# Lấy Standardized Residuals từ mô hình Log-Linear hiện tại
std_res <- rstandard(log_model_final)

# Gắn residuals vào df
df_clean_named$std_res <- std_res
df_clean_named$predicted_price <- exp(fitted(log_model_final))

# Lọc ra các điểm DỊ BIỆT (có std_res > 2.5 hoặc < -2.5)
outliers <- df_clean_named %>% 
  filter(abs(std_res) > 2.5) %>%
  arrange(desc(abs(std_res))) %>%
  select(name, manufacturer, release_price, predicted_price, std_res)

cat(sprintf("\nPhát hiện %d GPU dị biệt (Standardized Residual > 2.5) trong mẫu %d GPUs.\n\n", nrow(outliers), nrow(df_clean_named)))

print(outliers)

cat("\n===========================================\n")
cat("NHẬN XÉT CÁC GPU BỊ ĐỊNH GIÁ CAO BẤT THƯỜNG (Std Res > 2.5):\n")
over_priced <- outliers %>% filter(std_res > 2.5)
if(nrow(over_priced) > 0) print(over_priced)

# ==========================================
# TEST: Filter out these specific structural outliers by regex on Name
# ==========================================
df_clean_filtered <- df_clean_named %>%
  filter(
    !str_detect(name, "(?i)Quadro"),
    !str_detect(name, "(?i)Crossfire|Dual Core"),
    !str_detect(name, "(?i)\\[not released\\]"),
    !str_detect(name, "(?i)Hydro Copper")
  )

cat("\n\n--- KẾT QUẢ MÔ HÌNH SAU KHI LỌC BỎ CÁC OUTLIERS CẤU TRÚC ---\n")
test_log_model <- lm(log(release_price) ~ tdp + memory_size + memory_bus + core_speed + manufacturer + release_year, data = df_clean_filtered)

cat(sprintf("Số mẫu mới: %d\n", nrow(df_clean_filtered)))
print(summary(test_log_model))
print(lmtest::bptest(test_log_model))
print(shapiro.test(residuals(test_log_model)))

