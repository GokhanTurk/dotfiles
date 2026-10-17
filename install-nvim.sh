#!/bin/sh
# Neovim + config'i herhangi bir Linux sunucusuna kurar (root gerekmez).
#
#   curl -fsSL gokhanturk.com/nvim | sh
#   wget -qO- gokhanturk.com/nvim | sh      # curl yoksa
#
# Ne yapar:
#   1. Neovim yoksa veya 0.12'den eskiyse resmi sürümü ~/.local/opt/nvim'e
#      indirir (root ise /usr/local/bin/nvim, değilse ~/.local/bin/nvim linki).
#   2. Config'i GitHub'daki dotfiles reposundan ~/.config/nvim'e kopyalar
#      (git gerekmez). Varolan farklı bir config varsa yedekler.
#   3. git varsa plugin'leri lockfile'daki sürümlerle önceden indirir.
#
# Tekrar çalıştırmak güvenli: config'i günceller, plugin'leri lockfile'a eşitler.
# Ortam değişkenleri:
#   NVIM_UPDATE=1      Neovim'i (yeni olsa bile) son sürüme güncelle
#   NVIM_CONFIG_SRC=…  Config'i GitHub yerine bu yerel klasörden al (test için)
set -eu

REPO=GokhanTurk/dotfiles
BRANCH=main
MIN_MINOR=12 # 0.12+ gerekli (vim.pack, autocomplete)

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31mHATA:\033[0m %s\n' "$*" >&2; exit 1; }

fetch() { # fetch URL -> stdout
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$1"
  else
    die "curl veya wget gerekli"
  fi
}

command -v tar >/dev/null 2>&1 || die "tar gerekli"
[ "$(uname -s)" = Linux ] || die "sadece Linux destekleniyor"

if [ "$(id -u)" -eq 0 ]; then BIN_DIR=/usr/local/bin; else BIN_DIR=$HOME/.local/bin; fi
CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/nvim
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# --- 1. Neovim ---------------------------------------------------------------
nvim_ok() {
  command -v "$1" >/dev/null 2>&1 || return 1
  minor=$("$1" --version 2>/dev/null | sed -n '1s/^NVIM v0\.\([0-9]*\).*/\1/p')
  [ -n "$minor" ] && [ "$minor" -ge "$MIN_MINOR" ]
}

NVIM=nvim
if [ "${NVIM_UPDATE:-0}" = 1 ] || ! nvim_ok nvim; then
  case $(uname -m) in
    x86_64 | amd64) ARCH=x86_64 ;;
    aarch64 | arm64) ARCH=arm64 ;;
    *) die "desteklenmeyen mimari: $(uname -m)" ;;
  esac
  info "Neovim indiriliyor ($ARCH)…"
  fetch "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$ARCH.tar.gz" | tar xz -C "$TMP"
  rm -rf "$HOME/.local/opt/nvim"
  mkdir -p "$HOME/.local/opt" "$BIN_DIR"
  mv "$TMP/nvim-linux-$ARCH" "$HOME/.local/opt/nvim"
  ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$BIN_DIR/nvim"
  NVIM=$BIN_DIR/nvim
  "$NVIM" --version >/dev/null 2>&1 ||
    die "indirilen nvim çalışmadı (glibc çok eski olabilir: $(ldd --version 2>/dev/null | head -1))"
  info "$("$NVIM" --version | head -1) → $BIN_DIR/nvim"
else
  info "$(nvim --version | head -1) zaten kurulu"
fi

# --- 2. Config ---------------------------------------------------------------
MARKER=.install-nvim # bu dosya varsa config bu scriptle kurulmuştur

if [ -L "$CONFIG_DIR" ]; then
  die "$CONFIG_DIR bir symlink (stow?) — dokunulmadı. Orada 'git pull' yap."
fi
if [ -e "$CONFIG_DIR" ] && [ ! -e "$CONFIG_DIR/$MARKER" ]; then
  BAK=$CONFIG_DIR.bak.$(date +%Y%m%d-%H%M%S)
  warn "Mevcut config yedeklendi: $BAK"
  mv "$CONFIG_DIR" "$BAK"
fi

mkdir -p "$TMP/cfg"
if [ -n "${NVIM_CONFIG_SRC:-}" ]; then
  cp -R "$NVIM_CONFIG_SRC/." "$TMP/cfg/"
else
  info "Config indiriliyor ($REPO@$BRANCH)…"
  fetch "https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH" |
    tar xz -C "$TMP/cfg" --strip-components=4 "dotfiles-$BRANCH/nvim/.config/nvim"
fi
[ -f "$TMP/cfg/init.lua" ] || die "config indirilemedi"
touch "$TMP/cfg/$MARKER"
rm -rf "$CONFIG_DIR"
mkdir -p "$(dirname "$CONFIG_DIR")"
mv "$TMP/cfg" "$CONFIG_DIR"
info "Config → $CONFIG_DIR"

# --- 3. Plugin'ler -----------------------------------------------------------
if command -v git >/dev/null 2>&1; then
  info "Plugin'ler indiriliyor…"
  rm -f "${XDG_STATE_HOME:-$HOME/.local/state}/nvim/nopack"
  # Yeni kurulumda lockfile'dakiler iner; varolanlar lockfile sürümüne eşitlenir.
  "$NVIM" --headless \
    -c "lua vim.pack.update(nil, { force = true, offline = true, target = 'lockfile' })" \
    -c 'qa' >/dev/null 2>&1 || warn "Plugin kurulumu başarısız; Neovim sade modda çalışır (:PackRetry)"
else
  warn "git yok → plugin'siz sade mod (dahili catppuccin + netrw)"
fi

# --- PATH (sadece nvim'i biz indirdiysek) -------------------------------------
[ "$NVIM" != nvim ] && case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
      [ -f "$rc" ] || continue
      grep -q 'install-nvim' "$rc" 2>/dev/null && continue
      printf '\nexport PATH="%s:$PATH" # install-nvim\n' "$BIN_DIR" >>"$rc"
    done
    warn "$BIN_DIR PATH'e eklendi; bu oturum için: export PATH=\"$BIN_DIR:\$PATH\""
    ;;
esac

info "Hazır. 'nvim' ile başla — Space'e basıp bekle, kısayollar görünür."
