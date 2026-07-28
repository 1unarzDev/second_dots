-- FIX: Auto-create undo directory to prevent E828 error
local undodir = vim.fn.stdpath("state") .. "/undo"
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
vim.opt.undodir = undodir
vim.opt.undofile = true

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.clipboard = 'unnamedplus'
vim.opt.breakindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.signcolumn = 'yes'

-- Leaders must be set BEFORE lazy.nvim loads
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Tab configuration
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.keymap.set("n", "<Tab>", ">>",  { silent = true })
vim.keymap.set("n", "<S-Tab>", "<<",  { silent = true })
vim.keymap.set("v", "<Tab>", ">gv", { silent = true })
vim.keymap.set("v", "<S-Tab>", "<gv", { silent = true })
vim.keymap.set("i", "<Tab>", "<C-t>", { silent = true })
vim.keymap.set("i", "<S-Tab>", "<C-d>", { silent = true })

-- ==========================================================================
-- PLUGIN MANAGER (LAZY.NVIM) BOOTSTRAP
-- ==========================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
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

-- Define all plugins required by this configuration
local not_vscode = function() return not vim.g.vscode end

require("lazy").setup({
  {
    "atdma/caelestia-nvim",
    priority = 1000,
    lazy = false,
    cond = not_vscode,
    opts = {},
    config = function(_, opts)
      require("caelestia").setup(opts)
      vim.cmd.colorscheme("caelestia")
    end,
  },
  { "nvim-lualine/lualine.nvim", cond = not_vscode },
  "nvim-tree/nvim-web-devicons",
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", cond = not_vscode },
  { "lewis6991/gitsigns.nvim", cond = not_vscode },
  "windwp/nvim-autopairs",
  "numToStr/Comment.nvim",
  { "folke/which-key.nvim", cond = not_vscode },
  { "nvim-tree/nvim-tree.lua", cond = not_vscode },
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" }, cond = not_vscode },
  { "nvim-telescope/telescope-ui-select.nvim", cond = not_vscode },
  { "akinsho/bufferline.nvim", cond = not_vscode },
  { "hrsh7th/nvim-cmp", cond = not_vscode },
  { "hrsh7th/cmp-nvim-lsp", cond = not_vscode },
  { "hrsh7th/cmp-buffer", cond = not_vscode },
  { "hrsh7th/cmp-path", cond = not_vscode },
  { "L3MON4D3/LuaSnip", cond = not_vscode },
  { "saadparwaiz1/cmp_luasnip", cond = not_vscode },
  { "rafamadriz/friendly-snippets", cond = not_vscode },
  { "neovim/nvim-lspconfig", cond = not_vscode },
  { "folke/flash.nvim", event = "VeryLazy" },
  { "goolord/alpha-nvim", cond = not_vscode },
  "NMAC427/guess-indent.nvim",
})

-- ==========================================================================
-- TRANSPARENCY (let Hyprland's blur/opacity show through Neovim)
-- ==========================================================================
local opaque_groups = {
  Visual = true, VisualNOS = true,
  Search = true, IncSearch = true, CurSearch = true, Substitute = true,
  PmenuSel = true, PmenuMatch = true, PmenuMatchSel = true,
  MatchParen = true,
  Cursor = true, lCursor = true, TermCursor = true,
  DiffAdd = true, DiffChange = true, DiffDelete = true, DiffText = true,
}

-- Keep background colors for Lualine modes/position blocks
local opaque_prefixes = {
  "^lualine_a", -- Mode section (Normal, Insert, Visual colors)
  "^lualine_b", -- Git branch / diagnostics section
  "^lualine_y", -- File type / format section
  "^lualine_z", -- Cursor position block section
}

local function is_opaque(name)
  if opaque_groups[name] then return true end
  for _, pattern in ipairs(opaque_prefixes) do
    if name:match(pattern) then return true end
  end
  return false
end

local function apply_transparency()
  local groups = vim.api.nvim_get_hl(0, {})
  for name, hl in pairs(groups) do
    if hl.bg and not is_opaque(name) then
      local new_hl = vim.tbl_extend("force", {}, hl)
      new_hl.bg = nil
      pcall(vim.api.nvim_set_hl, 0, name, new_hl)
    end
  end
end

-- Reapply whenever :colorscheme runs
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "caelestia",
  callback = function()
    vim.schedule(apply_transparency)
  end,
})

