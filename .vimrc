set nocompatible              " be iMproved, required
syntax on
filetype off                  " required
" disable Visual vim by default
set mouse-=a07

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

"
"
"vim-flake8 is a Vim plugin that runs the currently open file through Flake8, a static syntax and style checker for Python source code
Plugin 'nvie/vim-flake8'

Plugin 'fatih/vim-go'
" for javascript
" Plugin 'jelera/vim-javascript-syntax'
Plugin 'pangloss/vim-javascript'
" Plugin 'othree/javascript-libraries-syntax.vim'
Plugin 'mxw/vim-jsx'
let g:jsx_ext_required = 0 " Allow JSX in normal JS files

Plugin 'matthewsimo/angular-vim-snippets'
Plugin 'nathanaelkane/vim-indent-guides'
let g:indent_guides_enable_on_vim_startup = 1

" for json
Plugin 'elzr/vim-json'

if has('nvim')
  Plugin 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
  Plugin 'deoplete-plugins/deoplete-go', { 'do': 'make'}
  Plugin 'tenfyzhong/CompleteParameter.vim'
  Plugin 'carakan/deoplete-emoji'
else
  Plugin 'Shougo/deoplete.nvim'
  Plugin 'roxma/nvim-yarp'
  Plugin 'roxma/vim-hug-neovim-rpc'
  Plugin 'deoplete-plugins/deoplete-go', { 'do': 'make'}
  Plugin 'tenfyzhong/CompleteParameter.vim'
  Plugin 'carakan/deoplete-emoji'
endif
let g:deoplete#enable_at_startup = 1

"
Plugin 'Shougo/neosnippet'
Plugin 'Shougo/neosnippet-snippets'
Plugin 'majutsushi/tagbar'
Plugin 'nsf/gocode', {'rtp': 'vim/'}
" Plugin 'rjohnsondev/vim-compiler-go'

" for git
Plugin 'airblade/vim-gitgutter'
Plugin 'scrooloose/syntastic'
" Plugin 'vim-airline/vim-airline'
" markdown
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
Plugin 'cespare/vim-toml'

Plugin 'maksimr/vim-jsbeautify'
Plugin 'scrooloose/nerdtree'
Plugin 'Xuyuanp/nerdtree-git-plugin'
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

Plugin 'morhetz/gruvbox'

" vim as PyCharm
Plugin 'JetBrains/ideavim'
Plugin 'luochen1990/rainbow'
let g:rainbow_active = 1

Plugin 'RRethy/vim-illuminate'
hi link illuminatedWord Visual

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
Plugin 'towolf/vim-helm'
" Put your non-Plugin stuff after this line
" For indentation
set expandtab
set shiftwidth=2
set softtabstop=2
" Do not advize me... for now
let g:vim_json_syntax_conceal = 0
" let g:neocomplete#enable_at_startup = 1
nmap <F8> :TagbarToggle<CR>

"------------------------------------------------------------------------------
" General
"------------------------------------------------------------------------------
"
"------------------------------------------------------------------------------
" VIM user interface
"------------------------------------------------------------------------------

" Make sure that coursor is always vertically centered on j/k moves
set so=999

" Turn on the WiLd menu
set wildmenu

" Set command-line completion mode
set wildmode=list:longest,full

" Highlight current line - allows you to track cursor position more easily
set cursorline

" Completion options (select longest + show menu even if a single match is found)
set completeopt=longest,menuone

" Show line, column number, and relative position within a file in the status line
set ruler

" Show line numbers - could be toggled on/off on-fly by pressing F6
set number

" Show (partial) commands (or size of selection in Visual mode) in the status line
set showcmd

" Allow smarter completion by infering the case
set infercase

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

nnoremap <LEADER><SPACE> :noh<CR>
vnoremap // y/<C-R>"<CR>

" Solving git merge conflicts with VIM
" Fugitive Conflict Resolution
nnoremap <leader>gd :Gvdiff<CR>
nnoremap gdh :diffget //2<CR>
nnoremap gdl :diffget //3<CR>

" Don't redraw while executing macros (good performance config)
" set lazyredraw

" For regular expressions turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch

" How many tenths of a second to blink when matching brackets
set mat=2

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500

"------------------------------------------------------------------------------
" Status line
"------------------------------------------------------------------------------
" Always show the status line
set laststatus=2

" Format the status line
" set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l



"------------------------------------------------------------------------------
" Syntastic
"------------------------------------------------------------------------------
"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*

let g:syntastic_aggregate_errors = 1
let g:syntastic_always_populate_loc_list = 0
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0

let g:syntastic_javascript_checkers = ['eslint']

"let g:go_list_type = "quickfix"
"let g:syntastic_mode_map = { 'mode': 'active', 'passive_filetypes': ['go'] }
"" use goimports for formatting
let g:go_fmt_command = "goimports"

" turn highlighting on
"
let g:syntastic_go_checkers = ['go', 'golint', 'errcheck']
"

"------------------------------------------------------------------------------
" vim-markdown
"------------------------------------------------------------------------------

let g:vim_markdown_toc_autofit = 1
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_math = 1
let g:vim_markdown_toml_frontmatter = 1
"------------------------------------------------------------------------------
" Vim-go
"------------------------------------------------------------------------------
let g:go_fmt_fail_silently = 1
let g:go_fmt_command = "gofmt" "Explicited the formater plugin (gofmt, goimports, goreturn...)

