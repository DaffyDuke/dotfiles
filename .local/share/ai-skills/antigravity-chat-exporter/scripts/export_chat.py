#!/usr/bin/env python3
"""
Antigravity Chat Exporter
Exporte les conversations Antigravity au format Markdown (.md).
"""

import argparse
import glob
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path


def get_default_app_data_dir() -> Path:
    env_dir = os.environ.get("ANTIGRAVITY_APP_DATA_DIR")
    if env_dir and os.path.isdir(env_dir):
        return Path(env_dir)
    default_path = Path.home() / ".gemini" / "antigravity-cli"
    return default_path


def get_all_conversations(app_data_dir: Path):
    brain_dir = app_data_dir / "brain"
    if not brain_dir.exists():
        return []
    
    conversations = []
    for entry in brain_dir.iterdir():
        if entry.is_dir() and not entry.name.startswith("."):
            log_full = entry / ".system_generated" / "logs" / "transcript_full.jsonl"
            log_compact = entry / ".system_generated" / "logs" / "transcript.jsonl"
            log_file = log_full if log_full.exists() else (log_compact if log_compact.exists() else None)
            
            mtime = 0
            if log_file and log_file.exists():
                mtime = log_file.stat().st_mtime
            else:
                mtime = entry.stat().st_mtime
                
            conversations.append({
                "id": entry.name,
                "dir": entry,
                "log_file": log_file,
                "mtime": mtime
            })
            
    conversations.sort(key=lambda x: x["mtime"], reverse=True)
    return conversations


def clean_user_message(content: str) -> str:
    if not content:
        return ""
    # Extract <USER_REQUEST> if present
    req_match = re.search(r"<USER_REQUEST>(.*?)</USER_REQUEST>", content, re.DOTALL)
    if req_match:
        text = req_match.group(1).strip()
    else:
        # Strip system wrappers
        text = re.sub(r"<ADDITIONAL_METADATA>.*?</ADDITIONAL_METADATA>", "", content, flags=re.DOTALL)
        text = re.sub(r"<SYSTEM_MESSAGE>.*?</SYSTEM_MESSAGE>", "", text, flags=re.DOTALL)
        text = re.sub(r"<EPHEMERAL_MESSAGE>.*?</EPHEMERAL_MESSAGE>", "", text, flags=re.DOTALL)
        text = re.sub(r"<USER_SETTINGS_CHANGE>.*?</USER_SETTINGS_CHANGE>", "", text, flags=re.DOTALL)
    return text.strip()


