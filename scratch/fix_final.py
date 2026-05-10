import sys
sys.stdout.reconfigure(encoding='utf-8')

with open('src/main.tex', 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    # 1) Remove the scatter plot code listing (code is trivial, figure already shown)
    ("\\textbf{7.1.4 V\u1ebd bi\u1ec3u \u0111\u1ed3 so s\u00e1nh gi\u00e1 th\u1ef1c t\u1ebf v\u1edbi gi\u00e1 d\u1ef1 \u0111o\u00e1n}\n\n\n\\begin{lstlisting}[language=R]\n#   Ve scatter plot\nplot(actual_values, predicted_values,\n     main=\"Bieu do so sanh gia thuc te voi gia du doan\",\n     xlab=\"Gia thuc te (USD)\",\n     ylab=\"Gia du doan (USD)\",\n     pch=19,\n     col=rgb(0.2, 0.4, 0.6, 0.5))\n#   Ke duong y=x de lam tham chieu ly tuong[cite: 4]\nabline(0, 1, col=\"red\", lwd=2)\n\\end{lstlisting}\n\nBi\u1ec3u \u0111\u1ed3 so s\u00e1nh gi\u00e1 th\u1ef1c t\u1ebf v\u1edbi gi\u00e1 d\u1ef1 \u0111o\u00e1n:",
     "\\textbf{7.1.4 Bi\u1ec3u \u0111\u1ed3 so s\u00e1nh gi\u00e1 th\u1ef1c t\u1ebf v\u1edbi gi\u00e1 d\u1ef1 \u0111o\u00e1n}"),

    # 2) Trim the "Lưu ý" for release_year in theory (Section 2)
    ("\\textbf{L\u01b0u \u00fd:} \u0110\u1ed1i v\u1edbi bi\u1ebfn \\texttt{release\\_year} (n\u0103m ph\u00e1t h\u00e0nh), sau khi parse, c\u00f3 d\u1ea1ng s\u1ed1 nguy\u00ean. \u0110\u1ec3 t\u1ed1i \u01b0u h\u00f3a kh\u1ea3 n\u0103ng di\u1ec5n gi\u1ea3i th\u1ef1c t\u1ebf c\u1ee7a m\u00f4 h\u00ecnh h\u1ed3i quy tuy\u1ebfn t\u00ednh (\u0111o l\u01b0\u1eddng tr\u1ef1c ti\u1ebfp m\u1ee9c thay \u0111\u1ed5i gi\u00e1 tr\u1ecb GPU sau m\u1ed7i m\u1ed9t n\u0103m tr\u00f4i qua), nh\u00f3m quy\u1ebft \u0111\u1ecbnh \\textbf{gi\u1eef nguy\u00ean gi\u00e1 tr\u1ecb g\u1ed1c} c\u1ee7a bi\u1ebfn n\u00e0y thay v\u00ec \u00e1p d\u1ee5ng chu\u1ea9n h\u00f3a Z-score nh\u01b0 c\u00e1c bi\u1ebfn th\u00f4ng s\u1ed1 k\u1ef9 thu\u1eadt kh\u00e1c. Vi\u1ec7c n\u00e0y gi\u00fap c\u00e1c h\u1ec7 s\u1ed1 m\u00f4 h\u00ecnh mang \u00fd ngh\u0129a kinh t\u1ebf h\u1ecdc tr\u1ef1c quan h\u01a1n.",
     "\\textbf{L\u01b0u \u00fd:} \\texttt{release\\_year} \u0111\u01b0\u1ee3c \\textbf{gi\u1eef nguy\u00ean gi\u00e1 tr\u1ecb g\u1ed1c} (kh\u00f4ng chu\u1ea9n h\u00f3a) \u0111\u1ec3 h\u1ec7 s\u1ed1 ph\u1ea3n \u00e1nh tr\u1ef1c ti\u1ebfp m\u1ee9c thay \u0111\u1ed5i gi\u00e1 m\u1ed7i n\u0103m."),

    # 3) Trim the "Kết quả so với kỳ vọng" in Section 5
    ("\\subsubsection{K\u1ebft qu\u1ea3 so v\u1edbi k\u1ef3 v\u1ecdng ban \u0111\u1ea7u}\n\nNh\u00ecn chung, k\u1ebft qu\u1ea3 thu \u0111\u01b0\u1ee3c \\textbf{v\u01b0\u1ee3t k\u1ef3 v\u1ecdng} v\u1ec1 m\u1eb7t th\u1ed1ng k\u00ea. M\u1ee5c ti\u00eau \u0111\u1eb7t ra l\u00e0 $R^2 \\geq 70\\%$ v\u00e0 m\u00f4 h\u00ecnh cu\u1ed1i c\u00f9ng \u0111\u1ea1t $R^2 = 78.54\\%$. Tuy nhi\u00ean, c\u00f3 m\u1ed9t \u0111i\u1ec3m \u0111\u00e1ng ch\u00fa \u00fd: m\u00f4 h\u00ecnh OLS ban \u0111\u1ea7u ch\u1ec9 \u0111\u1ea1t $R^2 = 29.8\\%$ v\u00e0 vi ph\u1ea1m hai gi\u1ea3 \u0111\u1ecbnh quan tr\u1ecdng, cho th\u1ea5y d\u1eef li\u1ec7u gi\u00e1 GPU c\u00f3 \u0111\u1eb7c tr\u01b0ng phi tuy\u1ebfn m\u1ea1nh (ph\u00e2n ph\u1ed1i l\u1ec7ch ph\u1ea3i c\u1ef1c \u0111oan v\u1edbi Skewness $= 16.84$) m\u00e0 m\u00f4 h\u00ecnh tuy\u1ebfn t\u00ednh thu\u1ea7n t\u00fay kh\u00f4ng x\u1eed l\u00fd \u0111\u01b0\u1ee3c. B\u01b0\u1edbc chuy\u1ec3n sang m\u00f4 h\u00ecnh Log-Linear l\u00e0 c\u1ea7n thi\u1ebft v\u00e0 hi\u1ec7u qu\u1ea3.",
     "K\u1ebft qu\u1ea3 \\textbf{v\u01b0\u1ee3t k\u1ef3 v\u1ecdng}: $R^2 = 78.54\\%$ (m\u1ee5c ti\u00eau $\\geq 70\\%$). B\u01b0\u1edbc chuy\u1ec3n t\u1eeb OLS ($R^2 = 29.8\\%$) sang Log-Linear l\u00e0 c\u1ea7n thi\u1ebft do d\u1eef li\u1ec7u gi\u00e1 GPU c\u00f3 ph\u00e2n ph\u1ed1i l\u1ec7ch ph\u1ea3i c\u1ef1c \u0111oan (Skewness $= 16.84$)."),
]

for i, (old, new) in enumerate(replacements):
    found = False
    for nl_to, label in [('\n', 'LF'), ('\r\n', 'CRLF')]:
        test_old = old.replace('\n', nl_to)
        if test_old in content:
            content = content.replace(test_old, new.replace('\n', nl_to))
            print(f"Replaced #{i+1} ({label})")
            found = True
            break
    if not found:
        print(f"NOT FOUND #{i+1}")

with open('src/main.tex', 'w', encoding='utf-8') as f:
    f.write(content)
