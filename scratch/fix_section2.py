import sys
sys.stdout.reconfigure(encoding='utf-8')

with open('src/main.tex', 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    # 1) Shorten the verbose outlier detection note
    ("\\textbf{K\u1ebft qu\u1ea3 ph\u00e1t hi\u1ec7n:} (\\textit{L\u01b0u \u00fd v\u1ec1 tr\u00ecnh t\u1ef1 th\u1ef1c thi: \u0110\u1ec3 ranh gi\u1edbi ph\u00e2n v\u1ecb IQR kh\u00f4ng b\u1ecb thu h\u1eb9p gi\u1ea3 t\u1ea1o, h\u00e0m \\texttt{count\\_outliers()} \u0111\u01b0\u1ee3c ch\u1ea1y ngay t\u1ea1i B\u01b0\u1edbc~3 tr\u00ean to\u00e0n b\u1ed9 t\u1eadp d\u1eef li\u1ec7u th\u00f4 $N = 3.406$ tr\u01b0\u1edbc khi ti\u1ebfn h\u00e0nh \u0111i\u1ec1n khuy\u1ebft. Tuy nhi\u00ean, \u0111\u1ec3 ph\u1ea3n \u00e1nh \u0111\u00fang \u0111\u1eb7c th\u00f9 d\u1eef li\u1ec7u \u0111\u01b0a v\u00e0o m\u00f4 h\u00ecnh, c\u00e1c con s\u1ed1 b\u00e1o c\u00e1o d\u01b0\u1edbi \u0111\u00e2y l\u00e0 s\u1ed1 l\u01b0\u1ee3ng ngo\u1ea1i l\u1ec7 \u0111\u01b0\u1ee3c th\u1ed1ng k\u00ea l\u1ea1i tr\u00ean t\u1eadp ph\u00e2n t\u00edch ch\u00ednh th\u1ee9c $N = 556$ quan s\u00e1t, sau khi \u0111\u00e3 l\u1ecdc b\u1ecf c\u00e1c d\u00f2ng khuy\u1ebft gi\u00e1 b\u00e1n -- xem chi ti\u1ebft quy tr\u00ecnh t\u1ea1i B\u01b0\u1edbc~4}):",
     "\\textbf{K\u1ebft qu\u1ea3 ph\u00e1t hi\u1ec7n} (ranh gi\u1edbi IQR t\u00ednh tr\u00ean t\u1eadp th\u00f4 $N = 3.406$, s\u1ed1 l\u01b0\u1ee3ng \u0111\u01b0\u1ee3c th\u1ed1ng k\u00ea l\u1ea1i tr\u00ean m\u1eabu $N = 556$):"),

    # 2) Shorten the selection bias paragraph
    ("\\textbf{Nh\u1eadn x\u00e9t v\u1ec1 t\u00ednh \u0111\u1ea1i di\u1ec7n c\u1ee7a m\u1eabu:} Vi\u1ec7c lo\u1ea1i b\u1ecf h\u01a1n 83\\% quan s\u00e1t do thi\u1ebfu gi\u00e1 ph\u00e1t h\u00e0nh c\u00f3 th\u1ec3 d\u1eabn \u0111\u1ebfn nguy c\u01a1 sai l\u1ec7ch ch\u1ecdn m\u1eabu (selection bias). Th\u1ef1c t\u1ebf, c\u00e1c GPU thi\u1ebfu gi\u00e1 kh\u00f4ng ph\u00e2n b\u1ed1 ng\u1eabu nhi\u00ean m\u00e0 th\u01b0\u1eddng t\u1eadp trung \u1edf c\u00e1c d\u00f2ng card c\u0169 ho\u1eb7c card \u0111\u1ed3 h\u1ecda t\u00edch h\u1ee3p (\u0111i\u1ec3n h\u00ecnh l\u00e0 to\u00e0n b\u1ed9 254 quan s\u00e1t c\u1ee7a h\u00e3ng Intel trong d\u1eef li\u1ec7u g\u1ed1c \u0111\u1ec1u r\u01a1i v\u00e0o tr\u01b0\u1eddng h\u1ee3p n\u00e0y v\u00e0 b\u1ecb lo\u1ea1i b\u1ecf ho\u00e0n to\u00e0n). \u0110\u00e2y l\u00e0 h\u1ea1n ch\u1ebf c\u1ed1 h\u1eefu xu\u1ea5t ph\u00e1t t\u1eeb \u0111\u1eb7c \u0111i\u1ec3m c\u1ee7a b\u1ed9 d\u1eef li\u1ec7u g\u1ed1c, gi\u00e1 ph\u00e1t h\u00e0nh kh\u00f4ng \u0111\u01b0\u1ee3c nh\u00e0 s\u1ea3n xu\u1ea5t c\u00f4ng b\u1ed1 ch\u00ednh th\u1ee9c cho to\u00e0n b\u1ed9 s\u1ea3n ph\u1ea9m, d\u1eabn \u0111\u1ebfn t\u1ef7 l\u1ec7 NA cao mang t\u00ednh c\u1ea5u tr\u00fac ch\u1ee9 kh\u00f4ng ph\u1ea3i ng\u1eabu nhi\u00ean (Missing Not At Random --- MNAR). V\u00ec v\u1eady, nh\u00f3m ghi nh\u1eadn \u0111\u00e2y l\u00e0 gi\u1edbi h\u1ea1n c\u1ee7a nghi\u00ean c\u1ee9u; c\u00e1c k\u1ebft lu\u1eadn t\u1eeb m\u00f4 h\u00ecnh mang t\u00ednh ch\u1ea5t kh\u00e1m ph\u00e1 c\u1ea5u tr\u00fac \u0111\u1ecbnh gi\u00e1 c\u1ee7a ph\u00e2n kh\u00fac GPU b\u00e1n l\u1ebb v\u00e0 n\u00ean \u0111\u01b0\u1ee3c di\u1ec5n gi\u1ea3i m\u1ed9t c\u00e1ch th\u1eadn tr\u1ecdng, kh\u00f4ng n\u00ean \u0111\u01b0\u1ee3c ngo\u1ea1i suy m\u1ed9t c\u00e1ch tuy\u1ec7t \u0111\u1ed1i ra to\u00e0n b\u1ed9 th\u1ecb tr\u01b0\u1eddng GPU.",
     "\\textbf{Nh\u1eadn x\u00e9t v\u1ec1 t\u00ednh \u0111\u1ea1i di\u1ec7n:} Vi\u1ec7c lo\u1ea1i b\u1ecf 83\\% quan s\u00e1t thi\u1ebfu gi\u00e1 c\u00f3 th\u1ec3 g\u00e2y sai l\u1ec7ch ch\u1ecdn m\u1eabu (selection bias). T\u1ef7 l\u1ec7 NA cao mang t\u00ednh c\u1ea5u tr\u00fac (MNAR) do gi\u00e1 kh\u00f4ng \u0111\u01b0\u1ee3c c\u00f4ng b\u1ed1 cho to\u00e0n b\u1ed9 s\u1ea3n ph\u1ea9m (to\u00e0n b\u1ed9 254 GPU Intel b\u1ecb lo\u1ea1i). K\u1ebft lu\u1eadn t\u1eeb m\u00f4 h\u00ecnh mang t\u00ednh kh\u00e1m ph\u00e1, c\u1ea7n di\u1ec5n gi\u1ea3i th\u1eadn tr\u1ecdng."),

    # 3) Merge Bước 5 and Bước 6 in theory section
    ("\\subsubsection{B\u01b0\u1edbc 5: M\u00e3 h\u00f3a bi\u1ebfn ph\u00e2n lo\u1ea1i (Encoding)}\n\n\\textbf{K\u1ef9 thu\u1eadt s\u1eed d\u1ee5ng:} Chuy\u1ec3n c\u00e1c bi\u1ebfn ph\u00e2n lo\u1ea1i \\texttt{manufacturer} v\u00e0 \\texttt{memory\\_type} th\u00e0nh \\texttt{factor} trong R b\u1eb1ng \\texttt{as.factor()}. Khi \u0111\u01b0a v\u00e0o h\u00e0m \\texttt{lm()} (h\u1ed3i quy tuy\u1ebfn t\u00ednh), R t\u1ef1 \u0111\u1ed9ng t\u1ea1o bi\u1ebfn gi\u1ea3 (dummy variables) v\u1edbi m\u1ed9t nh\u00f3m l\u00e0m c\u01a1 s\u1edf (reference level).\n\n\\textbf{L\u00fd do:} C\u00e1c thu\u1eadt to\u00e1n h\u1ed3i quy tuy\u1ebfn t\u00ednh ch\u1ec9 nh\u1eadn \u0111\u1ea7u v\u00e0o l\u00e0 s\u1ed1. Bi\u1ebfn ph\u00e2n lo\u1ea1i nh\u01b0 ``NVIDIA'', ``AMD'' kh\u00f4ng th\u1ec3 \u0111\u01b0a tr\u1ef1c ti\u1ebfp v\u00e0o ph\u01b0\u01a1ng tr\u00ecnh, m\u00e0 ph\u1ea3i \u0111\u01b0\u1ee3c m\u00e3 h\u00f3a th\u00e0nh c\u00e1c c\u1ed9t 0/1. R x\u1eed l\u00fd t\u1ef1 \u0111\u1ed9ng vi\u1ec7c n\u00e0y khi bi\u1ebfn \u0111\u00e3 \u0111\u01b0\u1ee3c khai b\u00e1o l\u00e0 factor, gi\u00fap \u0111\u01a1n gi\u1ea3n h\u00f3a code v\u00e0 tr\u00e1nh l\u1ed7i.",
     "\\subsubsection{B\u01b0\u1edbc 5 \\& 6: M\u00e3 h\u00f3a bi\u1ebfn ph\u00e2n lo\u1ea1i v\u00e0 Chu\u1ea9n h\u00f3a d\u1eef li\u1ec7u}\n\n\\textbf{M\u00e3 h\u00f3a:} Chuy\u1ec3n \\texttt{manufacturer} v\u00e0 \\texttt{memory\\_type} th\u00e0nh \\texttt{factor} b\u1eb1ng \\texttt{as.factor()}. R t\u1ef1 \u0111\u1ed9ng t\u1ea1o bi\u1ebfn gi\u1ea3 (dummy variables) khi \u0111\u01b0a v\u00e0o \\texttt{lm()}."),
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

# Remove the separate Bước 6 subsubsection header since we merged
old_b6 = "\\subsubsection{B\u01b0\u1edbc 6: Chu\u1ea9n h\u00f3a d\u1eef li\u1ec7u (Normalization / Standardization)}\n\n\\textbf{K\u1ef9 thu\u1eadt s\u1eed d\u1ee5ng:} Chu\u1ea9n h\u00f3a"
new_b6 = "\n\\textbf{Chu\u1ea9n h\u00f3a:} Chu\u1ea9n h\u00f3a"
for nl_to, label in [('\n', 'LF'), ('\r\n', 'CRLF')]:
    test_old = old_b6.replace('\n', nl_to)
    if test_old in content:
        content = content.replace(test_old, new_b6.replace('\n', nl_to))
        print(f"Merged Buoc 6 header ({label})")
        break
else:
    print("Buoc 6 header NOT FOUND")

with open('src/main.tex', 'w', encoding='utf-8') as f:
    f.write(content)
