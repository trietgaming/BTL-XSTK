import sys
sys.stdout.reconfigure(encoding='utf-8')

with open('src/main.tex', 'r', encoding='utf-8') as f:
    content = f.read()

old = """\\subsection{Ý nghĩa thực tiễn}

\\textbf{Mô hình Log-Linear đưa ra những ứng dụng thực tiễn quan trọng:}

\\textbf{(1) Công cụ định giá cho người mua:} Với phương trình $\\log(\\hat{Y}) = 84.45 + 0.455 \\cdot \\text{TDP} + \\ldots$, người tiêu dùng có thể ước lượng giá hợp lý của một GPU dựa trên thông số kỹ thuật của nó. Nếu giá thực tế cao hơn đáng kể so với giá mô hình dự đoán, đó là dấu hiệu GPU đang bị định giá cao (overpriced) và người mua nên cân nhắc thay thế.

\\textbf{(2) Định lượng ``phí thương hiệu'' NVIDIA:} Kết quả cho thấy với \\textit{cùng thông số kỹ thuật}, GPU NVIDIA đắt hơn AMD khoảng \\textbf{45.2\\%}. Đây là con số cụ thể giúp người mua GPU đánh giá liệu mức giá premium của NVIDIA có xứng đáng với nhu cầu của mình không, đặc biệt trong bối cảnh cả hai hãng đều có GPU trên cùng một phân khúc hiệu năng.

\\textbf{(3) Hỗ trợ hoạch định ngân sách doanh nghiệp:} Đối với các doanh nghiệp mua số lượng lớn GPU cho các hệ thống AI hoặc render farm, mô hình cung cấp cơ sở khoa học để so sánh giá trị thực tế của từng sản phẩm trong danh mục, tránh bị tác động bởi marketing và tập trung vào hiệu năng-trên-đô-la.

\\textbf{(4) Tín hiệu cho nhà sản xuất:} Hệ số âm của \\texttt{release\\_year} ($\\beta = -0.039$) cho thấy GPU ra mắt sau rẻ hơn $\\approx 3.8\\%$ mỗi năm --- phản ánh xu hướng giảm giá theo thời gian của công nghệ phần cứng (Moore's Law). Đây là thông tin hữu ích cho chiến lược định giá và thời điểm ra mắt sản phẩm.

Tóm lại, nghiên cứu đã thành công trong việc xây dựng một mô hình thống kê có cơ sở khoa học vững chắc và có giá trị ứng dụng thực tiễn cho cả người tiêu dùng lẫn nhà sản xuất GPU trên thị trường."""

new = """\\subsection{Ý nghĩa thực tiễn}

\\begin{enumerate}
  \\item \\textbf{Công cụ định giá:} Phương trình Log-Linear cho phép ước lượng giá hợp lý dựa trên thông số kỹ thuật --- nếu giá thực vượt xa giá mô hình, GPU có thể đang bị overpriced.
  \\item \\textbf{Định lượng ``phí thương hiệu'':} NVIDIA đắt hơn AMD $\\approx 45.2\\%$ cùng thông số --- cơ sở để người mua đánh giá mức premium.
  \\item \\textbf{Ngân sách doanh nghiệp:} Mô hình giúp so sánh giá trị thực giữa các GPU cho hệ thống AI/render farm.
  \\item \\textbf{Tín hiệu thị trường:} GPU ra sau rẻ hơn $\\approx 3.8\\%$/năm ($\\beta_{year} = -0.039$), phản ánh xu hướng Moore's Law.
\\end{enumerate}"""

for nl_to, label in [('\n', 'LF'), ('\r\n', 'CRLF')]:
    test_old = old.replace('\n', nl_to)
    if test_old in content:
        content = content.replace(test_old, new.replace('\n', nl_to))
        print(f"Replaced practical significance ({label})")
        break
else:
    print("NOT FOUND")

with open('src/main.tex', 'w', encoding='utf-8') as f:
    f.write(content)