-- Reload scheme watcher
do
  local uv = vim.uv or vim.loop
  local state_dir = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
  local caelestia_state_dir = state_dir .. "/caelestia"
  local retint_timer = uv.new_timer()
  local scheme_watcher = uv.new_fs_event()
  if scheme_watcher then
    scheme_watcher:start(caelestia_state_dir, {}, vim.schedule_wrap(function(err, filename)
      if not err and filename == "scheme.json" then
        retint_timer:stop()
        retint_timer:start(300, 0, vim.schedule_wrap(apply_transparency))
      end
    end))
  end
end

-- ==========================================================================
-- PLUGIN CONFIGURATIONS (Wrapped in pcall to prevent hard crashes)
-- ==========================================================================
local ok_ts, ts_configs = pcall(require, 'nvim-treesitter.configs')
if ok_ts then
  ts_configs.setup {
    highlight = { enable = true },
    indent = { enable = true },
  }
end

local ok_ibl, ibl = pcall(require, "ibl")
if ok_ibl then ibl.setup() end

local ok_git, gitsigns = pcall(require, 'gitsigns')
if ok_git then gitsigns.setup() end

local ok_pairs, autopairs = pcall(require, 'nvim-autopairs')
if ok_pairs then autopairs.setup({}) end

local ok_com, comment = pcall(require, 'Comment')
if ok_com then comment.setup() end

local ok_wk, whichkey = pcall(require, 'which-key')
if ok_wk then whichkey.setup() end

-- Configure Lualine
local ok_lualine, lualine = pcall(require, 'lualine')
if ok_lualine then
  local custom_theme = require('lualine.themes.auto')
  
  -- Clear background ONLY for middle section 'c' (the empty bar space)
  for _, mode in pairs(custom_theme) do
    if mode.c then mode.c.bg = 'NONE' end
  end

  lualine.setup {
    options = {
      theme = custom_theme,
      component_separators = { left = '│', right = '│' },
      section_separators = { left = '', right = '' },
    }
  }
end

local ok_tree, nvim_tree = pcall(require, "nvim-tree")
if ok_tree then
  nvim_tree.setup({
    filters = { dotfiles = false },
    view = { width = 30 }
  })
end
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = 'Toggle File Explorer' })

local ok_telescope, telescope = pcall(require, 'telescope')
if ok_telescope then
  telescope.setup {
    extensions = {
      ["ui-select"] = { require("telescope.themes").get_dropdown {} }
    }
  }
  pcall(telescope.load_extension, 'ui-select')

  local ok_builtin, builtin = pcall(require, 'telescope.builtin')
  if ok_builtin then
    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find Files' })
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live Grep' })
    vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find Buffers' })
  end
end

local ok_bufferline, bufferline = pcall(require, "bufferline")
if ok_bufferline then
  bufferline.setup{
    options = {
      mode = "buffers",
      diagnostics = "nvim_lsp",
      separator_style = "thin",
      indicator = {
        style = 'NONE',
      },
      offsets = {
        {
          filetype = "NvimTree",
          text = "File Explorer",
          text_align = "left",
          separator = false, -- Removes the vertical dividing line over NvimTree
        }
      },
    },
    highlights = {
      fill = { bg = "NONE" },
      background = { bg = "NONE" },
      tab = { bg = "NONE" },
      tab_selected = { bg = "NONE", bold = true },
      
      -- Prevents tab from turning gray when focusing NvimTree
      buffer_visible = { bg = "NONE" },
      buffer_selected = { bg = "NONE", bold = true, italic = false },
      
      -- Strips separator lines between tabs
      separator = { fg = "NONE", bg = "NONE" },
      separator_visible = { fg = "NONE", bg = "NONE" },
      separator_selected = { fg = "NONE", bg = "NONE" },

      indicator_selected = { bg = "NONE" },
      indicator_visible = { bg = "NONE" },
      offset_separator = { fg = "NONE", bg = "NONE" },
      
      -- Close buttons
      close_button = { bg = "NONE" },
      close_button_visible = { bg = "NONE" },
      close_button_selected = { bg = "NONE" },
      tab_close = { bg = "NONE" },
    }
  }
