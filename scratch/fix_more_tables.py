import sys
sys.stdout.reconfigure(encoding='utf-8')

with open('src/main.tex', 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    # 1) Compact Buoc 4 NA table to inline text
    ("""\\subsection{B\u01b0\u1edbc 4 --- X\u1eed l\u00fd gi\u00e1 tr\u1ecb khuy\u1ebft}

\\begin{table}[H]
\\centering
\\caption{T\u00ecnh tr\u1ea1ng NA sau khi l\u1ecdc bi\u1ebfn ph\u1ee5 thu\u1ed9c}
\\begin{tabular}{|l|r|l|r|}
\\hline
\\textbf{Bi\u1ebfn} & \\textbf{NA sau l\u1ecdc Y} & \\textbf{Ph\u01b0\u01a1ng ph\u00e1p} & \\textbf{NA sau x\u1eed l\u00fd} \\\\
\\hline
release\\_price (Y) & 0 & X\u00f3a d\u00f2ng (2.850 d\u00f2ng b\u1ecb lo\u1ea1i) & 0 \\\\
tdp & 2 & \u0110i\u1ec1n b\u1eb1ng Median & 0 \\\\
memory\\_size & 8 & \u0110i\u1ec1n b\u1eb1ng Median & 0 \\\\
memory\\_bus & 5 & \u0110i\u1ec1n b\u1eb1ng Median & 0 \\\\
core\\_speed & 79 & \u0110i\u1ec1n b\u1eb1ng Median & 0 \\\\
release\\_year & 8 & \u0110i\u1ec1n b\u1eb1ng Median & 0 \\\\
memory\\_type & 0 & --- & 0 \\\\
manufacturer & 0 & --- & 0 \\\\
\\hline
\\end{tabular}
\\end{table}

\\textbf{Nh\u1eadn x\u00e9t:} Sau khi l\u1ecdc c\u00e1c d\u00f2ng thi\u1ebfu bi\u1ebfn ph\u1ee5 thu\u1ed9c \\texttt{release\\_price}, t\u1eadp d\u1eef li\u1ec7u c\u00f2n l\u1ea1i \\textbf{556 quan s\u00e1t} c\u00f3 gi\u00e1 \u0111\u1ea7y \u0111\u1ee7. \u0110\u00e2y l\u00e0 m\u1eabu ph\u00e2n t\u00edch ch\u00ednh th\u1ee9c.""",

     """\\subsection{B\u01b0\u1edbc 4 --- X\u1eed l\u00fd gi\u00e1 tr\u1ecb khuy\u1ebft}

Sau khi x\u00f3a 2.850 d\u00f2ng thi\u1ebfu \\texttt{release\\_price} (bi\u1ebfn Y), t\u1eadp ph\u00e2n t\u00edch c\u00f2n \\textbf{556 quan s\u00e1t}. C\u00e1c bi\u1ebfn s\u1ed1 c\u00f2n NA \u0111\u01b0\u1ee3c \u0111i\u1ec1n Median (\\texttt{core\\_speed}: 79 NA, \\texttt{memory\\_size}: 8, \\texttt{release\\_year}: 8, \\texttt{memory\\_bus}: 5, \\texttt{tdp}: 2). Hai bi\u1ebfn ph\u00e2n lo\u1ea1i kh\u00f4ng c\u00f3 NA. K\u1ebft qu\u1ea3: 0\\% NA tr\u00ean to\u00e0n b\u1ed9 8 bi\u1ebfn."""),
]

for i, (old, new) in enumerate(replacements):
    for nl_to, label in [('\n', 'LF'), ('\r\n', 'CRLF')]:
        test_old = old.replace('\n', nl_to)
        if test_old in content:
            content = content.replace(test_old, new.replace('\n', nl_to))
            print(f"Replaced #{i+1} ({label})")
            break
    else:
        print(f"NOT FOUND #{i+1}")

# Also compact the thong ke mo ta table  
old2 = "\\subsection{Th\u1ed1ng k\u00ea m\u00f4 t\u1ea3 bi\u1ebfn ph\u1ee5 thu\u1ed9c release\\_price}"
idx = content.find(old2)
if idx >= 0:
    # Find the end of this subsection (next \subsection)
    next_sub = content.find("\\subsection{", idx + len(old2))
    if next_sub >= 0:
        section_content = content[idx:next_sub]
        nl = '\n'
        if '\r\n' in section_content:
            nl = '\r\n'
        new_section = f"""\\subsection{{Th\u1ed1ng k\u00ea m\u00f4 t\u1ea3 bi\u1ebfn ph\u1ee5 thu\u1ed9c release\\_price}}{nl}{nl}Tr\u00ean m\u1eabu $n = 556$: Min $= \\$23$, Q1 $= \\$159.75$, Median $= \\$240$, Mean $= \\$371.56$, Q3 $= \\$421.50$, Max $= \\$14.999$, SD $= \\$698.26$, Skewness $= 16.84$. Ph\u00e2n ph\u1ed1i l\u1ec7ch ph\u1ea3i r\u1ea5t m\u1ea1nh --- kho\u1ea3ng c\u00e1ch gi\u1eefa Mean v\u00e0 Median cho th\u1ea5y GPU flagship (TITAN, Quadro) k\u00e9o trung b\u00ecnh l\u00ean \u0111\u00e1ng k\u1ec3, d\u1eabn \u0111\u1ebfn quy\u1ebft \u0111\u1ecbnh log-transform bi\u1ebfn Y tr\u01b0\u1edbc khi ch\u1ea1y m\u00f4 h\u00ecnh.{nl}{nl}"""
        content = content[:idx] + new_section + content[next_sub:]
        print("Replaced thong ke mo ta section")
    else:
        print("Could not find next subsection")
else:
    print("thong ke mo ta not found")

with open('src/main.tex', 'w', encoding='utf-8') as f:
    f.write(content)
