setwd("C:/Users/Triet/OneDrive - MSFT/Documents/latexdev/src")
source("main.R")

cat("\n\n===========================================\n")
cat("DỰ ĐOÁN GIÁ GPU MỚI (OUT-OF-SAMPLE)\n")
cat("===========================================\n")

new_gpus <- data.frame(
  name = c("GeForce GTX 1650", "GeForce GTX 1660", "Radeon RX 5500 XT (8GB)", "Radeon RX 5600 XT", "GeForce RTX 3060 12GB"),
  tdp = c(75, 120, 130, 150, 170),
  memory_size = c(4096, 6144, 8192, 6144, 12288),
  memory_bus = c(128, 192, 128, 192, 192),
  core_speed = c(1485, 1530, 1607, 1130, 1320),
  manufacturer = factor(c("Nvidia", "Nvidia", "AMD", "AMD", "Nvidia"), levels = c("AMD", "Nvidia")),
  release_year = c(2019, 2019, 2019, 2020, 2021),
  actual_msrp = c(149, 219, 199, 279, 329)
)

# Chuẩn hóa Z-score dựa trên tập dữ liệu đã lọc df_clean
new_gpus_scaled <- new_gpus
new_gpus_scaled$tdp <- (new_gpus$tdp - mean(df_clean$tdp, na.rm=TRUE)) / sd(df_clean$tdp, na.rm=TRUE)
new_gpus_scaled$memory_size <- (new_gpus$memory_size - mean(df_clean$memory_size, na.rm=TRUE)) / sd(df_clean$memory_size, na.rm=TRUE)
new_gpus_scaled$memory_bus <- (new_gpus$memory_bus - mean(df_clean$memory_bus, na.rm=TRUE)) / sd(df_clean$memory_bus, na.rm=TRUE)
new_gpus_scaled$core_speed <- (new_gpus$core_speed - mean(df_clean$core_speed, na.rm=TRUE)) / sd(df_clean$core_speed, na.rm=TRUE)

# Dự đoán log price
log_preds <- predict(log_model_final, newdata = new_gpus_scaled, interval = "prediction", level = 0.95)

# Chuyển đổi về USD
usd_preds <- exp(log_preds)

results <- data.frame(
  Name = new_gpus$name,
  Actual_MSRP = new_gpus$actual_msrp,
  Predicted_Price = round(usd_preds[, "fit"], 2),
  Lower_95 = round(usd_preds[, "lwr"], 2),
  Upper_95 = round(usd_preds[, "upr"], 2)
)

results$Error_Percent = round((results$Predicted_Price - results$Actual_MSRP) / results$Actual_MSRP * 100, 2)

print(results)
