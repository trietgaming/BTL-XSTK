with open('src/main.tex', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace longtable with compact regular table
old = r"""\renewcommand{\arraystretch}{1.3}
\begin{longtable}{|p{2.5cm}|p{3cm}|p{6cm}|p{3.5cm}|}
\caption{Danh sách biến sử dụng trong mô hình và vai trò tương ứng}
\label{tab:bien} \\
\hline
\textbf{Biến} & \textbf{Kiểu thực tế} & \textbf{Lý do / Giải thích} & \textbf{Vai trò trong mô hình} \\
\hline
\endfirsthead
\multicolumn{4}{c}{\tablename~\thetable{} (tiếp theo)} \\
\hline
\textbf{Biến} & \textbf{Kiểu thực tế} & \textbf{Lý do / Giải thích} & \textbf{Vai trò trong mô hình} \\
\hline
\endhead
\hline
\endfoot
\texttt{manufacturer} & Định danh (Nominal)
  & Phân nhóm hãng sản xuất (NVIDIA, AMD, Intel)
  & Biến độc lập (phân loại) \\
\hline
\texttt{memory\_type} & Định danh (Nominal)
  & Các chuẩn VRAM (GDDR5, GDDR3, DDR3, HBM\ldots{} và các chuẩn khác) -- số lượng giá trị phân biệt có giới hạn.
  & Biến độc lập (phân loại), đã được xem xét và loại bỏ do VIF = 8.12; xem Phần~4, mục 7.1.2 \\
\hline
\texttt{memory\_bus} & Rời rạc (Discrete)
  & Băng thông bộ nhớ (bit) -- giá trị rời rạc tuân theo các chuẩn kỹ thuật của ngành.
  & Biến độc lập (số) \\
\hline
\texttt{memory\_size} & Rời rạc (Discrete)
  & Dung lượng VRAM (GB hoặc MB) -- giá trị rời rạc phân bố theo thiết kế của nhà sản xuất.
  & Biến độc lập (số) \\
\hline
\texttt{tdp} & Liên tục (Continuous)
  & Công suất tiêu thụ điện (Watt) -- ảnh hưởng trực tiếp đến chi phí sản xuất
  & Biến độc lập (số) \\
\hline
\texttt{core\_speed} & Liên tục (Continuous)
  & Tốc độ xung nhịp lõi (MHz) -- phản ánh hiệu năng xử lý
  & Biến độc lập (số) \\
\hline
\texttt{release\_year} & Rời rạc $\to$ Số
  & Ngày phát hành được parse thành năm (integer) để nắm xu hướng thời gian
  & Biến độc lập (số) \\
\hline
\texttt{release\_price} & Liên tục (Continuous)
  & Giá phát hành (USD) -- biến mục tiêu cần giải thích
  & Biến phụ thuộc $Y$ \\
\hline
\end{longtable}

\textbf{\textit{Lưu ý đặc biệt:}}

Biến \texttt{memory\_bus} tuy mang giá trị số nhưng thực chất là biến rời rạc vì chỉ tồn tại một số lượng giá trị cố định theo chuẩn kỹ thuật của ngành. Trong mô hình hồi quy, biến này được giữ nguyên dạng số vì thứ tự và khoảng cách giữa các giá trị có ý nghĩa vật lý thực sự (băng thông tăng gấp đôi phản ánh hiệu năng tăng tương ứng). Do đó, biến này được duy trì ở định dạng số trong suốt quá trình chạy mô hình.

Về biến \texttt{manufacturer}: Trong dữ liệu gốc, hãng ATI (đã bị AMD sáp nhập) xuất hiện ở một số quan sát. Để đảm bảo tính nhất quán về thị phần hiện tại, nhóm đã tiến hành gộp toàn bộ giá trị ``ATI'' vào nhóm ``AMD'' trong quá trình làm sạch dữ liệu."""

new = r"""{\small
\renewcommand{\arraystretch}{1.1}
\begin{table}[H]
\centering
\caption{Danh sách biến sử dụng trong mô hình và vai trò tương ứng}
\label{tab:bien}
\begin{tabular}{|l|l|p{5.5cm}|l|}
\toprule
\textbf{Biến} & \textbf{Kiểu} & \textbf{Mô tả} & \textbf{Vai trò} \\
\midrule
\texttt{manufacturer} & Nominal & Hãng sản xuất (NVIDIA, AMD) & Độc lập (phân loại) \\
\texttt{memory\_type} & Nominal & Chuẩn VRAM (GDDR5, GDDR3, DDR3, HBM\ldots) & Loại bỏ (VIF $= 8.12$) \\
\texttt{memory\_bus} & Rời rạc & Băng thông bộ nhớ (bit) --- giá trị theo chuẩn kỹ thuật & Độc lập (số) \\
\texttt{memory\_size} & Rời rạc & Dung lượng VRAM (GB/MB) & Độc lập (số) \\
\texttt{tdp} & Liên tục & Công suất tiêu thụ (Watt) --- chi phí sản xuất & Độc lập (số) \\
\texttt{core\_speed} & Liên tục & Tốc độ xung nhịp lõi (MHz) & Độc lập (số) \\
\texttt{release\_year} & Số nguyên & Năm phát hành (parse từ Release\_Date) & Độc lập (số) \\
\texttt{release\_price} & Liên tục & Giá phát hành (USD) --- biến mục tiêu & Phụ thuộc $Y$ \\
\bottomrule
\end{tabular}
\end{table}
}

\textbf{\textit{Lưu ý:}} \texttt{memory\_bus} tuy mang giá trị số nhưng thực chất là biến rời rạc (giá trị cố định theo chuẩn kỹ thuật), được giữ dạng số vì khoảng cách giữa các giá trị có ý nghĩa vật lý. Hãng ATI (đã bị AMD sáp nhập) được gộp vào ``AMD'' trong quá trình làm sạch."""

for nl_to, label in [('\n', 'LF'), ('\r\n', 'CRLF')]:
    test_old = old.replace('\n', nl_to)
    if test_old in content:
        content = content.replace(test_old, new.replace('\n', nl_to))
        print(f"Replaced longtable ({label})")
        break
else:
    print("NOT FOUND")

with open('src/main.tex', 'w', encoding='utf-8') as f:
    f.write(content)