def parse_transcript(log_file: Path):
    steps = []
    if not log_file or not log_file.exists():
        return steps

    with open(log_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                step = json.loads(line)
                steps.append(step)
            except json.JSONDecodeError:
                continue
    return steps


def format_iso_date(iso_str: str) -> str:
    if not iso_str:
        return ""
    try:
        dt = datetime.fromisoformat(iso_str.replace("Z", "+00:00"))
        # Local representation
        return dt.astimezone().strftime("%Y-%m-%d %H:%M:%S")
    except Exception:
        return iso_str


def export_conversation_to_markdown(
    conv_info: dict,
    include_tools: bool = False,
    include_thinking: bool = False,
    custom_title: str = None
) -> str:
    conv_id = conv_info["id"]
    log_file = conv_info["log_file"]
    steps = parse_transcript(log_file) if log_file else []

    first_user_prompt = ""
    start_time = None
    end_time = None
    user_count = 0
    assistant_count = 0
    tool_count = 0

    rendered_blocks = []

    for step in steps:
        step_type = step.get("type")
        created_at = step.get("created_at", "")
        formatted_date = format_iso_date(created_at)

        if created_at:
            if not start_time:
                start_time = formatted_date
            end_time = formatted_date

        if step_type == "USER_INPUT":
            raw_content = step.get("content", "")
            user_msg = clean_user_message(raw_content)
            if not user_msg:
                continue
            user_count += 1
            if not first_user_prompt:
                first_user_prompt = user_msg.split("\n")[0][:80].strip()

            date_line = f" *({formatted_date})*" if formatted_date else ""
            block = f"## 👤 Utilisateur{date_line}\n\n{user_msg}\n"
            rendered_blocks.append(block)

        elif step_type == "PLANNER_RESPONSE":
            content = step.get("content", "")
            thinking = step.get("thinking", "")
            tool_calls = step.get("tool_calls", [])

            tool_count += len(tool_calls)

            sub_blocks = []

            # Optional: Thinking
            if include_thinking and thinking:
                sub_blocks.append(
                    f"<details>\n<summary>💭 <i>Raisonnement (Thinking)</i></summary>\n\n"
                    f"{thinking.strip()}\n\n</details>\n"
                )

            # Optional: Tool calls
            if include_tools and tool_calls:
                for tc in tool_calls:
                    fn_name = tc.get("name") or tc.get("tool_name") or "tool"
                    fn_args = tc.get("arguments") or tc.get("args") or {}
                    args_formatted = json.dumps(fn_args, indent=2, ensure_ascii=False)
                    sub_blocks.append(
                        f"<details>\n<summary>🛠️ <i>Outil : <code>{fn_name}</code></i></summary>\n\n"
                        f"```json\n{args_formatted}\n```\n\n</details>\n"
                    )

            if content:
                assistant_count += 1
                date_line = f" *({formatted_date})*" if formatted_date else ""
                sub_blocks.append(f"## 🤖 Assistant{date_line}\n\n{content.strip()}\n")

            if sub_blocks:
                rendered_blocks.append("\n".join(sub_blocks))

    title = custom_title or (f"Discussion : {first_user_prompt}" if first_user_prompt else f"Conversation {conv_id[:8]}")

    header = [
        f"# {title}\n",
        f"- **ID Conversation** : `{conv_id}`",
        f"- **Début** : {start_time or 'N/A'}",
        f"- **Fin** : {end_time or 'N/A'}",
        f"- **Échanges** : {user_count} messages utilisateur, {assistant_count} réponses assistant",
    ]
    if include_tools:
        header.append(f"- **Outils exécutés** : {tool_count}")
    header.append("\n---\n")

    full_markdown = "\n".join(header) + "\n" + "\n---\n\n".join(rendered_blocks) + "\n"
    return full_markdown


def main():
    parser = argparse.ArgumentParser(description="Exportateur de conversations Google Antigravity en Markdown.")
    parser.add_argument("-c", "--conversation-id", help="ID de la conversation à exporter (par défaut : la plus récente)")
    parser.add_argument("-o", "--output", help="Chemin du fichier ou dossier de destination")
    parser.add_argument("-a", "--all", action="store_true", help="Exporter toutes les conversations")
    parser.add_argument("-l", "--list", action="store_true", help="Lister les conversations disponibles")
    parser.add_argument("--include-tools", action="store_true", help="Inclure les appels d'outils (details repliables)")
    parser.add_argument("--include-thinking", action="store_true", help="Inclure les chaînes de pensée de l'assistant")
    parser.add_argument("--title", help="Titre personnalisé pour la conversation")
    parser.add_argument("--app-data-dir", help="Répertoire de données d'Antigravity (défaut: ~/.gemini/antigravity-cli)")

    args = parser.parse_args()

    app_data_dir = Path(args.app_data_dir).expanduser() if args.app_data_dir else get_default_app_data_dir()
    if not app_data_dir.exists():
        print(f"❌ Répertoire Antigravity introuvable : {app_data_dir}", file=sys.stderr)
        sys.exit(1)

    conversations = get_all_conversations(app_data_dir)
    if not conversations:
        print(f"⚠️ Aucune conversation trouvée dans {app_data_dir / 'brain'}")
        sys.exit(0)

    # 1. Lister les conversations
    if args.list:
        print(f"📂 {len(conversations)} conversation(s) trouvée(s) dans {app_data_dir / 'brain'} :\n")
        print(f"{'ID':<38} {'Date / Heure':<20} {'Premier prompt'}")
        print("-" * 90)
        for c in conversations:
            steps = parse_transcript(c["log_file"]) if c["log_file"] else []
            prompt_preview = "N/A"
            for s in steps:
                if s.get("type") == "USER_INPUT":
                    msg = clean_user_message(s.get("content", ""))
                    if msg:
                        prompt_preview = msg.replace("\n", " ")[:45] + ("..." if len(msg) > 45 else "")
                        break
            date_str = datetime.fromtimestamp(c["mtime"]).strftime("%Y-%m-%d %H:%M:%S")
            print(f"{c['id']:<38} {date_str:<20} {prompt_preview}")
        return

    # 2. Exporter toutes les conversations
    if args.all:
        out_dir = Path(args.output).expanduser() if args.output else Path.cwd() / "antigravity_exports"
        out_dir.mkdir(parents=True, exist_ok=True)
        print(f"🚀 Exportation de {len(conversations)} conversation(s) vers {out_dir}...")
        for c in conversations:
            md = export_conversation_to_markdown(
                c,
                include_tools=args.include_tools,
                include_thinking=args.include_thinking,
                custom_title=args.title
            )
            date_prefix = datetime.fromtimestamp(c["mtime"]).strftime("%Y%m%d_%H%M")
            filename = f"conversation_{date_prefix}_{c['id'][:8]}.md"
            out_file = out_dir / filename
            with open(out_file, "w", encoding="utf-8") as f:
                f.write(md)
            print(f"  ✓ {filename}")
        print(f"\n✅ Export terminé dans {out_dir}")
        return

    # 3. Exporter une seule conversation
    target_conv = None
    if args.conversation_id:
        for c in conversations:
            if c["id"] == args.conversation_id or c["id"].startswith(args.conversation_id):
                target_conv = c
                break
        if not target_conv:
            print(f"❌ Conversation '{args.conversation_id}' introuvable.", file=sys.stderr)
            sys.exit(1)
    else:
        # Prendre la plus récente
        target_conv = conversations[0]

    md_content = export_conversation_to_markdown(
        target_conv,
        include_tools=args.include_tools,
        include_thinking=args.include_thinking,
        custom_title=args.title
    )

    # Déterminer le fichier de sortie
    if args.output:
        out_path = Path(args.output).expanduser()
        if out_path.is_dir() or args.output.endswith("/") or args.output.endswith("\\"):
            out_path.mkdir(parents=True, exist_ok=True)
            date_prefix = datetime.fromtimestamp(target_conv["mtime"]).strftime("%Y%m%d_%H%M")
            out_file = out_path / f"conversation_{date_prefix}_{target_conv['id'][:8]}.md"
        else:
            out_path.parent.mkdir(parents=True, exist_ok=True)
            out_file = out_path
    else:
        date_prefix = datetime.fromtimestamp(target_conv["mtime"]).strftime("%Y%m%d_%H%M")
        out_file = Path.cwd() / f"conversation_{date_prefix}_{target_conv['id'][:8]}.md"

    with open(out_file, "w", encoding="utf-8") as f:
        f.write(md_content)

    print(f"✅ Conversation exportée avec succès vers : {out_file}")


if __name__ == "__main__":
    main()
