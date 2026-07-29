# Makefile pour la gestion des dotfiles
# Projet: dotfiles multi-OS (Debian/Ubuntu et macOS)
# Auteur: Daffy
# Date: 14 janvier 2026

.PHONY: help bootstrap install merge-branches merge sync clean check-syntax

# Variables
SHELL := /bin/bash
# Détection automatique : si on est dans un dépôt git normal, utiliser git directement
# sinon utiliser l'alias du bare repository
ifneq ($(wildcard .git),)
	CONFIG_ALIAS := git
else
	CONFIG_ALIAS := git --git-dir=$(HOME)/dotfiles --work-tree=$(HOME)
endif
SETUP_SCRIPT := ./setup.sh

# Couleurs pour les messages
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

##@ Aide

help: ## Affiche cette aide
	@echo ""
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)   Makefile de gestion des dotfiles$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""

##@ Installation et Bootstrap

bootstrap: ## 🚀 Configure un nouvel ordinateur (clone dotfiles, installe config)
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)   Bootstrap d'un nouvel ordinateur$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Étape 1/4:$(NC) Vérification de Git..."
	@if ! command -v git &> /dev/null; then \
		echo "$(RED)✗ Git n'est pas installé. Installation...$(NC)"; \
		sudo apt update && sudo apt install -y git || (echo "$(RED)✗ Échec de l'installation de Git$(NC)" && exit 1); \
	else \
		echo "$(GREEN)✓ Git est installé$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)Étape 2/4:$(NC) Clone du dépôt dotfiles (bare repository)..."
	@if [ -d "$(HOME)/dotfiles" ]; then \
		echo "$(YELLOW)⚠ Le dépôt existe déjà dans ~/dotfiles$(NC)"; \
	else \
		git clone --bare git@github.com:DaffyDuke/dotfiles.git $(HOME)/dotfiles && \
		echo "$(GREEN)✓ Dépôt cloné$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)Étape 3/4:$(NC) Configuration de l'alias 'config'..."
	@mkdir -p $(HOME)/.config/zsh || true
	@if ! grep -q "alias config=" $(HOME)/.zshrc 2>/dev/null; then \
		echo "alias config='git --git-dir=\$$HOME/dotfiles --work-tree=\$$HOME'" >> $(HOME)/.zshrc && \
		echo "$(GREEN)✓ Alias ajouté à ~/.zshrc$(NC)"; \
	else \
		echo "$(GREEN)✓ Alias déjà configuré$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)Étape 4/4:$(NC) Checkout des fichiers de configuration..."
	@$(CONFIG_ALIAS) config --local status.showUntrackedFiles no
	@$(CONFIG_ALIAS) checkout || ( \
		echo "$(YELLOW)⚠ Conflit détecté avec des fichiers existants$(NC)"; \
		echo "$(YELLOW)Sauvegarde des fichiers existants dans ~/.dotfiles-backup$(NC)"; \
		mkdir -p $(HOME)/.dotfiles-backup; \
		$(CONFIG_ALIAS) checkout 2>&1 | grep -E "\s+\." | awk '{print $$1}' | xargs -I{} mv {} $(HOME)/.dotfiles-backup/{}; \
		$(CONFIG_ALIAS) checkout \
	)
	@echo ""
	@echo "$(GREEN)════════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)✓ Bootstrap terminé avec succès !$(NC)"
	@echo "$(GREEN)════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(BLUE)Prochaines étapes:$(NC)"
	@echo "  1. Rechargez votre shell: $(YELLOW)source ~/.zshrc$(NC)"
	@echo "  2. Installez les logiciels: $(YELLOW)make install$(NC)"
	@echo "  3. Vérifiez la syntaxe: $(YELLOW)make check-syntax$(NC)"
	@echo ""

install: check-syntax ## 📦 Exécute le script d'installation (setup.sh Main)
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)   Installation des logiciels et configurations$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@if [ ! -f "$(SETUP_SCRIPT)" ]; then \
		echo "$(RED)✗ setup.sh introuvable$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Exécution de setup.sh...$(NC)"
	@bash $(SETUP_SCRIPT)
	@echo ""
	@echo "$(GREEN)✓ Installation terminée$(NC)"

##@ Gestion de versions et branches

