with open('src/main.tex', 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    # 1) Replace OLS full table with inline summary
    (r"""\subsubsection{Mô hình OLS cơ sở}

\begin{table}[H]
\centering
\caption{Bảng hệ số hồi quy OLS}
\begin{tabular}{|l|r|r|r|r|l|}
\hline
\textbf{Biến} & \textbf{Hệ số ($\beta$)} & \textbf{Std. Error} & \textbf{t value} & \textbf{p-value} & \textbf{Ý nghĩa} \\
\hline
(Intercept) & $-14.078.20$ & 39.061.24 & $-0.360$ & 0.7187 & --- \\
tdp & 260.41 & 34.43 & 7.563 & $< 0.001$ & *** \\
memory\_size & 144.78 & 37.06 & 3.907 & $< 0.001$ & *** \\
memory\_bus & $-2.41$ & 26.60 & $-0.091$ & 0.9279 & --- \\
core\_speed & $-110.01$ & 41.03 & $-2.681$ & 0.0076 & ** \\
manufacturerNvidia & 281.69 & 62.69 & 4.493 & $< 0.001$ & *** \\
release\_year & 7.10 & 19.38 & 0.366 & 0.7142 & --- \\
\hline
\multicolumn{6}{|l|}{$R^2 = 0.2977$ | Adjusted $R^2 = 0.2900$ | $F(6,549) = 38.78$ | $p < 2.2 \times 10^{-16}$} \\
\hline
\end{tabular}
\end{table}

\textbf{Nhận xét:} Mô hình OLS chỉ giải thích được khoảng 29.77\% phương sai của giá. Ngoài ra, mô hình vi phạm hai giả định cơ bản: phân phối chuẩn phần dư ($W = 0.239$, $p < 2.2 \times 10^{-16}$) và đồng đều phương sai ($BP = 35.25$, $p = 3.86 \times 10^{-6}$). Nhóm chuyển sang mô hình Log-Linear.""",

     r"""\subsubsection{Mô hình OLS cơ sở}

Mô hình OLS ban đầu (giá gốc, chưa biến đổi log) cho kết quả kém: Adjusted $R^2 = 0.2900$ --- chỉ giải thích $\approx 29\%$ phương sai giá. Trong mô hình này, chỉ 3/6 biến có ý nghĩa (\texttt{tdp}, \texttt{memory\_size}, \texttt{manufacturerNvidia} với $p < 0.001$), trong khi \texttt{memory\_bus} ($p = 0.93$) và \texttt{release\_year} ($p = 0.71$) không có ý nghĩa. Ngoài ra, mô hình vi phạm nghiêm trọng hai giả định: phân phối chuẩn phần dư ($W = 0.239$, $p < 2.2 \times 10^{-16}$) và đồng đều phương sai ($BP = 35.25$, $p = 3.86 \times 10^{-6}$). Nhóm chuyển sang mô hình Log-Linear."""),

    # 2) Replace the Bước 2 full table with compact version
    (r"""\begin{table}[H]
\centering
\caption{Kết quả sau ép kiểu}
\begin{tabular}{|l|l|p{6cm}|}
\hline
\textbf{Biến} & \textbf{Kiểu dữ liệu} & \textbf{Phân phối / mô tả} \\
\hline
release\_price & numeric & Từ chuỗi ``\$240'' $\to$ 240 \\
tdp & numeric & Từ chuỗi ``141 Watts'' $\to$ 141 \\
memory\_size & numeric & Đơn vị MB \\
memory\_bus & numeric & Đơn vị Bit \\
core\_speed & numeric & Đơn vị MHz \\
release\_year & integer & Rút trích từ cột Release\_Date \\
manufacturer & factor & AMD: 1.409 | Nvidia: 1.743 (ATI đã gộp vào AMD) \\
memory\_type & factor & DDR3, GDDR3, GDDR5, GDDR5X, HBM-1, HBM-2 \\
\hline
\end{tabular}
\end{table}""",

     r"""Sau khi ép kiểu, 8 biến được chuyển đổi thành công: các biến số (\texttt{release\_price}, \texttt{tdp}, \texttt{memory\_size}, \texttt{memory\_bus}, \texttt{core\_speed}) ở dạng \texttt{numeric}; \texttt{release\_year} ở dạng \texttt{integer}; hai biến phân loại (\texttt{manufacturer}: AMD 1.409 $|$ Nvidia 1.743; \texttt{memory\_type}: 6 chuẩn VRAM) ở dạng \texttt{factor}."""),
]

for old, new in replacements:
    for nl_to, label in [('\n', 'LF'), ('\r\n', 'CRLF')]:
        test_old = old.replace('\n', nl_to)
        if test_old in content:
            content = content.replace(test_old, new.replace('\n', nl_to))
            print(f"Replaced ({label})")
            break
    else:
        print(f"NOT FOUND: {old[:60]}...")

with open('src/main.tex', 'w', encoding='utf-8') as f:
    f.write(content)
