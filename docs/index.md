# Documentation du Projet Dotfiles

**Généré le :** 14 janvier 2026  
**Type de projet :** CLI Tools / Scripts Collection  
**Propriétaire :** Daffy  
**Niveau de scan :** Deep Dive (analyse complète)

---

## 📋 Vue d'ensemble

Ce projet est une collection complète de dotfiles multi-OS (Debian/Ubuntu et macOS), scripts utilitaires et configurations système pour personnaliser et automatiser un environnement de développement.

### 🎯 Objectifs principaux

- **Configuration système unifiée** : Gestion centralisée des dotfiles via Git bare repository
- **Support multi-OS** : Branches distinctes pour Debian/Ubuntu et macOS
- **Automatisation d'installation** : Scripts d'installation pour 107+ logiciels et outils (setup.sh)
- **Framework BMAD** : Système de développement assisté par IA
- **Utilitaires système** : Collection de 44+ scripts shell et Python pour administration
- **Configurations serveur** : Scripts pour YunoHost, FreeNAS et services

---

## 🚀 Quick Start

### Bootstrap d'un nouvel ordinateur

```bash
# Méthode recommandée avec Makefile
make bootstrap    # Clone le repo et configure l'environnement
make install      # Installe tous les logiciels via setup.sh
```

### Commandes Make principales

| Commande | Description |
|----------|-------------|
| `make help` | Affiche l'aide complète avec toutes les commandes |
| `make bootstrap` | Configure un nouvel ordinateur (clone dotfiles, installe config) |
| `make install` | Exécute setup.sh pour installer tous les logiciels |
| `make check-syntax` | Vérifie la syntaxe de setup.sh et .zshrc |
| `make merge-branches` | Merge debian→develop, macos→develop, develop→main |
| `make sync` | Push toutes les branches vers origin |
| `make status` | Affiche l'état du dépôt dotfiles |
| `make commit` | Commit interactif avec commitizen |

Voir [README.md](../README.md) pour plus de détails.

---

## 🏗️ Architecture du projet

### Structure des répertoires

```
dotfiles/
├── bin/                    # Scripts utilitaires (40+ scripts)
├── _bmad/                  # Framework BMAD pour développement assisté par IA
│   ├── _config/           # Configuration agents et workflows
│   ├── bmb/               # Module BMad Builder
│   ├── bmgd/              # Module Game Development
│   ├── bmm/               # Module Methodology Management
│   ├── cis/               # Module Creative Innovation Systems
│   └── core/              # Fonctionnalités core
├── _bmad-output/          # Sorties des workflows BMAD
├── docs/                  # Documentation (ce fichier)
├── freenas/               # Configuration FreeNAS
├── yunohost/              # Scripts backup et gestion YunoHost
├── Modèles/               # Templates de fichiers
├── .config/               # Configurations applicatives
├── .claude/               # Configuration et hooks Claude AI
└── setup.sh               # Script d'installation principal (1656 lignes)
```

---

## 💻 Technologies

### Langages et outils

| Catégorie | Technologies | Description |
|-----------|--------------|-------------|
| **Shell scripting** | Bash, Zsh | Scripts système et automatisation |
| **Python** | Python 3.x | Scripts utilitaires avancés |
| **Node.js** | npm, commitizen | Gestion des commits et outils JS |
| **Version control** | Git | Workflow personnalisé pour dotfiles |
| **Terminal** | Zsh + Oh-My-Zsh | Shell interactif configuré |
| **Éditeurs** | Vim, NeoVim | Configuration avancée |

### Dépendances principales (package.json)

- **d3-force** (^3.0.0) : Visualisation de données
- **gitbook-cli** (^2.3.2) : Documentation
- **stream-json** (^1.9.1) : Traitement JSON streaming
- **tweet-to-toot** (^0.7.3) : Bridge Twitter/Mastodon
- **cz-conventional-changelog** (^3.3.0) : Commits conventionnels

---

## 🛠️ Composants principaux

### 1. Script d'installation principal (setup.sh)

**Fonctions principales détectées** (80+ fonctions) :
- `Setup()` : Configuration initiale Ubuntu
- `Packages()` : Installation packages système
- `Docker()` : Installation et configuration Docker
- `GnomeExtensions()` : Extensions Gnome Shell
- `Python()`, `GO()` : Environnements de développement
- `ZSH()` : Configuration Zsh et Oh-My-Zsh
- Et 70+ autres fonctions d'installation...

