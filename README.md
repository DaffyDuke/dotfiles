# Credits

Forked from <https://github.com/owulveryck/dotfiles>
Adapted with <https://lord.re/posts/62-dotfiles-home-git/>
Lots of fun from <https://catonmat.net/linux-and-vim-notes>

---

## 🚀 Quick Start

### Bootstrap d'un nouvel ordinateur

Pour configurer rapidement un nouvel ordinateur avec vos dotfiles :

```bash
# Option 1 : Avec Make (recommandé)
ssh-keygen
sudo apt install -y git curl zsh make
git clone git@github.com:DaffyDuke/dotfiles.git ~/dotfiles-tmp
cd ~/dotfiles-tmp
make bootstrap
make install

# Option 2 : Manuel
ssh-keygen
sudo apt install -y git curl zsh
git clone --bare git@github.com:DaffyDuke/dotfiles.git $HOME/dotfiles
echo "alias config='git --git-dir=\$HOME/dotfiles --work-tree=\$HOME'" >> ~/.zshrc
source ~/.zshrc
config config --local status.showUntrackedFiles no
config checkout
```

### Commandes Make disponibles

```bash
make help              # Affiche l'aide complète
make bootstrap         # Configure un nouvel ordinateur
make install           # Installe tous les logiciels (setup.sh)
make check-syntax      # Vérifie la syntaxe des scripts
make merge-branches    # Merge: debian→develop, macos→develop, develop→main
make sync              # Push toutes les branches vers origin
make status            # Affiche l'état du dépôt
```

---

## 📖 Usage quotidien

### Alias de base

```bash
alias config='git --git-dir=$HOME/dotfiles --work-tree=$HOME'
```

### Exemples de commandes

```bash
# Ajouter/modifier un fichier
config add .zshrc
config commit -m 'tuning zshrc' .zshrc

# Avec commitizen (recommandé)
config cz commit

# Avec Make
make add FILE=.zshrc
make commit
```

### Gestion des branches

Le projet utilise plusieurs branches pour gérer les configurations spécifiques aux OS :

- **`main`** : Branche principale stable
- **`develop`** : Branche de développement
- **`debian`** : Configuration spécifique Debian/Ubuntu
- **`macos`** : Configuration spécifique macOS

Pour merger toutes les branches :

```bash
make merge-branches
make sync
```
