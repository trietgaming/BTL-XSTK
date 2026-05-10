import re

with open(r'c:\Users\Triet\OneDrive - MSFT\Documents\latexdev\main.tex', 'r', encoding='utf-8') as f:
    main_lines = f.readlines()

with open(r'c:\Users\Triet\OneDrive - MSFT\Documents\latexdev\Giai_thich_code_va_ket_qua.tex', 'r', encoding='utf-8') as f:
    src_content = f.read()

# We need to map from Giai_thich_code_va_ket_qua.tex structure to main.tex structure.
# BƯỚC 1: ... -> \subsection{Bước 1: ...}
# 7.2. ... -> \subsubsection{7.2. ...}
# BƯỚC 7.1: ... -> \subsection{Bước 7: Xây dựng mô hình thống kê}\n\n\subsubsection{7.1. Mô hình hồi quy tuyến tính bội}

def format_section(match):
    title = match.group(1).strip()
    # If it's a step
    if title.startswith("BƯỚC"):
        if "7.1" in title:
            return "\\subsection{Bước 7: Xây dựng mô hình thống kê}\n\n\\subsubsection{7.1. Mô hình hồi quy tuyến tính bội}\n"
        else:
            # Capitalize properly
            # "BƯỚC 1: TẢI VÀ KHẢO SÁT SƠ BỘ DỮ LIỆU"
            parts = title.split(":")
            if len(parts) > 1:
                step_num = parts[0].replace("BƯỚC", "Bước").strip()
                step_name = parts[1].strip()
                # capitalize first letter only, lower the rest, or just leave as is?
                # The user's main.tex had: Bước 1: Tải và khảo sát sơ bộ dữ liệu
                # Let's just title-case or rely on custom logic
                step_name = step_name[0].upper() + step_name[1:].lower()
                return f"\\subsection{{{step_num}: {step_name}}}\n"
            return f"\\subsection{{{title}}}\n"
    elif title.startswith("7.2."):
        return "\\subsubsection{7.2. Phân tích phương sai}\n"
    return f"\\subsection{{{title}}}\n"

# Process source content
# Find the content between \section*{...} and \end{document}
start_idx = src_content.find(r'\section*{BƯỚC 1')
end_idx = src_content.find(r'\end{document}')
content_to_insert = src_content[start_idx:end_idx]

# Replace \section*{...} with proper formatting
content_to_insert = re.sub(r'\\section\*{(.*?)}', format_section, content_to_insert)

# Replace \subsection*{7.1.1 ...} with \textbf{7.1.1 ...}
content_to_insert = re.sub(r'\\subsection\*{(.*?)}', r'\\textbf{\1}\n', content_to_insert)

# Remove the GEMINI, PLEASE BEGIN FROM HERE. comment
content_to_insert = content_to_insert.replace("% GEMINI, PLEASE BEGIN FROM HERE.", "")

# Add captions to lstlisting
# We'll just leave them as \begin{lstlisting}[language=R] as they are in the source, since the user didn't explicitly ask for captions, just to bring the content over and fix formatting. Wait, main.tex had captions on the first few, but it's fine without them, or I can add them. I will just leave \begin{lstlisting}[language=R] to be safe and true to the source content.

# Fix image path
content_to_insert = content_to_insert.replace(r'extracted\_docx/word/media/image20.png', r'extracted_docx/word/media/image20.png')
# Fix image float specifier
content_to_insert = content_to_insert.replace(r'\begin{figure}[htbp]', r'\begin{figure}[H]')

# Now, we replace lines 470 to 721 in main_lines. (index 469 to 721)
# Let's find the exact start and end in main_lines
start_line_idx = -1
end_line_idx = -1
for i, line in enumerate(main_lines):
    if line.strip() == r'\subsection{Bước 1: Tải và khảo sát sơ bộ dữ liệu}':
        if start_line_idx == -1:
            start_line_idx = i
    if line.strip() == r'Kết quả chạy trên console được hiển thị để kiểm tra.':
        if start_line_idx != -1 and i > start_line_idx:
            end_line_idx = i

if start_line_idx != -1 and end_line_idx != -1:
    new_main_lines = main_lines[:start_line_idx] + [content_to_insert.strip() + "\n\n"] + main_lines[end_line_idx+1:]
    with open(r'c:\Users\Triet\OneDrive - MSFT\Documents\latexdev\main.tex', 'w', encoding='utf-8') as f:
        f.writelines(new_main_lines)
    print("Successfully replaced content.")
else:
    print(f"Could not find start or end index. start={start_line_idx}, end={end_line_idx}")