end

vim.keymap.set("n", "<C-h>", "<C-w>h") -- (Left)
vim.keymap.set("n", "<C-j>", "<C-w>j") -- (Up)
vim.keymap.set("n", "<C-k>", "<C-w>k") -- (Down)
vim.keymap.set("n", "<C-l>", "<C-w>l") -- (Right)
vim.keymap.set("n", "<leader>bn", "<cmd>BufferLineCycleNext<CR>")
vim.keymap.set("n", "<leader>bp", "<cmd>BufferLineCyclePrev<CR>")
vim.keymap.set("n", "<leader>x", ":bdelete<CR>", { silent = true, desc = "Close Buffer" })

local ok_cmp, cmp = pcall(require, 'cmp')
local ok_luasnip, luasnip = pcall(require, 'luasnip')
if ok_cmp and ok_luasnip then
  pcall(function() require("luasnip.loaders.from_vscode").lazy_load() end)

  cmp.setup {
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert {
      ['<C-n>'] = cmp.mapping.select_next_item(),
      ['<C-p>'] = cmp.mapping.select_prev_item(),
      ['<C-d>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<CR>'] = cmp.mapping.confirm {
        behavior = cmp.ConfirmBehavior.Replace,
        select = true,
      },
      ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { 'i', 's' }),
    },
    sources = {
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
      { name = 'buffer' },
      { name = 'path' },
    },
  }
end

local ok_flash, flash = pcall(require, "flash")
if ok_flash then
  flash.setup({})
  vim.keymap.set({ "n", "x", "o" }, "s", function() flash.jump() end, { desc = "Flash Jump" })
  vim.keymap.set({ "n", "x", "o" }, "S", function() flash.treesitter() end, { desc = "Flash Treesitter" })
  vim.keymap.set("c", "<C-s>", function() flash.toggle() end, { desc = "Flash Search Toggle" })
end

local ok_alpha, alpha = pcall(require, "alpha")
if ok_alpha then
  local dashboard = require("alpha.themes.dashboard")

  dashboard.section.header.val = {
    [[                                                                       ]],
    [[                                                                     ]],
    [[       ████ ██████           █████      ██                     ]],
    [[      ███████████             █████                             ]],
    [[      █████████ ███████████████████ ███   ███████████   ]],
    [[     █████████  ███    █████████████ █████ ██████████████   ]],
    [[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
    [[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
    [[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
    [[                                                                       ]],
  }
  
  dashboard.section.buttons.val = {
    dashboard.button("f", "  Find File",    "<cmd>Telescope find_files<CR>"),
    dashboard.button("r", "  Recent Files", "<cmd>Telescope oldfiles<CR>"),
    dashboard.button("g", "  Live Grep",    "<cmd>Telescope live_grep<CR>"),
    dashboard.button("n", "  New File",     "<cmd>ene <BAR> startinsert<CR>"),
    dashboard.button("q", "  Quit",         "<cmd>qa<CR>"),
  }

  alpha.setup(dashboard.config)
end

local ok_guess, guess_indent = pcall(require, "guess-indent")
if ok_guess then
  guess_indent.setup({
    auto_cmd = true,
  })
end

-- ==========================================================================
-- LSP NATIVE SETUP
-- ==========================================================================
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp_lsp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
if ok_cmp_lsp then
  capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end

vim.lsp.config('*', { capabilities = capabilities })

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
})

vim.lsp.enable({ "pyright", "nil_ls", "lua_ls" })

-- Apply initial transparency pass
apply_transparency()
