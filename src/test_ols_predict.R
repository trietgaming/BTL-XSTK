source("main.R")

cat("\n\n===========================================\n")
cat("THỬ NGHIỆM DỰ ĐOÁN BẰNG MÔ HÌNH OLS GỐC (FOR SCIENCE)\n")
cat("===========================================\n")

new_gpus <- data.frame(
  name = c("GeForce GTX 1650", "GeForce GTX 1660", "Radeon RX 5500 XT", "Radeon RX 6600 XT", "GeForce RTX 3060", "GeForce RTX 2060", "Radeon RX 5700"),
  tdp = c(75, 120, 130, 160, 170, 160, 180),
  memory_size = c(4096, 6144, 8192, 8192, 12288, 6144, 8192),
  memory_bus = c(128, 192, 128, 128, 192, 192, 256),
  core_speed = c(1485, 1530, 1607, 1968, 1320, 1365, 1465),
  manufacturer = factor(c("Nvidia", "Nvidia", "AMD", "AMD", "Nvidia", "Nvidia", "AMD"), levels = c("AMD", "Nvidia")),
  release_year = c(2019, 2019, 2019, 2021, 2021, 2019, 2019),
  actual_msrp = c(149, 219, 199, 379, 329, 349, 349)
)

new_gpus_scaled <- new_gpus
new_gpus_scaled$tdp <- (new_gpus$tdp - mean(df_clean$tdp, na.rm=TRUE)) / sd(df_clean$tdp, na.rm=TRUE)
new_gpus_scaled$memory_size <- (new_gpus$memory_size - mean(df_clean$memory_size, na.rm=TRUE)) / sd(df_clean$memory_size, na.rm=TRUE)
new_gpus_scaled$memory_bus <- (new_gpus$memory_bus - mean(df_clean$memory_bus, na.rm=TRUE)) / sd(df_clean$memory_bus, na.rm=TRUE)
new_gpus_scaled$core_speed <- (new_gpus$core_speed - mean(df_clean$core_speed, na.rm=TRUE)) / sd(df_clean$core_speed, na.rm=TRUE)

# 0. Xây dựng mô hình OLS Sạch để so sánh
mlr_model_linear_clean <- lm(release_price ~ tdp + memory_size + memory_bus + core_speed + manufacturer + release_year, data = df_final_clean)

# 1. Dự đoán bằng mlr_model_linear_clean (OLS Sạch)
preds_ols <- predict(mlr_model_linear_clean, newdata = new_gpus_scaled, interval = "prediction", level = 0.95)

# 2. Dự đoán bằng log_model_final (Log-Linear)
preds_log <- predict(log_model_final, newdata = new_gpus_scaled, interval = "prediction", level = 0.95)
usd_preds_log <- exp(preds_log)

results <- data.frame(
  Name = new_gpus$name,
  Actual = new_gpus$actual_msrp,
  OLS_Pred = round(preds_ols[, "fit"], 2),
  OLS_Error = round((preds_ols[, "fit"] - new_gpus$actual_msrp) / new_gpus$actual_msrp * 100, 2),
  Log_Pred = round(usd_preds_log[, "fit"], 2),
  Log_Error = round((usd_preds_log[, "fit"] - new_gpus$actual_msrp) / new_gpus$actual_msrp * 100, 2),
  Log_Lower = round(usd_preds_log[, "lwr"], 2),
  Log_Upper = round(usd_preds_log[, "upr"], 2)
)

print(results)
