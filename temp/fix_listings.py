import re

file_path = r'c:\Users\Triet\OneDrive - MSFT\Documents\latexdev\Giai_thich_code_va_ket_qua.tex'
with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# Remove the broken literate configuration and extendedchars
text = re.sub(r'\s*extendedchars=true,.*?\s*ờ\}{ờ}\{1\}', '', text, flags=re.DOTALL)
text = re.sub(r'literate=\s*\{\Â\}\{\Â\}\{1\}.*?ờ\}{ờ}\{1\}', '', text, flags=re.DOTALL)

# Also remove any trailing literate commas or empty ones if they exist
text = re.sub(r'literate=\s*,', '', text)

# Add escapeinside to lstset if not exists
if 'escapeinside=' not in text:
    text = text.replace('backgroundcolor=\\color{backcolour},', 'backgroundcolor=\\color{backcolour},\n    escapeinside={(*@}{@*)},')

def process_listings(match):
    block = match.group(0)
    # Wrap comments containing non-ASCII
    lines = block.split('\n')
    new_lines = []
    for line in lines:
        if '#' in line and any(ord(c) > 127 for c in line):
            # Wrap the comment part
            parts = line.split('#', 1)
            new_lines.append(parts[0] + '# (*@' + parts[1] + '@*)')
        elif '"' in line and any(ord(c) > 127 for c in line):
            # Wrap the string part containing non ascii
            def rep_string(m):
                s = m.group(0)
                if any(ord(c) > 127 for c in s):
                    # We wrap the inner content
                    return '"(*@' + s[1:-1] + '@*)"'
                return s
            new_line = re.sub(r'"[^"]+"', rep_string, line)
            new_lines.append(new_line)
        else:
            new_lines.append(line)
    return '\n'.join(new_lines)

text = re.sub(r'\\begin\{lstlisting\}.*?\\end\{lstlisting\}', process_listings, text, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)

print("Fix applied successfully!")
