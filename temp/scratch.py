import re

file_path = r'c:\Users\Triet\OneDrive - MSFT\Documents\latexdev\Giai_thich_code_va_ket_qua.tex'

with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

listings = re.findall(r'\\begin\{lstlisting\}.*?\\end\{lstlisting\}', text, re.DOTALL)
chars = set()
for l in listings:
    for c in l:
        if ord(c) > 127:
            chars.add(c)

literate_items = []
for c in sorted(chars):
    # Map the unicode char to itself so standard LaTeX rendering takes over
    literate_items.append(f"    {{{c}}}{{{c}}}{{1}}")

literate_str = "    literate=\n" + " \\penalty0\n".join(literate_items) + ","

# Insert into lstset
text = text.replace('    backgroundcolor=\\color{backcolour},', '    extendedchars=true,\n' + literate_str + '\n    backgroundcolor=\\color{backcolour},')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)

print("Done inserting literate!")
