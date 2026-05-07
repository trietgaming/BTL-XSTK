# ⚡ LaTeX Realtime Editing Setup

## ✅ Đã cấu hình:

### 1. **Realtime PDF Preview** 
- Khi bạn **Ctrl+S** save `.tex` → PDF tự động build & render lại bên cạnh
- PDF hiển thị trong **tab tích hợp** (không cần mở external viewer)

### 2. **Forward Sync: Tex → PDF**
- **Cách sử dụng**: 
  - Click vào dòng bất kỳ trong `.tex` file
  - Nhấn **Ctrl+Alt+J** (hoặc double-click dòng trong editor)
  - PDF sẽ tự động scroll đến vị trí tương ứng

### 3. **Backward Sync: PDF → Tex**  
- **Cách sử dụng**:
  - **Ctrl+Click** (giữ Ctrl + click chuột) lên PDF
  - `.tex` sẽ tự động scroll & focus đến dòng code tương ứng
  - Hoặc dùng right-click "Go to source" trong PDF viewer

### 4. **Compiler Settings**
- Đang dùng: **pdfLaTeX** (default, Overleaf-like)
- Hỗ trợ tiếng Việt tốt, nhưng nếu font đẹp hơn thì chuyển sang **XeLaTeX**
- Tất cả compiler đều bật **SyncTeX** (`-synctex=1`)

---

## 🚀 Quick Start:

1. **Mở file** `main.tex`
2. Nhấn **Ctrl+Alt+L** (hoặc kích biểu tượng Build ngoài lề) để build lần đầu
3. PDF preview mở ở tab bên phải
4. **Edit & Save** (`Ctrl+S`) → PDF tự cập nhật
5. **Navigate**: Click `.tex` → Ctrl+Alt+J → PDF nhảy đến dòng đó
6. **Navigate ngược**: Ctrl+Click PDF → `.tex` tự scroll

---

## 🎛️ Tuning lệnh (nếu cần):

Các recipe có sẵn:
- `pdfLaTeX (Overleaf default)` ← **mặc định**
- `pdfLaTeX + BibTeX` (nếu dùng BibTeX)
- `pdfLaTeX + Biber` (nếu dùng Biber)
- `XeLaTeX (Unicode / tiếng Việt)` (tốt hơn cho font Vietnamese)
- `XeLaTeX + Biber`
- `LuaLaTeX`

**Để chọn recipe khác**: 
- Nhấn Ctrl+Shift+P (Command Palette)
- Gõ `LaTeX Workshop: Select recipe`
- Chọn recipe muốn dùng

---

## 📋 Keybindings chính:

| Phím | Chức năng |
|------|----------|
| **Ctrl+S** | Save & tự động rebuild PDF |
| **Ctrl+Alt+L** | Build LaTeX (fullbuild) |
| **Ctrl+Alt+J** | Forward search (Tex line → PDF) |
| **Ctrl+Click** (PDF) | Backward search (PDF → Tex) |
| **Ctrl+Shift+P** → `recipe` | Chọn compiler recipe |
| **Ctrl+L, Ctrl+W** | Xem warnings & errors |

---

## ⚠️ Troubleshooting:

### PDF không update khi save?
- Kiểm tra: Bottom-left corner có chữ "Building..." không?
- Nếu build lỗi → xem tab "PROBLEMS" ở dưới

### Syncing không hoạt động?
- Đảm bảo compiler args có `-synctex=1` ✅ (đã set sẵn)
- Thử rebuild: Ctrl+Alt+L

### File PDF bị lock / không thể write?
- Đóng PDF ngoài VS Code nếu đang mở
- Hoặc dùng Ctrl+Alt+V để toggle PDF viewer tab

---

## 💡 Tips:

1. **Tắt auto-build** nếu project lớn: 
   - Settings → tìm `latex-workshop.latex.autoBuild.run` → chọn `never`
   - Rồi dùng Ctrl+Alt+L khi muốn build

2. **Cả hai biến Bắc & Nam???**
   - Main file để có `\begin{document}` & `\end{document}`
   - LaTeX Workshop tự detect nó

3. **Build time chậm?** 
   - Có thể là do xử lý hình ảnh hoặc cache stale
   - Thử: xóa thư mục `build/` hoặc `.vscode/.latex-workshop/`

---

Happy LaTeX editing! 🎉
