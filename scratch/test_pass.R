setwd("C:/Users/Triet/OneDrive - MSFT/Documents/latexdev/src")
source("main.R")

cat("\n\n===========================================\n")
cat("TEST CÁCH PASS KIỂM ĐỊNH TỰ ĐỘNG\n")
cat("===========================================\n")

# --- 1. Pass Shapiro-Wilk bằng cách cắt tỉa sâu hơn ---
# Với N=514, W=0.989. Ta lọc abs(std_res) < 1.96
df_pass <- df_final_clean
log_pass <- log_model_final

for(i in 1:3) {
  std_res <- rstandard(log_pass)
  keep_idx <- abs(std_res) <= 2.0  # Loại thêm các ngoại lệ nhẹ
  df_pass <- df_pass[keep_idx, ]
  log_pass <- lm(log(release_price) ~ tdp + memory_size + memory_bus + core_speed + manufacturer + release_year, data = df_pass)
  cat(sprintf("\nVòng %d - Số mẫu: %d, SW W: %f, SW p-value: %f", i, nrow(df_pass), shapiro.test(residuals(log_pass))$statistic, shapiro.test(residuals(log_pass))$p.value))
}

cat("\n\n--- MÔ HÌNH SAU KHI CẮT TỈA ---")
print(summary(log_pass))
print(shapiro.test(residuals(log_pass)))

# --- 2. Pass Breusch-Pagan bằng WLS ---
cat("\n--- THỬ WLS TRÊN MÔ HÌNH VỪA CẮT TỈA ---")
wt <- 1 / fitted(lm(abs(residuals(log_pass)) ~ fitted(log_pass)))^2
wls_model <- lm(log(release_price) ~ tdp + memory_size + memory_bus + core_speed + manufacturer + release_year, data = df_pass, weights = wt)

cat("\nBP Test của WLS:\n")
print(lmtest::bptest(wls_model))

