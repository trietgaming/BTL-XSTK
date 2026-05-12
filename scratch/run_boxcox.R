setwd("C:/Users/Triet/OneDrive - MSFT/Documents/latexdev/src")
source("main.R")
library(MASS)

cat("\n\n===========================================\n")
cat("CHẠY PHÂN TÍCH BOX-COX\n")
cat("===========================================\n")

# Hồi quy với giá gốc (trước khi log)
base_model <- lm(release_price ~ tdp + memory_size + memory_bus + core_speed + manufacturer + release_year, data = df_final)

# Tìm lambda tối ưu bằng Box-Cox
bc <- boxcox(base_model, plotit = FALSE)

# Lấy lambda tốt nhất
best_lambda <- bc$x[which.max(bc$y)]

cat("\n=> Giá trị Lambda tối ưu:", best_lambda, "\n")

if (best_lambda >= -0.25 && best_lambda <= 0.25) {
  cat("=> Lambda rất gần 0. Điều này CHỨNG MINH RÕ RÀNG rằng phép biến đổi Logarit (tương đương Lambda = 0) là phép biến đổi tối ưu tự nhiên cho tập dữ liệu này.\n")
} else if (best_lambda > 0.25 && best_lambda <= 0.75) {
  cat("=> Lambda gần 0.5. Phép biến đổi căn bậc hai (Square Root) có thể phù hợp hơn.\n")
} else {
  cat("=> Phép biến đổi khác.\n")
}

# Chạy thử mô hình với Lambda tối ưu nếu khác 0
if(abs(best_lambda) > 0.0) {
    if (abs(best_lambda) < 1e-4) {
        y_trans <- log(df_final$release_price)
    } else {
        y_trans <- ((df_final$release_price ^ best_lambda) - 1) / best_lambda
    }
    
    trans_model <- lm(y_trans ~ tdp + memory_size + memory_bus + core_speed + manufacturer + release_year, data = df_final)
    
    cat("\n--- Kiểm định phân phối chuẩn phần dư (Shapiro-Wilk) với Box-Cox Lambda =", best_lambda, "---\n")
    print(shapiro.test(residuals(trans_model)))
    
    cat("\n--- Kiểm định phương sai sai số (Breusch-Pagan) với Box-Cox Lambda =", best_lambda, "---\n")
    print(lmtest::bptest(trans_model))
}