### 2. Scripts utilitaires (bin/)

**40+ scripts classés par catégorie :**

#### Administration système
- `date-dir-cleanup.sh` : Gestion répertoires datés YYYY-MM-DD
- `cleanup.sh` : Nettoyage système
- `datadog_status.sh` : Monitoring Datadog
- `memused.sh` : Utilisation mémoire
- `getswap` : Info swap

#### Réseau et certificats
- `check_cert` : Vérification certificats SSL
- `get_certs.sh` : Récupération certificats
- `wifi`, `wificheck` : Gestion WiFi
- `dig-plus` : DNS debugging avancé
- `vpn.sh` : Gestion VPN

#### Docker et conteneurs
- `docker-clean.sh` : Nettoyage images Docker

#### Cloud et synchronisation
- `cloudsync.sh` : Synchronisation cloud

#### Gnome et extensions
- `gnome-shell-extension-cl` : CLI extensions Gnome
- `gnomeshell-extension-manage` : Gestion extensions

#### Git et développement
- `gpull.sh` : Git pull automatisé
- `list-alias` : Liste tous les alias shell

#### Sécurité
- `hibp` : Have I Been Pwned checker
- `rkhunter.conf` : Configuration rootkit hunter

#### Python utilitaires
- `generate-thumbnails.py` : Génération miniatures
- `get_screensavers.py` : Téléchargement screensavers
- `nextcloud-status.py` : Status Nextcloud

### 3. Framework BMAD

**5 modules installés :**

1. **Core** : Fonctionnalités de base
   - Brainstorming
   - Party mode (multi-agents)
   - Workflows core

2. **BMB** (BMad Builder) : Construction d'agents/workflows
   - Création d'agents
   - Création de modules
   - Création de workflows

3. **BMGD** (Game Development) : Développement de jeux
   - Workflows pré-production (brainstorm, brief, GDD)
   - Workflows design (narrative, architecture)
   - Workflows production (stories, sprint, code review)
   - Game testing workflows

4. **BMM** (Methodology Management) : Gestion projet
   - Workflows analyse (product brief, research)
   - Workflows planning (PRD, UX, architecture)
   - Workflows implémentation (sprint, dev, code review)
   - Quick flows (dev rapide, specs)

5. **CIS** (Creative Innovation Systems) : Innovation
   - Brainstorming coaching
   - Problem solving créatif
   - Design thinking
   - Stratégie d'innovation

**IDEs supportés :** Claude Code, Codex, Cursor, GitHub Copilot, Windsurf, et 12 autres

### 4. Configuration serveurs

#### YunoHost (yunohost/)
- `backup.sh` : Backup complet (web, mails, bases de données)
- `backup_to_OVH.sh` : Backup vers OVH
- `nextcloud-installer.sh` : Installation apps Nextcloud
- `service_failed.sh` : Gestion services échoués
- `dedup.py`, `imapdedup.py` : Déduplication emails

#### FreeNAS (freenas/)
- Configuration boot et services
- Scripts Jackett
- `loader.conf` : Configuration boot

---

## 🎨 Configurations dotfiles

### Fichiers de configuration principaux

```
.aliases          # Alias shell personnalisés
.zshrc            # Configuration Zsh
.vimrc            # Configuration Vim
.profile          # Variables d'environnement
.gitconfig        # Configuration Git
.tmux.conf        # Configuration Tmux
.nbrc             # Configuration nb (notes)
```

### Workflow Git personnalisé

```bash
alias config='git --git-dir=$HOME/dotfiles --work-tree=$HOME'
```

Permet de gérer les dotfiles avec Git sans dossier .git dans HOME.

**Exemple d'utilisation :**
```bash
config add .zshrc
config cz commit  # Avec commitizen
```

---

## 📦 Installation et utilisation

### Prérequis

1. Ubuntu/Debian Linux
2. Git installé
3. Accès sudo

### Installation initiale

```bash
# Clone du repo (méthode bare repository)
alias config='git --git-dir=$HOME/dotfiles --work-tree=$HOME'

# Lancer l'installation complète
./setup.sh

# Ou installation sélective d'un composant
./setup.sh Docker
./setup.sh ZSH
./setup.sh GnomeExtensions
```

### Utilisation quotidienne

