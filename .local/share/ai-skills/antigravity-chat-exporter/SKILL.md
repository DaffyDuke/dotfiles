---
name: antigravity-chat-exporter
description: >-
  Export Antigravity conversations to clean Markdown files. Use when the user asks
  to export, dump, backup, or save conversations or chat logs to Markdown.
---

# Antigravity Chat Exporter

This skill allows exporting raw or formatted Antigravity conversations from `transcript.jsonl` / `transcript_full.jsonl` into Markdown (`.md`) files.

## When to use this skill

Activate this skill when:
- The user requests to "export the conversation" / "exporter la conversation"
- The user asks to backup or save previous or current discussions in Markdown format
- The user wants a list of past conversations

## Usage Instructions

Use the `run_command` tool to execute the Python script located at `scripts/export_chat.py` inside this skill directory (or directly via the CLI command `export-chat`).

### 1. Export Current Conversation
```bash
python3 ~/.gemini/config/skills/antigravity-chat-exporter/scripts/export_chat.py -c "<CONVERSATION_ID>" -o "<OUTPUT_PATH_OR_DIR>"
```
*Note*: The current conversation ID can be obtained from the system prompt (`Conversation ID:`).

### 2. Export All Conversations
```bash
python3 ~/.gemini/config/skills/antigravity-chat-exporter/scripts/export_chat.py --all -o "./antigravity_exports"
```

### 3. List Available Conversations
```bash
python3 ~/.gemini/config/skills/antigravity-chat-exporter/scripts/export_chat.py --list
```

### 4. Advanced Options
- `--include-tools`: Include collapsible `<details>` blocks showing tool names and executed parameters.
- `--include-thinking`: Include collapsible `<details>` blocks showing model reasoning/thought processes.
- `--title "<Custom Title>"`: Set a custom title header for the conversation.
