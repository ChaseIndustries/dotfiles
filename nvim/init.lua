-- Minimal Neovim config. Its main job is to power the editor pane in
-- herdr-deck (https://github.com/ctbaum/herdr-deck) via herdr-agents.nvim,
-- which keeps Claude/Codex connected to Neovim inside Herdr-managed decks.
-- Day-to-day editing still happens in Cursor.

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "

local inside_herdr = vim.env.HERDR_SOCKET_PATH and vim.env.HERDR_SOCKET_PATH ~= ""

require("lazy").setup({
  {
    "ctbaum/herdr-agents.nvim",
    cond = inside_herdr,
    lazy = false,
    dependencies = {
      { "coder/claudecode.nvim", dependencies = { "folke/snacks.nvim" } },
      { "ishiooon/codex.nvim", dependencies = { "folke/snacks.nvim" } },
    },
    opts = {},
  },
})

vim.opt.number = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.termguicolors = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