```bash
# Lister les alias disponibles
list-alias

# Nettoyer répertoires datés
date-dir-cleanup.sh --execute /path/to/dir

# Vérifier certificat SSL
check_cert example.com

# Nettoyer Docker
docker-clean.sh

# Monitoring mémoire
memused.sh
```

---

## 🔧 Workflows BMAD

### Initialisation projet

```bash
# Pour game dev
*workflow-init

# Pour projet applicatif
/bmad:bmm:workflows:sprint-status
```

### Workflows disponibles

**Core (2 workflows) :**
- `brainstorming` : Sessions de brainstorming
- `party-mode` : Discussions multi-agents

**BMB (3 workflows) :**
- `agent` : Créer/éditer agents
- `module` : Créer modules BMAD
- `workflow` : Créer workflows

**BMGD (31 workflows) :** Développement jeux complet

**BMM (23 workflows) :** Méthodologie projet complète

**CIS (6 workflows) :** Innovation et créativité

---

## 📚 Documentation existante

- **README.md** : Guide rapide et crédits
- **CHANGELOG.md** : Historique des changements
- **Windows.md** : Notes pour dual-boot Windows
- **[docs/index.md](index.md)** : Documentation complète (ce fichier)
- **[docs/bin-scripts-detailed.md](bin-scripts-detailed.md)** : ⭐ Analyse exhaustive des 44 scripts utilitaires

---

## 🎯 Cas d'usage

### 1. Nouvelle installation Ubuntu

```bash
./setup.sh
```

Installe automatiquement 100+ outils et configurations.

### 2. Développement assisté par IA

Utiliser les workflows BMAD pour :
- Créer des specs techniques
- Générer du code
- Faire des revues de code
- Gérer des sprints

### 3. Administration serveur

Scripts YunoHost pour backup automatisés et maintenance.

### 4. Utilitaires quotidiens

Collection de 40+ scripts pour tâches courantes.

---

## 🔐 Sécurité et maintenance

### Points d'attention

- **Scripts sudo** : Plusieurs scripts nécessitent des privilèges root
- **Credentials** : Fichier `/etc/yunohost/personnals` contient des secrets
- **Backup** : Scripts de backup configurés pour OVH
- **Git workflow** : Les dotfiles sont versionnés, attention aux secrets

### Bonnes pratiques

1. Réviser les scripts avant exécution
2. Tester en mode dry-run quand disponible
3. Sauvegarder avant modifications système
4. Ne pas commiter de secrets dans les dotfiles

---

## 🚀 Extensions et personnalisation

### Ajouter un nouveau script utilitaire

1. Créer le script dans `bin/`
2. Rendre exécutable : `chmod +x bin/mon-script.sh`
3. Commiter : `config add bin/mon-script.sh && config cz commit`

### Créer un nouveau workflow BMAD

```bash
# Utiliser le workflow builder
/bmad:bmb:workflows:workflow
```

### Ajouter une fonction dans setup.sh

Suivre le pattern existant :
```bash
MaFonction() {
  # Description
  # Installation de X
  commandes...
}
```

---

## 📊 Statistiques du projet

- **Scripts shell** : 44 fichiers
- **Scripts Python** : 3+ fichiers  
- **Fichiers de configuration** : 145+ fichiers
- **Workflows BMAD** : 69 workflows
- **Agents BMAD** : 25 agents
- **Lignes setup.sh** : ~1656 lignes
- **Fonctions setup.sh** : 80+ fonctions

---

## 🔗 Références et crédits

### Sources originales
- Forked from: https://github.com/owulveryck/dotfiles
- Adapted with: https://lord.re/posts/62-dotfiles-home-git/
- Tips from: https://catonmat.net/linux-and-vim-notes

