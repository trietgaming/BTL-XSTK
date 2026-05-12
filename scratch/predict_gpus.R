setwd("C:/Users/Triet/OneDrive - MSFT/Documents/latexdev/src")
source("main.R")

cat("\n\n===========================================\n")
cat("DỰ ĐOÁN GIÁ GPU MỚI (OUT-OF-SAMPLE)\n")
cat("===========================================\n")

# Tạo dataframe cho 2 GPU mới: GTX 1650 và GTX 1660
new_gpus <- data.frame(
  name = c("GeForce GTX 1650", "GeForce GTX 1660"),
  tdp = c(75, 120),
  memory_size = c(4096, 6144),
  memory_bus = c(128, 192),
  core_speed = c(1485, 1530),
  manufacturer = factor(c("Nvidia", "Nvidia"), levels = c("AMD", "Nvidia")),
  release_year = c(2019, 2019),
  actual_msrp = c(149, 219)
)

# Dự đoán log price
log_preds <- predict(log_model_final, newdata = new_gpus, interval = "prediction", level = 0.95)

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
