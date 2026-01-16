import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Dotfiles Documentation',
  description: 'Documentation pour la configuration de mon environnement de développement',
  
  themeConfig: {
    nav: [
      { text: 'Accueil', link: '/' },
      { text: 'Scripts', link: '/bin-scripts-detailed' },
      { text: 'Configuration', link: '/setup-dependencies' }
    ],

    sidebar: [
      {
        text: 'Guide',
        items: [
          { text: 'Introduction', link: '/index' },
          { text: 'Installation', link: '/setup-sh-detailed' },
          { text: 'Dépendances', link: '/setup-dependencies' }
        ]
      },
      {
        text: 'Configuration',
        items: [
          { text: 'Aliases', link: '/aliases-detailed' },
          { text: 'Tmux', link: '/tmux-detailed' },
          { text: 'Vim', link: '/vimrc-detailed' },
          { text: 'Zsh', link: '/zshrc-detailed' }
        ]
      },
      {
        text: 'Scripts',
        items: [
          { text: 'Scripts bin/', link: '/bin-scripts-detailed' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/yourusername/dotfiles' }
    ],

    footer: {
      message: 'Configuration personnelle de développement',
      copyright: 'Copyright © 2026'
    }
  }
})
