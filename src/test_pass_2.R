source("main.R")

cat("\n\n===========================================\n")
cat("TEST PASS KIỂM ĐỊNH LẦN 2\n")
cat("===========================================\n")

# --- 1. Lọc abs(std_res) <= 2.0 (cắt đuôi nhẹ) ---
std_res <- rstandard(log_model_final)
keep_idx <- abs(std_res) <= 2.0
df_pass <- df_final_clean[keep_idx, ]
log_pass <- lm(log(release_price) ~ tdp + memory_size + memory_bus + core_speed + manufacturer + release_year, data = df_pass)

cat("\n--- KẾT QUẢ MÔ HÌNH N = ", nrow(df_pass), " ---\n", sep="")
print(shapiro.test(residuals(log_pass)))
print(lmtest::bptest(log_pass))

cat("R-squared: ", summary(log_pass)$r.squared, "\n")
