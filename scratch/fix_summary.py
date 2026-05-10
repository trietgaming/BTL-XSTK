with open('src/main.tex', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the summary console output block
old = """Kết quả trên console:
\\begin{lstlisting}[style=console]
Coefficients:
                 Estimate Std. Error t value Pr(>|t|)
(Intercept)      84.45346   22.49258   3.755 0.000192 ***
tdp               0.45471    0.01983  22.933  < 2e-16 ***
memory_size       0.17287    0.02134   8.101 3.54e-15 ***
memory_bus        0.07061    0.01532   4.610 5.01e-06 ***
core_speed        0.12173    0.02362   5.153 3.59e-07 ***
manufacturer2     0.37345    0.03610  10.345  < 2e-16 ***
release_year     -0.03924    0.01116  -3.517 0.000473 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 0.3388 on 549 degrees of freedom
Multiple R-squared:  0.7854,    Adjusted R-squared:  0.783
\\end{lstlisting}"""

new = r"Kết quả \texttt{summary()} cho thấy tất cả 6 biến đều có ý nghĩa thống kê (p $< 0.001$) với $R^2 = 78.54\%$. Bảng hệ số chi tiết được trình bày tại Phần~4."

# Try both LF and CRLF
for nl_from, nl_to, label in [('\n', '\n', 'LF'), ('\n', '\r\n', 'CRLF')]:
    test_old = old.replace('\n', nl_to)
    if test_old in content:
        content = content.replace(test_old, new.replace('\n', nl_to))
        print(f"Replaced summary console ({label})")
        break
else:
    print("NOT FOUND")

with open('src/main.tex', 'w', encoding='utf-8') as f:
    f.write(content)
