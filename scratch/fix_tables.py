with open('src/main.tex', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix ANOVA table - remove booktabs rules and use hline instead since we have | separators
replacements = [
    # Fix ANOVA table
    (r"""\begin{tabular}{|l|r|r|r|r|}
\toprule
\textbf{Hãng} & \textbf{n} & \textbf{Mean (USD)} & \textbf{Median (USD)} & \textbf{SD (USD)} \\
\midrule
AMD & 272 & \$246.30 & \$200.00 & \$197.93 \\
Nvidia & 284 & \$491.73 & \$324.50 & \$943.42 \\
\midrule
\multicolumn{5}{|l|}{\textbf{Levene's Test:} $F = 11.168$, $p = 0.000888$ $\to$ Phương sai KHÔNG đồng nhất} \\
\multicolumn{5}{|l|}{\textbf{Welch's ANOVA:} $F = 18.39$, $df_1 = 1$, $df_2 = 309.05$, $p = 2.409 \times 10^{-5}$ ***} \\
\bottomrule""",

     r"""\begin{tabular}{|l|r|r|r|r|}
\hline
\textbf{Hãng} & \textbf{n} & \textbf{Mean (USD)} & \textbf{Median (USD)} & \textbf{SD (USD)} \\
\hline
AMD & 272 & \$246.30 & \$200.00 & \$197.93 \\
Nvidia & 284 & \$491.73 & \$324.50 & \$943.42 \\
\hline
\multicolumn{5}{|l|}{\textbf{Levene's Test:} $F = 11.168$, $p = 0.000888$ $\to$ Phương sai KHÔNG đồng nhất} \\
\multicolumn{5}{|l|}{\textbf{Welch's ANOVA:} $F = 18.39$, $df_1 = 1$, $df_2 = 309.05$, $p = 2.409 \times 10^{-5}$ ***} \\
\hline"""),

    # Fix variable table too
    (r"""\begin{tabular}{|l|l|p{5.5cm}|l|}
\toprule
\textbf{Biến} & \textbf{Kiểu} & \textbf{Mô tả} & \textbf{Vai trò} \\
\midrule""",
     r"""\begin{tabular}{|l|l|p{5.5cm}|l|}
\hline
\textbf{Biến} & \textbf{Kiểu} & \textbf{Mô tả} & \textbf{Vai trò} \\
\hline"""),

    (r"""\bottomrule
\end{tabular}
\end{table}
}""",
     r"""\hline
\end{tabular}
\end{table}
}"""),
]

for old, new in replacements:
    for nl_to, label in [('\n', 'LF'), ('\r\n', 'CRLF')]:
        test_old = old.replace('\n', nl_to)
        if test_old in content:
            content = content.replace(test_old, new.replace('\n', nl_to))
            print(f"Replaced ({label}): {old[:40]}...")
            break
    else:
        print(f"NOT FOUND: {old[:40]}...")

with open('src/main.tex', 'w', encoding='utf-8') as f:
    f.write(content)
