--           ▄▄  ▄▄
--  ██████╗  ██████╗ ██╗  ██╗██╗  ██╗ █████╗ ███╗   ██╗
-- ██╔════╝ ██╔═══██╗██║ ██╔╝██║  ██║██╔══██╗████╗  ██║
-- ██║  ███╗██║   ██║█████╔╝ ███████║███████║██╔██╗ ██║
-- ██║   ██║██║   ██║██╔═██╗ ██╔══██║██╔══██║██║╚██╗██║
-- ╚██████╔╝╚██████╔╝██║  ██╗██║  ██║██║  ██║██║ ╚████║
--  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
--
-- Neovim 0.12+ · vim.pack · catppuccin + mini.nvim

vim.loader.enable()

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Seçenekler
local o = vim.opt

o.number = true
o.relativenumber = true
o.mouse = 'a'
o.showmode = false
o.signcolumn = 'yes'
o.cursorline = true
o.scrolloff = 8
o.sidescrolloff = 8
o.wrap = false
o.splitright = true
o.splitbelow = true
o.winborder = 'rounded'
o.winbar = ' ' -- üstte boşluk

o.ignorecase = true
o.smartcase = true
o.inccommand = 'split'

o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.smartindent = true
o.breakindent = true

o.undofile = true
o.swapfile = false
o.updatetime = 250
o.timeoutlen = 400
o.confirm = true

o.list = true
o.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Dahili autocomplete
o.autocomplete = true
o.completeopt = { 'menuone', 'noselect', 'popup' }
o.pumheight = 10

-- Pano: lokalde sistem, SSH'ta OSC 52
vim.schedule(function()
  if vim.env.SSH_TTY then
    local osc52 = require('vim.ui.clipboard.osc52')
    -- yapıştırma nvim register'ından
    local function paste() return { vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('') } end
    vim.g.clipboard = {
      name = 'OSC 52',
      copy = { ['+'] = osc52.copy('+'), ['*'] = osc52.copy('*') },
      paste = { ['+'] = paste, ['*'] = paste },
    }
  end
  vim.o.clipboard = 'unnamedplus'
end)

-- Plugin'ler (vim.pack); kurulum başarısızsa bir daha denenmez, :PackRetry
local nopack = vim.fn.stdpath('state') .. '/nopack'
local has_plugins = false

if vim.fn.executable('git') == 1 and not vim.uv.fs_stat(nopack) then
  has_plugins = pcall(vim.pack.add, {
    { src = 'https://github.com/catppuccin/nvim', name = 'catppuccin' },
    'https://github.com/nvim-mini/mini.nvim',
  }, { confirm = false })
  if not has_plugins then
    vim.fn.mkdir(vim.fn.stdpath('state'), 'p')
    vim.fn.writefile({}, nopack)
    vim.notify('Plugin kurulumu başarısız, sade modda devam. Tekrar: :PackRetry', vim.log.levels.WARN)
  end
end

vim.api.nvim_create_user_command('PackRetry', function()
  vim.fn.delete(nopack)
  vim.notify('Neovim\'i yeniden aç, plugin kurulumu tekrar denenecek.')
end, { desc = 'Plugin kurulumunu tekrar dene' })

-- sudo'suz açılmış dosyayı sudo ile kaydet
vim.api.nvim_create_user_command('SudoWrite', function()
  local path = vim.fn.expand('%:p')
  local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  if vim.bo.eol or vim.bo.fixeol then text = text .. '\n' end
  local pw = ''
  if vim.system({ 'sudo', '-n', 'true' }):wait().code ~= 0 then
    pw = vim.fn.inputsecret('sudo şifresi: ') .. '\n'
  end
  local r = vim.system({ 'sudo', '-S', '-p', '', 'tee', path }, { stdin = pw .. text, stdout = false }):wait()
  if r.code ~= 0 then
    vim.notify('Kaydedilemedi: ' .. vim.trim(r.stderr or ''), vim.log.levels.ERROR)
    return
  end
  vim.bo.modified = false
  vim.bo.readonly = false
  vim.notify('Kaydedildi (sudo): ' .. path)
end, { desc = 'Dosyayı sudo ile kaydet' })

vim.api.nvim_create_user_command('PackUpdate', function()
  vim.pack.update() -- onay: :w
end, { desc = 'Plugin\'leri güncelle' })

-- Tema
if has_plugins then
  require('catppuccin').setup({
    flavour = 'mocha',
    integrations = { mini = { enabled = true } },
  })
end
-- Satır numaraları okunaklı olsun (relativenumber ile zıplarken)
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    vim.api.nvim_set_hl(0, 'LineNr', { fg = '#a6adc8' })
    vim.api.nvim_set_hl(0, 'LineNrAbove', { fg = '#a6adc8' })
    vim.api.nvim_set_hl(0, 'LineNrBelow', { fg = '#a6adc8' })
    vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#fab387', bold = true })
  end,
})
-- plugin yoksa dahili catppuccin
vim.cmd.colorscheme(has_plugins and 'catppuccin-mocha' or 'catppuccin')

