source("main.R")

cat("\n\n===========================================\n")
cat("TEST GPU 'CHUẨN MỰC' CHO DỰ ĐOÁN\n")
cat("===========================================\n")

new_gpus <- data.frame(
  name = c("GeForce RTX 2060", "GeForce RTX 2070", "Radeon RX 5700"),
  tdp = c(160, 175, 180),
  memory_size = c(6144, 8192, 8192),
  memory_bus = c(192, 256, 256),
  core_speed = c(1365, 1410, 1465),
  manufacturer = factor(c("Nvidia", "Nvidia", "AMD"), levels = c("AMD", "Nvidia")),
  release_year = c(2019, 2018, 2019),
  actual_msrp = c(349, 499, 349)
)

new_gpus_scaled <- new_gpus
new_gpus_scaled$tdp <- (new_gpus$tdp - mean(df_clean$tdp, na.rm=TRUE)) / sd(df_clean$tdp, na.rm=TRUE)
new_gpus_scaled$memory_size <- (new_gpus$memory_size - mean(df_clean$memory_size, na.rm=TRUE)) / sd(df_clean$memory_size, na.rm=TRUE)
new_gpus_scaled$memory_bus <- (new_gpus$memory_bus - mean(df_clean$memory_bus, na.rm=TRUE)) / sd(df_clean$memory_bus, na.rm=TRUE)
new_gpus_scaled$core_speed <- (new_gpus$core_speed - mean(df_clean$core_speed, na.rm=TRUE)) / sd(df_clean$core_speed, na.rm=TRUE)

log_preds <- predict(log_model_final, newdata = new_gpus_scaled, interval = "prediction", level = 0.95)
usd_preds <- exp(log_preds)

results <- data.frame(
  Name = new_gpus$name,
  Actual_MSRP = new_gpus$actual_msrp,
  Predicted_Price = round(usd_preds[, "fit"], 2),
  Error_Percent = round((usd_preds[, "fit"] - new_gpus$actual_msrp) / new_gpus$actual_msrp * 100, 2)
)

print(results)