merge-branches: ## 🔀 Merge: penguin→develop, debian→develop, macos→develop, develop→main (PR), puis main→toutes
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)   Merge des branches$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Vérification de l'état du dépôt...$(NC)"
	@if $(CONFIG_ALIAS) diff-index --quiet HEAD --; then \
		echo "$(GREEN)✓ Aucun changement non commité$(NC)"; \
	else \
		echo "$(RED)✗ Vous avez des changements non commités$(NC)"; \
		echo "$(YELLOW)Veuillez les commiter ou les stasher avant de continuer$(NC)"; \
		exit 1; \
	fi
	@echo ""
	@echo "$(BLUE)Phase 1: Consolidation vers develop$(NC)"
	@echo "$(YELLOW)Étape 1/9:$(NC) Merge penguin → develop..."
	@$(CONFIG_ALIAS) checkout develop || (echo "$(RED)✗ Échec du checkout develop$(NC)" && exit 1)
	@$(CONFIG_ALIAS) merge --no-ff penguin -m "chore: merge penguin into develop" && \
		echo "$(GREEN)✓ penguin → develop$(NC)" || \
		(echo "$(RED)✗ Conflit lors du merge penguin → develop$(NC)" && exit 1)
	@echo ""
	@echo "$(YELLOW)Étape 2/9:$(NC) Merge debian → develop..."
	@$(CONFIG_ALIAS) merge --no-ff debian -m "chore: merge debian into develop" && \
		echo "$(GREEN)✓ debian → develop$(NC)" || \
		(echo "$(RED)✗ Conflit lors du merge debian → develop$(NC)" && exit 1)
	@echo ""
	@echo "$(YELLOW)Étape 3/9:$(NC) Merge macos → develop..."
	@$(CONFIG_ALIAS) merge --no-ff macos -m "chore: merge macos into develop" && \
		echo "$(GREEN)✓ macos → develop$(NC)" || \
		(echo "$(RED)✗ Conflit lors du merge macos → develop$(NC)" && exit 1)
	@echo ""
	@echo "$(YELLOW)Étape 4/9:$(NC) Push des branches..."
	@$(CONFIG_ALIAS) push origin develop penguin debian macos && \
		echo "$(GREEN)✓ Branches poussées$(NC)" || \
		echo "$(RED)✗ Échec du push$(NC)"
	@echo ""
	@echo "$(BLUE)Phase 2: Merge vers main via PR$(NC)"
	@echo "$(YELLOW)Étape 5/9:$(NC) Création d'une Pull Request develop → main avec auto-merge..."
	@if command -v gh &> /dev/null; then \
		$(CONFIG_ALIAS) checkout develop && \
		gh pr create --base main --head develop --title "chore: merge develop into main" \
			--body "Merge automatique de develop vers main via Makefile" --fill 2>/dev/null && \
		gh pr merge --auto --squash 2>/dev/null && \
		echo "$(GREEN)✓ Pull Request créée avec auto-merge activé$(NC)" || \
		(echo "$(YELLOW)⚠ PR déjà existante ou erreur, vérifiez manuellement$(NC)"; \
		 echo "$(BLUE)URL:$(NC) https://github.com/DaffyDuke/dotfiles/compare/main...develop"); \
	else \
		echo "$(YELLOW)⚠ GitHub CLI (gh) non installé$(NC)"; \
		echo "$(BLUE)Créez manuellement la PR:$(NC) https://github.com/DaffyDuke/dotfiles/compare/main...develop"; \
	fi
	@echo ""
	@echo "$(GREEN)════════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)✓ Phase 1 & 2 terminées ! Attendez le merge de la PR...$(NC)"
	@echo "$(GREEN)════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(BLUE)Prochaines étapes:$(NC)"
	@echo "  1. La PR sera automatiquement mergée une fois les checks passés"
	@echo "  2. Puis exécutez: $(YELLOW)make sync-main$(NC) pour synchroniser main vers toutes les branches"

sync-main: ## 🔄 Synchronise main vers develop, debian, macos et penguin
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)   Synchronisation de main vers toutes les branches$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(BLUE)Phase 3: Distribution depuis main$(NC)"
	@echo "$(YELLOW)Étape 6/9:$(NC) Récupération de main..."
	@$(CONFIG_ALIAS) checkout main && $(CONFIG_ALIAS) pull origin main && \
		echo "$(GREEN)✓ main à jour$(NC)" || \
		(echo "$(RED)✗ Échec de la mise à jour de main$(NC)" && exit 1)
	@echo ""
	@echo "$(YELLOW)Étape 7/9:$(NC) Merge main → develop..."
	@$(CONFIG_ALIAS) checkout develop && $(CONFIG_ALIAS) pull --rebase=false origin develop && \
		$(CONFIG_ALIAS) merge main -m "chore: sync main into develop" && \
		echo "$(GREEN)✓ main → develop$(NC)" || \
		(echo "$(RED)✗ Conflit lors du merge main → develop$(NC)" && exit 1)
	@$(CONFIG_ALIAS) push origin develop
	@echo ""
	@echo "$(YELLOW)Étape 7/9:$(NC) Merge main → debian..."
	@$(CONFIG_ALIAS) checkout debian && $(CONFIG_ALIAS) pull --rebase=false origin debian && \
		$(CONFIG_ALIAS) merge main -m "chore: sync main into debian" && \
		echo "$(GREEN)✓ main → debian$(NC)" || \
		(echo "$(RED)✗ Conflit lors du merge main → debian$(NC)" && exit 1)
	@$(CONFIG_ALIAS) push origin debian
	@echo ""
	@echo "$(YELLOW)Étape 8/9:$(NC) Merge main → macos..."
	@$(CONFIG_ALIAS) checkout macos && $(CONFIG_ALIAS) pull --rebase=false origin macos && \
		$(CONFIG_ALIAS) merge main -m "chore: sync main into macos" && \
		echo "$(GREEN)✓ main → macos$(NC)" || \
		(echo "$(RED)✗ Conflit lors du merge main → macos$(NC)" && exit 1)
	@$(CONFIG_ALIAS) push origin macos
	@echo ""
	@echo "$(YELLOW)Étape 9/9:$(NC) Merge main → penguin..."
	@$(CONFIG_ALIAS) checkout penguin && $(CONFIG_ALIAS) pull --rebase=false origin penguin && \
		$(CONFIG_ALIAS) merge main -m "chore: sync main into penguin" && \
		echo "$(GREEN)✓ main → penguin$(NC)" || \
		(echo "$(RED)✗ Conflit lors du merge main → penguin$(NC)" && exit 1)
	@$(CONFIG_ALIAS) push origin penguin
	@echo ""
	@echo "$(GREEN)════════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)✓ Toutes les branches sont synchronisées avec main !$(NC)"
	@echo "$(GREEN)════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@$(CONFIG_ALIAS) checkout main
	@echo "$(BLUE)Branches actuelles:$(NC)"
	@$(CONFIG_ALIAS) branch -vv

