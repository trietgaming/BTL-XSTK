import sys
sys.stdout.reconfigure(encoding='utf-8')

with open('src/main.tex', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the Dien giai table with inline itemize list
old = r"""\subsubsection{Diễn giải các hệ số hồi quy}

\begin{table}[H]
\centering
\caption{Diễn giải thực tế các hệ số hồi quy Log-Linear}
\begin{tabular}{|l|r|p{7cm}|}
\hline
\textbf{Biến} & \textbf{Hệ số $\beta$} & \textbf{Diễn giải thực tế} \\
\hline
tdp & 0.4547 & Tăng 1 đơn vị độ lệch chuẩn TDP $\to$ giá tăng $\approx 57.5\%$ ($e^{0.4547}-1$) \\
memory\_size & 0.1729 & Tăng 1 SD dung lượng RAM $\to$ giá tăng $\approx 18.9\%$ \\
memory\_bus & 0.0706 & Tăng 1 SD bus width $\to$ giá tăng $\approx 7.3\%$ \\
core\_speed & 0.1217 & Tăng 1 SD xung nhịp $\to$ giá tăng $\approx 12.9\%$ \\
manufacturerNvidia & 0.3735 & GPU Nvidia đắt hơn AMD $\approx 45.2\%$ ($e^{0.3735}-1$) cùng thông số \\
release\_year & $-0.0392$ & GPU ra năm sau rẻ hơn năm trước $\approx 3.8\%$ (hiệu ứng giảm giá theo thời gian) \\
\hline
\end{tabular}
\end{table}

\subsubsection{Kiểm định giả định mô hình Log-Linear}

\begin{table}[H]
\centering
\caption{Kết quả kiểm định giả định mô hình Log-Linear}
\begin{tabular}{|p{4.5cm}|p{4cm}|l|p{4cm}|}
\hline
\textbf{Kiểm định} & \textbf{Kết quả} & \textbf{p-value} & \textbf{Kết luận} \\
\hline
VIF --- tất cả biến & Tất cả $< 3.0$ & --- & Không có đa cộng tuyến \\
Breusch-Pagan (phương sai) & $BP = 99.04$, $df = 6$ & $< 2.2 \times 10^{-16}$ *** & Phương sai chưa hoàn toàn đồng đều \\
Shapiro-Wilk (chuẩn phần dư) & $W = 0.94765$ & $4.056 \times 10^{-13}$ *** & Gần chuẩn hơn OLS, nhưng vẫn vi phạm nhẹ \\
\hline
\end{tabular}
\end{table}"""

new = r"""\subsubsection{Diễn giải hệ số và kiểm định giả định}

\textbf{Diễn giải thực tế:} TDP có ảnh hưởng mạnh nhất: tăng 1~SD $\to$ giá tăng $\approx 57.5\%$ ($e^{0.4547}-1$). Tiếp theo là dung lượng RAM ($+18.9\%$/SD), xung nhịp ($+12.9\%$/SD), bus width ($+7.3\%$/SD). GPU Nvidia đắt hơn AMD $\approx 45.2\%$ ($e^{0.3735}-1$) cùng thông số. GPU ra sau rẻ hơn $\approx 3.8\%$/năm (hiệu ứng giảm giá theo thời gian).

\textbf{Kiểm định giả định:} VIF tất cả biến $< 3.0$ (không có đa cộng tuyến). Breusch-Pagan: $BP = 99.04$, $p < 2.2 \times 10^{-16}$ (phương sai chưa hoàn toàn đồng đều). Shapiro-Wilk: $W = 0.948$, $p = 4.056 \times 10^{-13}$ (gần chuẩn hơn OLS, vẫn vi phạm nhẹ)."""

for nl_to, label in [('\n', 'LF'), ('\r\n', 'CRLF')]:
    test_old = old.replace('\n', nl_to)
    if test_old in content:
        content = content.replace(test_old, new.replace('\n', nl_to))
        print(f"Replaced dien giai + kiem dinh ({label})")
        break
else:
    print("NOT FOUND")

with open('src/main.tex', 'w', encoding='utf-8') as f:
    f.write(content)
