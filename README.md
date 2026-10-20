<div align="center">

<img src=".github/demo.gif" alt="GÖKHAN dotfiles" width="720">

<br>

![Arch](https://img.shields.io/badge/Arch-1e1e2e?style=for-the-badge&logo=archlinux&logoColor=89b4fa) ![Debian](https://img.shields.io/badge/Debian-1e1e2e?style=for-the-badge&logo=debian&logoColor=f38ba8) ![Ubuntu](https://img.shields.io/badge/Ubuntu-1e1e2e?style=for-the-badge&logo=ubuntu&logoColor=fab387) ![Neovim](https://img.shields.io/badge/Neovim_0.12-1e1e2e?style=for-the-badge&logo=neovim&logoColor=a6e3a1) ![Catppuccin](https://img.shields.io/badge/Catppuccin_Mocha-1e1e2e?style=for-the-badge&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PGNpcmNsZSBjeD0iMTIiIGN5PSIxMiIgcj0iMTAiIGZpbGw9IiNjYmE2ZjciLz48L3N2Zz4=)

</div>

## Kurulum

```sh
curl -fsSL gokhanturk.com/dotfiles | sh
```

Sadece bazı paketler:

```sh
curl -fsSL gokhanturk.com/dotfiles | sh -s -- fish tmux
```

| Değişken       | Ne yapar                                              |
| -------------- | ----------------------------------------------------- |
| `DOTFILES_DIR` | Klon yeri (varsayılan `~/dotfiles`)                   |
| `PKGS=1`       | `pkglist.txt`'deki paketleri kurar (Arch)             |
| `WALLPAPERS=1` | [Duvar kağıtlarını](https://github.com/GokhanTurk/wallpapers) `~/wallpapers`'a klonlar |

```sh
curl -fsSL gokhanturk.com/dotfiles | PKGS=1 WALLPAPERS=1 sh
```

## İçerik

| Paket       | Hedef                         |                                         |
| ----------- | ----------------------------- | --------------------------------------- |
| `alacritty` | `~/.config/alacritty`         | Terminal, FiraCode Nerd Font            |
| `bat`       | `~/.config/bat`               | `cat` yerine                            |
| `fastfetch` | `~/.config/fastfetch`         | Sistem bilgisi                          |
| `fish`      | `~/.config/fish`              | Shell, kısaltmalar, `myip`              |
| `hushlogin` | `~/.hushlogin`                | SSH girişindeki MOTD'yi sustur          |
| `nvim`      | `~/.config/nvim`              | vim.pack + catppuccin + mini.nvim       |
| `starship`  | `~/.config/starship.toml`     | Prompt                                  |
| `tmux`      | `~/.config/tmux`              | Terminal çoklayıcı                      |

Her şey Catppuccin Mocha.

## Stow nasıl çalışıyor

Her klasör bir paket, içi `$HOME` ile aynı yapıda:

```
~/dotfiles/
└── fish/
    └── .config/
        └── fish/                         stow fish
            └── config.fish  ◀──────────────────────────  ~/.config/fish/config.fish
```

```sh
cd ~/dotfiles
stow fish          # bağla
stow -R fish       # yeniden bağla (yeni dosya eklendiyse)
stow -D fish       # kaldır
```

## Neovim

Sadece Neovim:

```sh
curl -fsSL gokhanturk.com/nvim | sh
```

Neovim 0.12+, `vim.pack`, catppuccin + mini.nvim. Plugin sürümleri `nvim-pack-lock.json`'da sabit.

### `v` kısayolu ve varsayılan editör

Alias'lar shell'in interaktif dosyasına, `EDITOR` ise her oturumda yüklenen ortam dosyasına yazılır.
Tekrar çalıştırmak güvenli, satır zaten varsa eklenmez.

**bash** (alias → `~/.bash_aliases`, ortam → `~/.profile`)

```sh
grep -qxF "alias v='nvim'" ~/.bash_aliases 2>/dev/null || echo "alias v='nvim'" >> ~/.bash_aliases
grep -qF 'sudo() {' ~/.bash_aliases 2>/dev/null || echo 'sudo() { if [ "$1" = v ]; then shift; command sudo -e "$@"; else command sudo "$@"; fi; }' >> ~/.bash_aliases
grep -qxF 'export EDITOR=nvim' ~/.profile 2>/dev/null || printf 'export EDITOR=nvim\nexport VISUAL=nvim\n' >> ~/.profile
```

**zsh** (alias → `~/.zshrc`, ortam → `~/.zshenv`)

```sh
grep -qxF "alias v='nvim'" ~/.zshrc 2>/dev/null || echo "alias v='nvim'" >> ~/.zshrc
grep -qF 'sudo() {' ~/.zshrc 2>/dev/null || echo 'sudo() { if [ "$1" = v ]; then shift; command sudo -e "$@"; else command sudo "$@"; fi; }' >> ~/.zshrc
grep -qxF 'export EDITOR=nvim' ~/.zshenv 2>/dev/null || printf 'export EDITOR=nvim\nexport VISUAL=nvim\n' >> ~/.zshenv
```

**fish** için gerekmez, `fish` paketinde zaten var.

`sudo v dosya`, `sudo -e dosya` (sudoedit) olarak çalışır: dosya root yetkisiyle kaydedilir ama nvim kendi ayarlarınla açılır.

Alias hemen geçerli olsun diye yeni bir shell aç. `EDITOR` için oturumu kapatıp tekrar gir.
`~/.bash_aliases`'ı Debian/Ubuntu'nun varsayılan `~/.bashrc`'si yükler.

| Tuş            | Ne yapar                         |
| -------------- | -------------------------------- |
| `Space Space`  | Dosya bul (`Ctrl-k` üst klasör)  |
| `Space fg`     | Metin ara                        |
| `Space fr`     | Son açılanlar                    |
| `Space fb`     | Açık buffer'lar                  |
| `Space e`      | Dosya gezgini                    |
| `Space w / q`  | Kaydet / kapat                   |
| `Ctrl-hjkl`    | Pencereler arası geç             |
| `J / K`        | Seçimi taşı (görsel mod)         |

Tüm kısayolları görmek için `Space`'e basıp bekle, sağ alt köşede bir menü açılır.

<br>

<div align="center">
  <a href="https://gokhanturk.com"><img src=".github/icon.svg" width="16" align="absmiddle" alt=">_"> gokhanturk.com</a>
</div>