" Show a list of interfaces which is implemented by the type under your cursor
au FileType go nmap <Leader>s <Plug>(go-implements)

" Show type info for the word under your cursor
au FileType go nmap <Leader>i <Plug>(go-info)

" Open the relevant Godoc for the word under the cursor
au FileType go nmap <Leader>gd <Plug>(go-doc)
au FileType go nmap <Leader>gv <Plug>(go-doc-vertical)

" Open the Godoc in browser
au FileType go nmap <Leader>gb <Plug>(go-doc-browser)

" " Open go doc in vertical window, horizontal, or tab
au Filetype go nnoremap <leader>v :vsp <CR>:exe "GoDef" <CR>
au Filetype go nnoremap <leader>s :sp <CR>:exe "GoDef"<CR>
au Filetype go nnoremap <leader>t :tab split <CR>:exe "GoDef"<CR>

" Run/build/test/coverage
au FileType go nmap <leader>r <Plug>(go-run)
au FileType go nmap <leader>b <Plug>(go-build)
au FileType go nmap <leader>t <Plug>(go-test)
au FileType go nmap <leader>c <Plug>(go-coverage)

" By default syntax-highlighting for Functions, Methods and Structs is disabled.
" Let's enable them!
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1

nmap <F8> :TagbarToggle<CR>
let g:tagbar_type_go = {  
    \ 'ctagstype' : 'go',
    \ 'kinds'     : [
        \ 'p:package',
        \ 'i:imports:1',
        \ 'c:constants',
        \ 'v:variables',
        \ 't:types',
        \ 'n:interfaces',
        \ 'w:fields',
        \ 'e:embedded',
        \ 'm:methods',
        \ 'r:constructor',
        \ 'f:functions'
    \ ],
    \ 'sro' : '.',
    \ 'kind2scope' : {
        \ 't' : 'ctype',
        \ 'n' : 'ntype'
    \ },
    \ 'scope2kind' : {
        \ 'ctype' : 't',
        \ 'ntype' : 'n'
    \ },
    \ 'ctagsbin'  : 'gotags',
    \ 'ctagsargs' : '-sort -silent'
\ }

" let g:golang_goroot = "$GOROOT"
" let g:syntastic_html_tidy_ignore_errors=["<ion-", "discarding unexpected </ion-", " proprietary attribute \"ng-"]

let g:syntastic_html_tidy_ignore_errors = [
    \  '<ion-', 
    \  'discarding unexpected </ion-', 
    \  ' proprietary attribute "ng-',
    \  'plain text isn''t allowed in <head> elements',
    \  '<base> escaping malformed URI reference',
    \  'discarding unexpected <body>',
    \  '<script> escaping malformed URI reference',
    \  '</head> isn''t allowed in <body> elements'
    \ ]

" Nerdtree
autocmd vimenter * NERDTree
autocmd vimenter * wincmd p
" vimscript git-nerdtree
let g:NERDTreeGitStatusIndicatorMapCustom = {
    \ "Modified"  : "✹",
    \ "Staged"    : "✚",
    \ "Untracked" : "✭",
    \ "Renamed"   : "➜",
    \ "Unmerged"  : "═",
    \ "Deleted"   : "✖",
    \ "Dirty"     : "✗",
    \ "Clean"     : "✔︎",
    \ 'Ignored'   : '☒',
    \ "Unknown"   : "?"
    \ }

set background=dark
colorscheme gruvbox
Plugin 'wakatime/vim-wakatime'
Plugin 'imain/notmuch-vim'
Plugin 'itchyny/calendar.vim'
Plugin 'google/vim-jsonnet'
" Plugin 'valloric/youcompleteme'
Plugin 'tpope/vim-unimpaired'

" Catpuccino
Plugin 'catppuccin/vim', { 'as': 'catppuccin' }

" Terraform
Plugin 'hashivim/vim-terraform'
Plugin 'juliosueiras/vim-terraform-completion'

" Deoplete config
let g:deoplete#omni_patterns = {}
let g:deoplete#omni_patterns.terraform = '[^ *\t"{=$]\w*'
let g:deoplete#enable_at_startup = 1
call deoplete#initialize()
call deoplete#custom#option('num_processes', 4)


" Syntastic Config
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" (Optional)Remove Info(Preview) window
set completeopt-=preview

" (Optional)Hide Info(Preview) window after completions
autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
autocmd InsertLeave * if pumvisible() == 0|pclose|endif

" (Optional) Enable terraform plan to be include in filter
let g:syntastic_terraform_tffilter_plan = 1

" (Optional) Default: 0, enable(1)/disable(0) plugin's keymapping
let g:terraform_completion_keys = 1

" (Optional) Default: 1, enable(1)/disable(0) terraform module registry completion
let g:terraform_registry_module_completion = 0

let g:notmuch_folders = [
      \ [ 'new', 'tag:inbox and tag:unread' ],
      \ [ 'inbox', 'tag:inbox' ],
      \ [ 'unread', 'tag:unread' ],
      \ [ 'News', 'tag:@sanenews' ],
      \ [ 'Later', 'tag:@sanelater' ],
      \ [ 'Patreon', 'tag:@patreon' ],
      \ [ 'LivestockConservancy', 'tag:livestock-conservancy' ],
    \ ]

