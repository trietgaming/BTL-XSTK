# Quy tắc viết báo cáo LaTeX (BTL Xác Suất Thống Kê - HCMUT)

## Cấu trúc dự án
- Báo cáo LaTeX: `src/main.tex`
- Code phân tích: `src/main.R`
- Hình ảnh/biểu đồ: `src/figures/`
- Dữ liệu: `src/All_GPUs.csv`

---

## Quy tắc bắt buộc

### 1. Đồng bộ R ↔ LaTeX
Khi cập nhật code R (`src/main.R`):
- Rà soát toàn bộ `main.tex` để tìm các đoạn đề cập đến kết quả, số liệu, hay phân tích đó.
- Cập nhật ngay tất cả nơi có đề cập: số liệu thống kê, bảng kết quả, nhận xét, kết luận.
- Không để báo cáo mô tả code cũ hoặc kết quả cũ khi code đã thay đổi.

### 2. Biểu đồ / Đồ thị
Mỗi khi vẽ biểu đồ trong R:
1. Xuất ảnh ra `src/figures/<tên_mô_tả>.png` (hoặc `.pdf`) với độ phân giải cao (`dpi = 300`, kích thước phù hợp).
2. Chèn ảnh vào `main.tex` bằng `\includegraphics` với caption mô tả rõ ràng và label để cross-reference.
3. Đặt figure ở vị trí logic gần với phân tích đang mô tả, dùng `[H]` hoặc `[htbp]`.
4. Mọi biểu đồ phải có caption đầy đủ: nêu rõ nội dung, đơn vị (nếu có), và nguồn dữ liệu.

### 3. Nhất quán toàn báo cáo
Khi thay đổi bất kỳ phần nào:
- Kiểm tra tất cả các phần **phụ thuộc hoặc tham chiếu** đến phần đó.
- Ví dụ: cập nhật phần 2 (mô tả dữ liệu) → kiểm tra phần 3 (phân tích), phần 4 (kết quả hồi quy), phần 5 (kết luận) có dùng lại con số/nhận xét không.
- Đảm bảo báo cáo **liền mạch và không mâu thuẫn** từ đầu đến cuối.
- Cập nhật cross-reference (`\ref{}`, `\eqref{}`) nếu nhãn thay đổi.

### 4. Ưu tiên trình bày
Thứ tự ưu tiên khi viết/sửa báo cáo:
1. **Visualization** — Biểu đồ rõ ràng, màu sắc phù hợp, legend dễ đọc, không rối mắt.
2. **Rành mạch & Logic** — Mỗi đoạn có lý do tồn tại, dẫn dắt tự nhiên sang phần kế.
3. **Dễ hiểu** — Giải thích thuật ngữ thống kê khi xuất hiện lần đầu, không giả định người đọc biết trước.

### 5. Bố cục cố định — KHÔNG ĐƯỢC THAY ĐỔI
Các `\section{}` cấp cao nhất là quy định của giảng viên, **tuyệt đối không sửa tên, thứ tự, hay xóa**.
- Chỉ được thêm/sửa nội dung bên trong (`\subsection`, `\subsubsection`, văn bản, bảng, hình).
- Nếu cần thêm nội dung không vừa với section hiện tại, trao đổi với người dùng trước.

### 6. Giới hạn số trang
- Tối đa **30 trang nội dung** (không tính trang bìa).
- Khi thêm nội dung mới, ước tính số trang hiện tại. Nếu gần đủ 30 trang, hỏi người dùng trước khi thêm.
- Ưu tiên biểu đồ súc tích thay vì nhiều bảng dài; dùng `longtable` chỉ khi thực sự cần.

### 7. Chất lượng thống kê học thuật
Mỗi kiểm định thống kê trong báo cáo phải trình bày đủ 4 thành phần:
> **Tên kiểm định** → **giá trị thống kê** (F, t, W, χ²...) → **p-value** → **Kết luận tại α = 0.05**

Không được chỉ viết "có ý nghĩa thống kê" mà thiếu con số.