### Technologies principales
- [Oh-My-Zsh](https://ohmyz.sh/)
- [Vim](https://www.vim.org/)
- [Commitizen](http://commitizen.github.io/cz-cli/)
- [BMAD Framework](../README.md)

---

## � Documentation Détaillée (Deep Dive)

Cette section contient les analyses exhaustives des composants clés du projet :

### 📄 [Documentation Complète des Scripts bin/](bin-scripts-detailed.md)
**44 scripts analysés** - Utilitaires système, monitoring, automatisation, cloud

### 📄 [Documentation Exhaustive setup.sh](setup-sh-detailed.md)
**107 fonctions d'installation documentées** - Script d'installation complet Ubuntu/Debian

### 📄 [Analyse des Dépendances setup.sh](setup-dependencies.md)
**Graphe de dépendances des 107 fonctions** - Analyse des dépendances entre fonctions, ordre d'exécution optimal, problèmes détectés et recommandations

### 📄 [Configuration Zsh Complète (.zshrc)](zshrc-detailed.md)
**243 lignes analysées (refactorisée)** - Oh-My-Zsh, Powerlevel10k, 22 plugins, configuration multi-plateforme (Debian/macOS) avec sections OS clairement séparées

### 📄 [Aliases et Fonctions Shell (.aliases)](aliases-detailed.md)
**63 aliases et fonctions** - Raccourcis système, Docker, Git, réseau, monitoring, téléchargements

### 📄 [Configuration Vim Complète (.vimrc)](vimrc-detailed.md)
**386 lignes, 35+ plugins** - Vundle, deoplete, vim-go, Syntastic, NERDTree, support multi-langages (Python, Go, JS/JSX, Terraform, Markdown)

### 📄 [Configuration Tmux (.tmux.conf)](tmux-detailed.md)
**297 lignes, 5 plugins TPM** - Prefix Ctrl+F, navigation F1-F8, synchronisation panes, tmux-resurrect, thème Catppuccin

---

## 🔧 Workflow de développement

### Gestion des branches

Le projet utilise un workflow Git multi-branches pour gérer les configurations spécifiques aux OS :

```
main (production)
  ↑
develop (intégration)
  ↑         ↑
debian    macos
```

**Branches principales :**
- **`main`** : Branche stable de production
- **`develop`** : Branche de développement et d'intégration
- **`debian`** : Configuration spécifique Debian/Ubuntu
- **`macos`** : Configuration spécifique macOS

**Workflow de merge :**

```bash
# Merge toutes les branches automatiquement
make merge-branches

# Ou manuellement
config checkout develop
config merge debian -m "chore: merge debian into develop"
config merge macos -m "chore: merge macos into develop"
config checkout main
config merge develop -m "chore: merge develop into main"

# Synchroniser avec origin
make sync
```

### Alias Git personnalisé

```bash
alias config='git --git-dir=$HOME/dotfiles --work-tree=$HOME'
```

Cet alias permet de gérer les dotfiles comme un dépôt Git bare, avec le répertoire de travail dans `$HOME`.

---

## 📝 Notes de développement

### Pattern détecté : Deep Dive Analysis

Cette documentation a été générée via un **Deep Dive** qui :
- ✅ Scanne la structure complète des répertoires
- ✅ Analyse le contenu détaillé de tous les fichiers de configuration
- ✅ Détecte et documente les dépendances entre composants
- ✅ Identifie les problèmes et propose des améliorations
- ✅ Génère des analyses exhaustives (7 documents détaillés)
- ✅ Refactorise le code pour améliorer la maintenabilité

**Documents générés :**
1. setup-sh-detailed.md (107 fonctions)
2. bin-scripts-detailed.md (44 scripts)
3. zshrc-detailed.md (243 lignes)
4. aliases-detailed.md (63 aliases/fonctions)
5. vimrc-detailed.md (386 lignes, 35+ plugins)
6. tmux-detailed.md (297 lignes, 5 plugins)
7. setup-dependencies.md (graphe de dépendances)

**Améliorations appliquées :**
- ✅ Refactorisation .zshrc : sections OS séparées et clairement documentées
- ✅ Corrections setup.sh : décommenté Setup, Python, GO, Docker ; inversé GnomeExtensions/GnomeConfigurations
- ✅ Makefile : automatisation complète (bootstrap, install, merge-branches, sync)
- ✅ README.md : instructions Quick Start avec Make

---

## 🎯 Prochaines étapes suggérées

1. **Tests automatisés** : Ajouter tests pour setup.sh et scripts critiques
2. **CI/CD** : Automatiser validation syntaxe et tests sur push
3. **Documentation BMAD** : Compléter docs des workflows custom
4. **Monitoring** : Logger les installations pour détecter les échecs
5. **Modularisation setup.sh** : Créer des méta-fonctions (DevEnvironment, ContainerStack, DesktopEnvironment)

---

*Documentation générée automatiquement par BMAD Document Project Workflow*  
*Version : 1.2.0 | Mode : Deep Dive | Date : 14 janvier 2026*