-- mini.nvim
if has_plugins then
  require('mini.icons').setup()
  require('mini.statusline').setup()

  -- Tuş ipuçları
  local clue = require('mini.clue')
  clue.setup({
    triggers = {
      { mode = 'n', keys = '<Leader>' },
      { mode = 'x', keys = '<Leader>' },
      { mode = 'n', keys = 'g' },
      { mode = 'x', keys = 'g' },
      { mode = 'n', keys = 'z' },
      { mode = 'x', keys = 'z' },
      { mode = 'n', keys = '[' },
      { mode = 'n', keys = ']' },
      { mode = 'n', keys = '<C-w>' },
      { mode = 'n', keys = '"' },
      { mode = 'n', keys = "'" },
      { mode = 'n', keys = '`' },
      { mode = 'i', keys = '<C-r>' },
    },
    clues = {
      { mode = 'n', keys = '<Leader>f', desc = '+Bul' },
      clue.gen_clues.builtin_completion(),
      clue.gen_clues.g(),
      clue.gen_clues.marks(),
      clue.gen_clues.registers(),
      clue.gen_clues.windows(),
      clue.gen_clues.z(),
    },
    window = { delay = 300 },
  })

  -- Dosya gezgini
  require('mini.files').setup({
    windows = { preview = true, width_focus = 30, width_nofocus = 20, width_preview = 40 },
  })
  -- Gezgini sağa yasla
  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniFilesWindowUpdate',
    callback = function(args)
      local state = MiniFiles.get_explorer_state()
      if not state then return end
      local widths, idx = {}, nil
      for i, w in ipairs(state.windows) do
        widths[i] = vim.api.nvim_win_get_width(w.win_id) + 2 -- kenarlık
        if w.win_id == args.data.win_id then idx = i end
      end
      if not idx then return end
      local col = vim.o.columns
      for i = #widths, idx, -1 do col = col - widths[i] end
      local config = vim.api.nvim_win_get_config(args.data.win_id)
      config.col = math.max(col, 0)
      vim.api.nvim_win_set_config(args.data.win_id, config)
    end,
  })

  -- Fuzzy finder
  require('mini.pick').setup()
  require('mini.extra').setup()
end

-- Dosya bul (gizli + symlink dahil), Ctrl-k: üst klasör
local function pick_files(dir, query)
  dir = vim.fs.normalize(dir or vim.fn.getcwd())
  local cmd = vim.fn.executable('rg') == 1
      and { 'rg', '--files', '--hidden', '--follow', '--color=never', '--glob', '!.git' }
    or { 'find', '-L', '.', '-type', 'f', '-not', '-path', '*/.git/*' }
  if query then vim.schedule(function() MiniPick.set_picker_query(query) end) end
  MiniPick.builtin.cli({ command = cmd }, {
    source = {
      name = 'Dosyalar: ' .. vim.fn.fnamemodify(dir, ':~') .. '  (Ctrl-k: üst klasör)',
      cwd = dir,
      show = function(buf, items, q) MiniPick.default_show(buf, items, q, { show_icons = true }) end,
    },
    mappings = {
      up = {
        char = '<C-k>',
        func = function()
          local parent = vim.fs.dirname(dir)
          if parent == dir then return end
          local q = MiniPick.get_picker_query()
          vim.schedule(function() pick_files(parent, q) end)
          return true
        end,
      },
    },
  })
end

-- Kısayollar
local map = vim.keymap.set

if has_plugins then
  map('n', '<leader>e', function()
    if not MiniFiles.close() then MiniFiles.open(vim.api.nvim_buf_get_name(0), false) end
  end, { desc = 'Dosya gezgini (bu dosyanın klasörü)' })
  map('n', '<leader>E', function() MiniFiles.open() end, { desc = 'Dosya gezgini (çalışma dizini)' })

  map('n', '<leader>ff', function() pick_files() end, { desc = 'Dosya bul' })
  map('n', '<leader>fg', '<cmd>Pick grep_live<cr>', { desc = 'Metin ara (grep)' })
  map('n', '<leader>fr', '<cmd>Pick oldfiles<cr>', { desc = 'Son açılan dosyalar' })
  map('n', '<leader>fb', '<cmd>Pick buffers<cr>', { desc = 'Açık dosyalar (buffer)' })
  map('n', '<leader>fh', '<cmd>Pick help<cr>', { desc = 'Neovim yardımı' })
  map('n', '<leader>fk', '<cmd>Pick keymaps<cr>', { desc = 'Kısayollar' })
  map('n', '<leader><leader>', function() pick_files() end, { desc = 'Dosya bul' })
else
  -- plugin'siz: netrw + :find
  map('n', '<leader>e', '<cmd>Lexplore %:p:h<cr>', { desc = 'Dosya gezgini (netrw)' })
  map('n', '<leader>ff', ':find **/*', { desc = 'Dosya bul' })
  map('n', '<leader><leader>', ':find **/*', { desc = 'Dosya bul' })
  map('n', '<leader>fb', ':buffer ', { desc = 'Açık dosyalar' })
end

map('n', '<leader>w', '<cmd>write<cr>', { desc = 'Kaydet' })
map('n', '<leader>q', '<cmd>quit<cr>', { desc = 'Pencereyi kapat' })
map('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Arama vurgusunu kaldır' })

map('n', '<C-h>', '<C-w>h', { desc = 'Sol pencere' })
map('n', '<C-j>', '<C-w>j', { desc = 'Alt pencere' })
map('n', '<C-k>', '<C-w>k', { desc = 'Üst pencere' })
map('n', '<C-l>', '<C-w>l', { desc = 'Sağ pencere' })

map('x', 'J', ":m '>+1<cr>gv=gv", { desc = 'Seçimi aşağı taşı' })
map('x', 'K', ":m '<-2<cr>gv=gv", { desc = 'Seçimi yukarı taşı' })
map('x', '<', '<gv')
map('x', '>', '>gv')

-- Autocmd'ler
local au = vim.api.nvim_create_autocmd

au('TextYankPost', { callback = function() vim.hl.on_yank() end })

-- Son konuma dön
au('BufReadPost', {
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local lines = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= lines and vim.bo[args.buf].filetype ~= 'gitcommit' then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

au('VimResized', { command = 'wincmd =' })
