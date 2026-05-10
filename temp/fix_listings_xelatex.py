import re

file_path = 'c:/Users/Triet/OneDrive - MSFT/Documents/latexdev/Giai_thich_code_va_ket_qua.tex'
with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

if 'escapeinside={(*@}{@*)}' not in text:
    text = text.replace('backgroundcolor=\\color{backcolour},', 'backgroundcolor=\\color{backcolour},\n    escapeinside={(*@}{@*)},')

def process_listings(match):
    block = match.group(0)
    lines = block.split('\n')
    new_lines = []
    for line in lines:
        if any(ord(c) > 127 for c in line):
            if line.lstrip().startswith('#'):
                # It's a comment line
                indent = line[:line.find('#')]
                content = line[line.find('#')+1:]
                new_line = indent + '# (*@' + content + '@*)'
                new_lines.append(new_line)
            elif 'cat(' in line or 'main=' in line or 'xlab=' in line or 'ylab=' in line:
                # Wrap inside strings
                def repl_str(m):
                    return '\"(*@' + m.group(1) + '@*)\"'
                new_line = re.sub(r'"([^"]*[^\x00-\x7F]+[^"]*)"', repl_str, line)
                new_lines.append(new_line)
            elif line.startswith('---'):
                # Console output line
                # We need to escape it inside \texttt
                escaped = line.replace('\\', '\\textbackslash{}').replace('_', '\\_').replace('#', '\\#').replace('%', '\\%').replace('&', '\\&').replace('{', '\\{').replace('}', '\\}').replace('~', '\\~{}').replace('^', '\\^{}')
                new_lines.append('(*@\\texttt{' + escaped + '}@*)')
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)
    return '\n'.join(new_lines)

text = re.sub(r'\\begin\{lstlisting\}.*?\\end\{lstlisting\}', process_listings, text, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)
print('Done!')
