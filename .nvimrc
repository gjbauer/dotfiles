
set number
set shell=/bin/sh
set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

Plugin 'ibhagwan/fzf-lua'
Plugin 'nvim-tree/nvim-web-devicons'

call vundle#end()
filetype plugin indent on    " required
