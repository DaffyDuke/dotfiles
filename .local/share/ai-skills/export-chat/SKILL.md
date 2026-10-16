---
name: export-chat
description: >-
  Exporte les conversations OpenCode (ou sessions) au format Markdown. Utilise
  cette compétence lorsque l'utilisateur demande d'exporter, sauvegarder ou
  convertir des conversations ou sessions de chat en Markdown.
---

# OpenCode Chat Exporter

Cette compétence permet d'exporter les conversations OpenCode stockées sous forme de sessions ou transcripts en fichiers Markdown (`.md`) propres et structurés.

## Quand utiliser cette compétence

Active cette compétence lorsque :
- L'utilisateur demande "d'exporter la conversation" / "export chat"
- L'utilisateur souhaite sauvegarder ou archiver sa discussion actuelle ou passée en format Markdown
- L'utilisateur veut lister les sessions/conversations disponibles

## Instructions d'utilisation

Utilise le script Python situé dans `scripts/export_chat.py`.

### 1. Exporter la conversation courante ou la plus récente
```bash
python3 ~/.config/opencode/skills/export-chat/scripts/export_chat.py -o "./export.md"
```

### 2. Exporter toutes les conversations
```bash
python3 ~/.config/opencode/skills/export-chat/scripts/export_chat.py --all -o "./opencode_exports"
```

### 3. Lister les conversations disponibles
```bash
python3 ~/.config/opencode/skills/export-chat/scripts/export_chat.py --list
```
