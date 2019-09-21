if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" For Neovim 0.1.3 and 0.1.4 - https://github.com/neovim/neovim/pull/2198
if (has('nvim'))
  let $NVIM_TUI_ENABLE_TRUE_COLOR = 1
endif

" For Neovim > 0.1.5 and Vim > patch 7.4.1799 - https://github.com/vim/vim/commit/61be73bb0f965a895bfb064ea3e55476ac175162
" Based on Vim patch 7.4.1770 (`guicolors` option) - https://github.com/vim/vim/commit/8a633e3427b47286869aa4b96f2bfc1fe65b25cd
" https://github.com/neovim/neovim/wiki/Following-HEAD#20160511
if (has('termguicolors'))
  set termguicolors
endif

" Fix rendering error when scrolling
if (&term =~ '^xterm' && &t_Co == 256)
  set t_ut= | set ttyscroll=1
endif

call plug#begin()
  Plug 'bling/vim-airline'
  Plug 'hzchirs/vim-material'
  Plug 'kaicataldo/material.vim'
call plug#end()

" Dark
set background=dark
let g:material_terminal_italics = 1
let g:material_theme_style = 'palenight' " 'default' | 'palenight' | 'ocean' | 'lighter' | 'darker'
colorscheme material

" Show hidden characters
set list
set tabpagemax=15               " Only show 15 tabs
set showmode                    " Display the current mode

set cursorline                  " Highlight current line

set backspace=indent,eol,start  " Backspace for dummies
set linespace=0                 " No extra spaces between rows
set number                      " Line numbers on
set showmatch                   " Show matching brackets/parenthesis
set incsearch                   " Find as you type search
set hlsearch                    " Highlight search terms
set winminheight=0              " Windows can be 0 line high
set ignorecase                  " Case insensitive search
set smartcase                   " Case sensitive when uc present
set wildmenu                    " Show list instead of just completing
set wildmode=list:longest,full  " Command <Tab> completion, list matches, then longest common part, then all.
set wildignore=*\\tmp\\*,*.swp,*.zip,*.exe,node_modules,bower_components,.git
set whichwrap=b,s,h,l,<,>,[,]   " Backspace and cursor keys wrap too
set scrolljump=5                " Lines to scroll when cursor leaves screen
set scrolloff=3                 " Minimum lines to keep above and below cursor
"set foldenable                 " Auto fold code
set nofoldenable
set list
set listchars=tab:»\ ,trail:·,extends:#,nbsp:. ",eol:¬  Highlight problematic whitespace

filetype plugin indent on       " Automatically detect file types.
syntax on                       " Syntax highlighting
set mouse=a                     " Automatically enable mouse usage
set mousehide                   " Hide the mouse cursor while typing
scriptencoding utf-8
set encoding=utf-8
set termencoding=utf-8
"set fileencoding=utf-8

"set shortmess+=filmnrxoOtT     " Abbrev. of messages (avoids 'hit enter')
"set viewoptions=folds,options,cursor,unix,slash " Better Unix / Windows compatibility
set virtualedit=onemore         " Allow for cursor beyond last character
set history=1000                " Store a ton of history (default is 20)
"set spell                      " Spell checking on
set hidden                      " Allow buffer switching without saving

set nowrap                      " Do not wrap long lines
set autoindent                  " Indent at the same level of the previous line
set shiftwidth=4                " Use indents of 4 spaces
"set expandtab                  " Tabs are spaces, not tabs
set tabstop=4                   " An indentation every four columns
set softtabstop=4               " Let backspace delete indent
set nojoinspaces                " Prevents inserting two spaces after punctuation on a join (J)
set splitright                  " Puts new vsplit windows to the right of the current
set splitbelow                  " Puts new split windows to the bottom of the current
"set matchpairs+=<:>            " Match, to be used with %
set pastetoggle=<F12>           " pastetoggle (sane indentation on pastes)

" Key remapps
let mapleader = ','

" map control-backspace to delete the previous word
imap <C-BS> <C-W>
nmap <silent> <leader>ev :e $MYVIMRC<CR>
nmap <silent> <leader>rv :so $MYVIMRC<CR>

let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#fnamemod = ':t'
let g:airline_powerline_fonts = 1