- **Diễn giải hệ số hồi quy theo ngữ cảnh thực tế** (GPU market), không chỉ nói "hệ số dương/âm có ý nghĩa". Ví dụ: "Mỗi đơn vị tăng của TDP (đã chuẩn hóa) tương ứng với mức tăng X% trong giá GPU."
- **Kiểm tra và ghi nhận giả định trước khi dùng kiểm định**: VD kiểm tra đồng nhất phương sai (Levene's) trước ANOVA, kiểm tra đa cộng tuyến (VIF) trước hồi quy.
- Mô hình hồi quy phải kèm **biểu đồ chẩn đoán phần dư**: Residuals vs Fitted, Q-Q plot của phần dư.

### 8. Chất lượng visualization
- **Bảng màu nhất quán** toàn báo cáo: chọn 1 palette (ví dụ `RColorBrewer` "Set2" hoặc `viridis`) và dùng xuyên suốt, không trộn màu tuỳ hứng.
- **Font chữ trong plot đủ lớn để đọc khi in** — dùng `base_size = 12` trong ggplot2 hoặc `cex.lab = 1.2` trong base R.
- Mỗi hình phải có **đoạn nhận xét trực tiếp trong văn bản ngay sau** — không để hình "tự nói chuyện". Câu nhận xét phải chỉ ra insight cụ thể, không chỉ mô tả lại những gì đã thấy. Nhận xét không nằm trong label mà ở đoạn văn bên dưới

### 9. Viết học thuật
- Mỗi `\subsection` nên:
  - Mở đầu bằng **1 câu giới thiệu mục tiêu** của mục đó.
  - Kết thúc bằng **1 câu tóm tắt phát hiện chính** hoặc câu chuyển tiếp sang mục kế.
- **Ký hiệu toán học nhất quán với phần lý thuyết** — nếu phần 2 dùng β₀, β₁, ε thì phần 3 và 4 phải dùng đúng ký hiệu đó, không tự ý đổi.

### 10. Kỹ thuật LaTeX
- Dùng `\FloatBarrier` (package `placeins`) **trước mỗi `\section` lớn** để hình/bảng không trôi sang section khác.
- **Bảng kết quả dùng `booktabs`**: `\toprule`, `\midrule`, `\bottomrule`. Không dùng `\hline` thuần cho bảng kết quả thống kê.
- **Code listing trong báo cáo phải là bản sạch**: loại bỏ các dòng debug, `cat()` tạm, comment dư thừa. Chỉ giữ code chạy được và có ý nghĩa trình bày.

---

## Hướng dẫn kỹ thuật LaTeX

### Chèn hình
```latex
\begin{figure}[H]
    \centering
    \includegraphics[width=0.85\textwidth]{figures/ten_hinh.png}
    \caption{Mô tả rõ ràng về nội dung hình.}
    \label{fig:ten_hinh}
\end{figure}
```

### Xuất hình từ R
```r
png("figures/ten_hinh.png", width = 1800, height = 1200, res = 300)
# ... code vẽ ...
dev.off()
```
Hoặc dùng `ggsave()` với ggplot2:
```r
ggsave("figures/ten_hinh.png", plot = p, width = 6, height = 4, dpi = 300)
```

### Cross-reference kết quả
Khi nhắc đến kết quả cụ thể trong văn bản, dùng `\ref{fig:...}` và `\ref{tab:...}` để liên kết động, không hardcode số trang hay số hình.

---

## Checklist trước khi báo cáo hoàn chỉnh

### Nội dung & Thống kê
- [ ] Mọi số liệu trong văn bản khớp với kết quả code R hiện tại.
- [ ] Không có mâu thuẫn giữa các section (nhận xét, kết luận, số liệu).
- [ ] Mọi kiểm định có đủ: tên + giá trị thống kê + p-value + kết luận tại α=0.05.
- [ ] Hệ số hồi quy được diễn giải theo ngữ cảnh GPU (không chỉ "dương/âm").
- [ ] Biểu đồ chẩn đoán phần dư (Residuals vs Fitted, Q-Q plot) có mặt trong báo cáo.
- [ ] Giả định của mỗi kiểm định được kiểm tra và ghi nhận trước khi dùng.

### Hình ảnh & Trình bày
- [ ] Mọi hình trong `src/figures/` đều được chèn vào báo cáo (không hình thừa).
- [ ] Tất cả biểu đồ có caption đầy đủ và label.
- [ ] Palette màu nhất quán toàn bài.
- [ ] Trục biểu đồ dùng nhãn tiếng Việt + đơn vị, không để tên biến R raw.
- [ ] Mỗi hình có đoạn nhận xét cụ thể.
- [ ] Font chữ trong plot đủ lớn để đọc khi in.

### Viết & Cấu trúc
- [ ] Mỗi `\subsection` có câu mở đầu (mục tiêu) và câu kết (phát hiện/chuyển tiếp).
- [ ] Ký hiệu toán học nhất quán với định nghĩa ở phần lý thuyết.
- [ ] Mỗi hình/bảng được nhắc đến trong văn bản đều dùng `\ref{}`.

### Kỹ thuật LaTeX
- [ ] `\FloatBarrier` đặt trước mỗi `\section` lớn.
- [ ] Bảng kết quả dùng booktabs (`\toprule`, `\midrule`, `\bottomrule`).
- [ ] Code listing trong báo cáo là bản sạch (không có debug/comment tạm).
- [ ] Bố cục `\section` giữ nguyên theo quy định giảng viên.

### Giới hạn & Tổng thể
- [ ] Báo cáo không vượt 30 trang nội dung.
- [ ] Cross-reference (`\ref{}`, `\eqref{}`) không có broken link.
