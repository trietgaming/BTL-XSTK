import sys
sys.stdout.reconfigure(encoding='utf-8')

with open('src/main.tex', 'r', encoding='utf-8') as f:
    content = f.read()

old = """\\textbf{Câu hỏi 1 --- Thông số kỹ thuật nào ảnh hưởng đến giá GPU?} Mô hình Log-Linear cuối cùng với $R^2 = 78.54\\%$ đã xác nhận rằng toàn bộ 6 thông số được chọn (TDP, dung lượng bộ nhớ, băng thông bộ nhớ, xung nhịp lõi, hãng sản xuất và năm phát hành) đều có tác động có ý nghĩa thống kê lên giá phát hành GPU (tất cả p-value $< 0.001$). Trong đó, \\textbf{TDP (công suất tiêu thụ)} là yếu tố có ảnh hưởng mạnh nhất --- tăng 1 độ lệch chuẩn TDP khiến giá tăng $\\approx 57.5\\%$, phản ánh đúng quy luật kinh tế học phần cứng: GPU có hiệu năng cao tiêu thụ điện nhiều hơn và đắt hơn. Kết quả này vượt kỳ vọng ban đầu khi tất cả biến, kể cả \\texttt{memory\\_bus} vốn không có ý nghĩa trong mô hình OLS, đều trở nên có ý nghĩa sau khi biến đổi logarit.

\\textbf{Câu hỏi 2 --- Có sự chênh lệch giá đáng kể giữa NVIDIA và AMD?} Welch's ANOVA xác nhận có sự khác biệt có ý nghĩa thống kê về giá trung bình giữa hai hãng ($F = 18.39$, $p = 2.409 \\times 10^{-5}$). Vì chỉ có 2 nhóm, Welch's ANOVA tương đương Welch's T-test nên không cần kiểm định hậu kiểm; mức chênh lệch giá trung bình giữa NVIDIA (\\$491.73) và AMD (\\$246.30) là khoảng \\textbf{\\$245.43}. Đồng thời, mô hình hồi quy cho thấy với cùng thông số kỹ thuật, GPU NVIDIA đắt hơn AMD khoảng \\textbf{45.2\\%} --- đây là phát hiện quan trọng vì nó kiểm soát cả yếu tố cấu hình, tức là sự chênh lệch giá không hoàn toàn do NVIDIA có cấu hình mạnh hơn mà còn do chiến lược định giá của hãng."""

new = """\\textbf{Câu hỏi 1 --- Thông số kỹ thuật nào ảnh hưởng đến giá GPU?} Mô hình Log-Linear ($R^2 = 78.54\\%$) xác nhận cả 6 thông số đều có ý nghĩa ($p < 0.001$). TDP ảnh hưởng mạnh nhất ($+57.5\\%$/SD), tiếp theo là dung lượng RAM, xung nhịp, bus width. Đặc biệt, \\texttt{memory\\_bus} trở nên có ý nghĩa sau biến đổi log (vốn không có ý nghĩa trong OLS).

\\textbf{Câu hỏi 2 --- Chênh lệch giá NVIDIA vs AMD?} Welch's ANOVA ($F = 18.39$, $p = 2.409 \\times 10^{-5}$): chênh lệch trung bình \\textbf{\\$245.43}. Mô hình hồi quy cho thấy cùng thông số, NVIDIA đắt hơn AMD \\textbf{45.2\\%} --- sự chênh lệch do chiến lược định giá chứ không chỉ do cấu hình."""

for nl_to, label in [('\n', 'LF'), ('\r\n', 'CRLF')]:
    test_old = old.replace('\n', nl_to)
    if test_old in content:
        content = content.replace(test_old, new.replace('\n', nl_to))
        print(f"Replaced conclusion ({label})")
        break
else:
    print("NOT FOUND")

with open('src/main.tex', 'w', encoding='utf-8') as f:
    f.write(content)
