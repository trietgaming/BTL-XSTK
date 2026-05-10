import sys
sys.stdout.reconfigure(encoding='utf-8')

with open('src/main.tex', 'r', encoding='utf-8') as f:
    content = f.read()

# Consolidate the 4 limitations into a compact list
old = """\\subsection{Hạn chế và đề xuất cải tiến}

Mặc dù mô hình Log-Linear đạt được kết quả khả quan, vẫn còn một số hạn chế cần được cải tiến trong các nghiên cứu tiếp theo:

\\textbf{Hạn chế 1 --- Phương sai sai số chưa hoàn toàn đồng đều:} Kiểm định Breusch-Pagan trên mô hình Log-Linear vẫn cho p-value rất nhỏ ($BP = 99.04$, $p < 2.2 \\times 10^{-16}$), cho thấy hiện tượng phương sai thay đổi (heteroscedasticity) chưa được khắc phục triệt để.
\\begin{itemize}
    \\item \\textbf{Đề xuất:} Sử dụng \\textbf{Weighted Least Squares (WLS)} với trọng số là nghịch đảo của phương sai ước lượng, hoặc tính toán \\textbf{Robust Standard Errors} (hàm \\texttt{coeftest()} với \\texttt{vcovHC()} trong R) để đảm bảo suy diễn thống kê vẫn chính xác dù phương sai thay đổi.
\\end{itemize}

\\textbf{Hạn chế 2 --- Phần dư chưa hoàn toàn phân phối chuẩn:} Mặc dù $W$-statistic cải thiện từ 0.239 (OLS) lên 0.948 (Log-Linear), phần dư vẫn vi phạm nhẹ giả định chuẩn (Shapiro-Wilk p $= 4.056 \\times 10^{-13}$).
\\begin{itemize}
    \\item \\textbf{Đề xuất:} Thử nghiệm thêm \\textbf{biến đổi Box-Cox} để tìm tham số $\\lambda$ tối ưu thay vì cố định $\\lambda = 0$ (log transform). Ngoài ra, với cỡ mẫu $n = 556$, định lý Giới hạn Trung tâm đảm bảo các suy diễn về hệ số hồi quy vẫn hợp lệ.
\\end{itemize}

\\textbf{Hạn chế 3 --- Selection bias do loại bỏ 83.7\\% quan sát thiếu giá:} Tập 556 quan sát chỉ bao gồm các GPU có công bố giá chính thức, có thể thiên về các dòng phổ thông hoặc flagship, bỏ qua phân khúc tầm trung ít được công bố giá.
\\begin{itemize}
    \\item \\textbf{Đề xuất:} Thu thập thêm dữ liệu giá từ các nguồn khác (Amazon, Newegg, Ebay) để bổ sung các quan sát thiếu giá, hoặc áp dụng phương pháp \\textbf{Multiple Imputation} cho biến phụ thuộc.
\\end{itemize}

\\textbf{Hạn chế 4 --- Không xét tương tác giữa biến:} Mô hình hiện tại giả định các biến tác động độc lập lên giá. Trên thực tế, tác động của TDP lên giá có thể phụ thuộc vào hãng sản xuất (ví dụ: cùng TDP nhưng NVIDIA định giá khác AMD).
\\begin{itemize}
    \\item \\textbf{Đề xuất:} Thêm các \\textbf{số hạng tương tác} (interaction terms) như \\texttt{tdp:manufacturer} vào mô hình và sử dụng Ramsey RESET test để kiểm tra sai dạng hàm.
\\end{itemize}"""

new = """\\subsection{Hạn chế và đề xuất cải tiến}

\\begin{enumerate}
  \\item \\textbf{Phương sai sai số chưa đồng đều} ($BP = 99.04$, $p < 2.2 \\times 10^{-16}$). \\textit{Đề xuất:} WLS hoặc Robust SE (\\texttt{vcovHC()}).
  \\item \\textbf{Phần dư chưa hoàn toàn chuẩn} ($W = 0.948$, $p = 4.056 \\times 10^{-13}$). \\textit{Đề xuất:} Biến đổi Box-Cox; CLT với $n = 556$ vẫn đảm bảo suy diễn hợp lệ.
  \\item \\textbf{Selection bias} do loại 83.7\\% quan sát thiếu giá (MNAR). \\textit{Đề xuất:} Bổ sung dữ liệu từ Amazon/Newegg hoặc Multiple Imputation.
  \\item \\textbf{Không xét tương tác biến.} \\textit{Đề xuất:} Thêm interaction terms (\\texttt{tdp:manufacturer}) và Ramsey RESET test.
\\end{enumerate}"""

for nl_to, label in [('\n', 'LF'), ('\r\n', 'CRLF')]:
    test_old = old.replace('\n', nl_to)
    if test_old in content:
        content = content.replace(test_old, new.replace('\n', nl_to))
        print(f"Replaced limitations ({label})")
        break
else:
    print("NOT FOUND")

with open('src/main.tex', 'w', encoding='utf-8') as f:
    f.write(content)