merge: merge-branches ## Alias pour merge-branches

sync: ## 📤 Push toutes les branches vers origin
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)   Synchronisation avec origin$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Push de toutes les branches...$(NC)"
	@$(CONFIG_ALIAS) push origin main develop debian macos penguin && \
		echo "$(GREEN)✓ Toutes les branches ont été poussées$(NC)" || \
		echo "$(RED)✗ Échec du push$(NC)"
	@echo ""

##@ Validation et maintenance

check-syntax: ## ✅ Vérifie la syntaxe de setup.sh et .zshrc
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)   Vérification de la syntaxe$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Vérification de setup.sh...$(NC)"
	@if bash -n $(SETUP_SCRIPT) 2>/dev/null; then \
		echo "$(GREEN)✓ setup.sh est syntaxiquement correct$(NC)"; \
	else \
		echo "$(RED)✗ Erreur de syntaxe dans setup.sh$(NC)"; \
		bash -n $(SETUP_SCRIPT); \
		exit 1; \
	fi
	@echo ""
	@echo "$(YELLOW)Vérification de .zshrc...$(NC)"
	@if [ -f "$(HOME)/.zshrc" ]; then \
		if zsh -n $(HOME)/.zshrc 2>/dev/null; then \
			echo "$(GREEN)✓ .zshrc est syntaxiquement correct$(NC)"; \
		else \
			echo "$(RED)✗ Erreur de syntaxe dans .zshrc$(NC)"; \
			zsh -n $(HOME)/.zshrc; \
			exit 1; \
		fi \
	else \
		echo "$(YELLOW)⚠ .zshrc introuvable$(NC)"; \
	fi
	@echo ""
	@echo "$(GREEN)✓ Toutes les vérifications sont passées$(NC)"

clean: ## 🧹 Nettoie les fichiers temporaires
	@echo "$(YELLOW)Nettoyage des fichiers temporaires...$(NC)"
	@rm -rf $(HOME)/.dotfiles-backup/
	@echo "$(GREEN)✓ Nettoyage terminé$(NC)"

##@ Documentation

docs-update: ## 📚 Met à jour l'index de documentation
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)   Mise à jour de la documentation$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Mise à jour de docs/index.md...$(NC)"
	@if [ -f "docs/index.md" ]; then \
		echo "$(GREEN)✓ Documentation trouvée$(NC)"; \
		echo "Fichiers de documentation disponibles:"; \
		ls -1 docs/*.md | sed 's/^/  - /'; \
	else \
		echo "$(RED)✗ docs/index.md introuvable$(NC)"; \
	fi
	@echo ""

##@ Informations

status: ## 📊 Affiche l'état du dépôt dotfiles
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)   État du dépôt dotfiles$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@$(CONFIG_ALIAS) status

diff: ## 📝 Affiche les différences non commitées
	@$(CONFIG_ALIAS) diff

log: ## 📜 Affiche l'historique des commits
	@$(CONFIG_ALIAS) log --oneline --graph --decorate --all -20

branches: ## 🌳 Affiche toutes les branches
	@echo "$(BLUE)Branches locales:$(NC)"
	@$(CONFIG_ALIAS) branch -vv
	@echo ""
	@echo "$(BLUE)Branches distantes:$(NC)"
	@$(CONFIG_ALIAS) branch -r

##@ Raccourcis Git

commit: ## 💾 Commit avec commitizen (interactif)
	@echo "$(YELLOW)Utilisation de commitizen pour le commit...$(NC)"
	@$(CONFIG_ALIAS) cz commit

add: ## ➕ Ajoute un fichier au staging (usage: make add FILE=.zshrc)
	@if [ -z "$(FILE)" ]; then \
		echo "$(RED)✗ Usage: make add FILE=chemin/vers/fichier$(NC)"; \
		exit 1; \
	fi
	@$(CONFIG_ALIAS) add $(FILE)
	@echo "$(GREEN)✓ $(FILE) ajouté au staging$(NC)"

pull: ## ⬇️  Pull depuis origin
	@$(CONFIG_ALIAS) pull

push: ## ⬆️  Push vers origin
	@$(CONFIG_ALIAS) push
