lua << EOF
require'nvim-treesitter.install'.compilers = { "gcc" }
require'nvim-treesitter.configs'.setup {
  ensure_installed = "go",
}
EOF
" Quit Neovim after installation
autocmd VimEnter * quit
