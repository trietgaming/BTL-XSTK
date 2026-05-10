import re

with open('src/main.tex', 'r', encoding='utf-8') as f:
    content = f.read()

old = r"""\subsubsection{7.2. Phân tích phương sai}


\begin{lstlisting}[language=R]
print(leveneTest(release_price ~ manufacturer, data = df_final))
\end{lstlisting}

Kiểm tra xem độ phân tán (biến thiên) của giá GPU thuộc hãng NVIDIA có bằng với độ phân tán của giá GPU hãng AMD hay không.

\begin{lstlisting}[style=console]
> print(leveneTest(release_price ~ manufacturer, data = df_final))
Levene's Test for Homogeneity of Variance (center = median)
       Df F value      Pr(>F)    
group   1  11.168 0.0008884 ***
      554                        
\end{lstlisting}

\begin{lstlisting}[language=R]
anova_result <- oneway.test(release_price ~ manufacturer, data = df_final, var.equal = FALSE)
print(anova_result)
\end{lstlisting}

\textbf{oneway.test(...)}: Hàm thực hiện phân tích phương sai một yếu tố.

\textbf{var.equal = FALSE}: Đây là tham số quan trọng nhất. Nó ra lệnh cho R thực hiện hiệu chỉnh Welch nhằm xử lý tình trạng phương sai không đồng nhất đã phát hiện ở bước trên.

Kết quả chạy trên console: 
\begin{lstlisting}[style=console]
> print(anova_result)

	One-way analysis of means (not assuming equal variances)

data:  release_price and manufacturer
F = 18.39, num df = 1.00, denom df = 309.05, p-value = 2.409e-05
\end{lstlisting}"""

new = r"""\subsubsection{7.2. Phân tích phương sai}

\begin{lstlisting}[language=R]
# Kiem dinh dong nhat phuong sai
print(leveneTest(release_price ~ manufacturer, data = df_final))

# Welch's ANOVA (var.equal = FALSE de xu ly phuong sai khong dong nhat)
anova_result <- oneway.test(release_price ~ manufacturer,
                            data = df_final, var.equal = FALSE)
print(anova_result)
\end{lstlisting}

\textbf{Levene's Test} kiểm tra tính đồng nhất phương sai giữa hai nhóm. \textbf{oneway.test(..., var.equal = FALSE)} thực hiện Welch's ANOVA --- phiên bản bền vững khi phương sai không đồng nhất. Kết quả chi tiết được trình bày tại Phần~4."""

if old in content:
    content = content.replace(old, new)
    print("FOUND and replaced (LF)")
elif old.replace('\n', '\r\n') in content:
    content = content.replace(old.replace('\n', '\r\n'), new.replace('\n', '\r\n'))
    print("FOUND and replaced (CRLF)")
else:
    print("NOT FOUND - trying fuzzy")
    # Try to find the section
    idx = content.find(r'\subsubsection{7.2. Phân tích phương sai}')
    if idx >= 0:
        end_marker = r'%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%' + '\r\n' + r'\section{Kết quả Thu được}'
        end_idx = content.find(end_marker, idx)
        if end_idx < 0:
            end_marker = '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\\section{Kết quả Thu được}'
            end_idx = content.find(end_marker, idx)
        if end_idx >= 0:
            nl = '\r\n' if '\r\n' in content[idx:idx+100] else '\n'
            replacement = new.replace('\n', nl)
            content = content[:idx] + replacement + nl + nl + nl + content[end_idx:]
            print(f"REPLACED via fuzzy match (idx={idx}, end={end_idx})")
        else:
            print(f"Found section start at {idx} but no end marker")
    else:
        print("Section not found at all")

with open('src/main.tex', 'w', encoding='utf-8') as f:
    f.write(content)
