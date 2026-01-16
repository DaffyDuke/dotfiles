# Documentation VitePress

VitePress a été installé comme alternative moderne et sécurisée à gitbook-cli.

## 🚀 Démarrage rapide

### Développement local
```bash
npm run docs:dev
```
Ouvre un serveur de développement avec rechargement à chaud sur http://localhost:5173

### Build de production
```bash
npm run docs:build
```
Génère les fichiers statiques dans `docs/.vitepress/dist/`

### Prévisualisation de production
```bash
npm run docs:preview
```
Prévisualise le build de production localement

## 📁 Structure

```
docs/
├── .vitepress/
│   └── config.js          # Configuration VitePress
├── index.md               # Page d'accueil
├── setup-sh-detailed.md
├── aliases-detailed.md
├── bin-scripts-detailed.md
└── ...                    # Autres pages de documentation
```

## 🔧 Configuration

La configuration se trouve dans `docs/.vitepress/config.js` et inclut :
- Navigation principale
- Barre latérale
- Liens sociaux
- Footer

## 📝 Écriture de documentation

VitePress utilise Markdown avec des extensions Vue. Ajoutez simplement des fichiers `.md` dans le dossier `docs/` et ils seront automatiquement accessibles.

## 🔗 Liens utiles

- [Documentation VitePress](https://vitepress.dev/)
- [Guide Markdown](https://vitepress.dev/guide/markdown)
- [Configuration](https://vitepress.dev/reference/site-config)
