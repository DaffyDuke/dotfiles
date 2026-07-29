#!/usr/bin/env python3
"""
Convertisseur Markdown vers SPIP (Sans dépendance externe).
Usage: cat fichier.md | python3 md2spip_simple.py
"""

import sys
import re


def convert_md_to_spip(text):
    if not text:
        return ""

    lines = text.split("\n")
    output_lines = []
    in_code_block = False
    in_ul = False
    in_ol = False

    i = 0
    while i < len(lines):
        line = lines[i]

        # 1. Gestion des blocs de code (``` ou ~~~)
        if re.match(r"^(```|~~~)", line):
            if not in_code_block:
                in_code_block = True
                output_lines.append("<code>")
            else:
                in_code_block = False
                output_lines.append("</code>")
            i += 1
            continue

        if in_code_block:
            output_lines.append(line)
            i += 1
            continue

        # 2. Gestion des titres (# ## ###)
        # On commence par les plus grands titres pour éviter les conflits
        m = re.match(r"^(#{1,6})\s+(.*)", line)
        if m:
            level = len(m.group(1))
            content = m.group(2).strip()
            # SPIP utilise {Titre} pour h1, mais on peut utiliser {Titre} pour tous
            # ou différencier si besoin. Ici on met tout en {Titre} comme c'est le standard simple,
            # ou on peut ajouter des sauts de ligne.
            output_lines.append(f"{{{content}}}")
            i += 1
            continue

        # 3. Gestion des listes
        # Liste non ordonnée (- * ou +)
        m_ul = re.match(r"^\s*[-*+]\s+(.*)", line)
        if m_ul:
            if not in_ul:
                in_ul = True
            content = m_ul.group(1)
            output_lines.append(f"-* {content}")
            i += 1
            continue
        else:
            if in_ul:
                in_ul = False

        # Liste ordonnée (1. 2.)
        m_ol = re.match(r"^\s*\d+\.\s+(.*)", line)
        if m_ol:
            if not in_ol:
                in_ol = True
            content = m_ol.group(1)
            output_lines.append(f"-# {content}")
            i += 1
            continue
        else:
            if in_ol:
                in_ol = False

        # 4. Citations (> )
        m_quote = re.match(r"^>\s?(.*)", line)
        if m_quote:
            output_lines.append(f"<quote>{m_quote.group(1)}</quote>")
            i += 1
            continue

        # 5. Lignes vides
        if line.strip() == "":
            output_lines.append("")
            i += 1
            continue

        # 6. Traitement inline (gras, italique, liens) sur les lignes normales
        processed_line = line

        # Liens [text](url) -> [text->url]
        processed_line = re.sub(
            r"\[([^\]]+)\]\(([^\)]+)\)", r"[\1->\2]", processed_line
        )

        # Images ![alt](src) -> <img|src=src|alt=alt>
        processed_line = re.sub(
            r"!\[([^\]]*)\]\(([^\)]+)\)", r"<img|src=\2|alt=\1>", processed_line
        )

        # Gras **text** -> {{text}}
        processed_line = re.sub(r"\*\*(.+?)\*\*", r"{{\1}}", processed_line)

        # Italique *text* -> {text}
        # Attention à ne pas matcher les -* des listes déjà traitées, mais ici on est hors liste
        processed_line = re.sub(r"(?<!\*)\*(.+?)\*(?!\*)", r"{\1}", processed_line)

        # Code inline `text` -> <code>text</code>
        processed_line = re.sub(r"`([^`]+)`", r"<code>\1</code>", processed_line)

        output_lines.append(processed_line)
        i += 1

    # Fermeture des balises ouvertes si nécessaire (fin de fichier)
    if in_code_block:
        output_lines.append("</code>")

    return "\n".join(output_lines)


def main():
    input_text = sys.stdin.read()
    spip_output = convert_md_to_spip(input_text)
    sys.stdout.write(spip_output)


if __name__ == "__main__":
    main()
