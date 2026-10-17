#!/bin/sh
# Neovim + config kurulumu (Arch, Debian, Ubuntu)
#
#   curl -fsSL gokhanturk.com/nvim | sh
#   wget -qO- gokhanturk.com/nvim | sh
#
# Neovim paket yöneticisinden kurulur; deponun sürümü 0.12'den eskiyse
# resmi sürüm /opt/nvim'e kurulur. Tekrar çalıştırmak güvenli.
#
#   NVIM_UPDATE=1        resmi sürümü yeniden indir
#   NVIM_CONFIG_SRC=dir  config'i GitHub yerine yerel klasörden al
set -eu

REPO=GokhanTurk/dotfiles
BRANCH=main
MIN_MINOR=12

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31mHATA:\033[0m %s\n' "$*" >&2; exit 1; }
has() { command -v "$1" >/dev/null 2>&1; }

fetch() {
  if has curl; then curl -fsSL "$1"
  elif has wget; then wget -qO- "$1"
  else die "curl veya wget gerekli"
  fi
}

# "0.12.1" / "0.9.5-6ubuntu2" / "1:0.10.0-1" -> minor; 1.x ve üstü 99
minor_of() {
  printf '%s\n' "$1" | sed -n 's/^\([0-9]*:\)\{0,1\}v\{0,1\}\([0-9]*\)\.\([0-9]*\).*/\2 \3/p' |
    { read -r major minor || exit 0; [ "$major" -ge 1 ] && echo 99 || echo "$minor"; }
}

nvim_ok() {
  has nvim || return 1
  m=$(minor_of "$(nvim --version 2>/dev/null | sed -n '1s/^NVIM //p')")
  [ -n "$m" ] && [ "$m" -ge "$MIN_MINOR" ]
}

[ "$(uname -s)" = Linux ] || die "sadece Linux"
[ -r /etc/os-release ] || die "/etc/os-release yok, dağıtım tanınamadı"

if [ "$(id -u)" -eq 0 ]; then SUDO=
elif has sudo; then SUDO=sudo
else die "root veya sudo gerekli"
fi

ID= ID_LIKE=
. /etc/os-release
case " $ID $ID_LIKE " in
  *" arch "*) DISTRO=arch ;;
  *" debian "* | *" ubuntu "*) DISTRO=debian ;;
  *) die "desteklenmeyen dağıtım: $ID" ;;
esac

CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/nvim
STATE_DIR=${XDG_STATE_HOME:-$HOME/.local/state}/nvim
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# --- Paketler ---------------------------------------------------------------
# Resmi sürümü /opt/nvim'e kurar
install_release() {
  case $(uname -m) in
    x86_64 | amd64) arch=x86_64 ;;
    aarch64 | arm64) arch=arm64 ;;
    *) die "desteklenmeyen mimari: $(uname -m)" ;;
  esac
  info "Neovim resmi sürümü indiriliyor ($arch)"
  fetch "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$arch.tar.gz" |
    tar xz -C "$TMP"
  "$TMP/nvim-linux-$arch/bin/nvim" --version >/dev/null 2>&1 ||
    die "indirilen nvim çalışmadı (glibc: $(ldd --version 2>/dev/null | head -1))"
  $SUDO rm -rf /opt/nvim
  $SUDO mv "$TMP/nvim-linux-$arch" /opt/nvim
  $SUDO ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
}

case $DISTRO in
  arch)
    # -Sy yok: kısmi güncelleme yapmamak için
    info "pacman: neovim git ripgrep"
    $SUDO pacman -S --needed --noconfirm neovim git ripgrep ||
      die "pacman başarısız; önce 'sudo pacman -Syu' dene"
    ;;
  debian)
    apt_get() { $SUDO env DEBIAN_FRONTEND=noninteractive apt-get -y -qq "$@"; }
    info "apt: git ripgrep"
    apt_get update
    apt_get install --no-install-recommends ca-certificates git ripgrep

    candidate=$(apt-cache policy neovim | sed -n 's/^ *Candidate: //p')
    m=$(minor_of "$candidate")
    if [ -n "$m" ] && [ "$m" -ge "$MIN_MINOR" ]; then
      info "apt: neovim $candidate"
      apt_get install --no-install-recommends neovim
    elif [ "${NVIM_UPDATE:-0}" = 1 ] || ! nvim_ok; then
      warn "Depodaki neovim eski (${candidate:-yok}), resmi sürüm kurulacak"
      install_release
    fi
    ;;
esac

hash -r 2>/dev/null || true
nvim_ok || die "nvim 0.$MIN_MINOR+ kurulamadı"
info "$(nvim --version | head -1)"

# --- Config -----------------------------------------------------------------
MARKER=.install-nvim # config bu scriptle kurulduysa var

[ -L "$CONFIG_DIR" ] && die "$CONFIG_DIR symlink (stow?), dokunulmadı"
if [ -e "$CONFIG_DIR" ] && [ ! -e "$CONFIG_DIR/$MARKER" ]; then
  bak=$CONFIG_DIR.bak.$(date +%Y%m%d-%H%M%S)
  warn "Mevcut config yedeklendi: $bak"
  mv "$CONFIG_DIR" "$bak"
fi

mkdir -p "$TMP/cfg"
if [ -n "${NVIM_CONFIG_SRC:-}" ]; then
  cp -R "$NVIM_CONFIG_SRC/." "$TMP/cfg/"
else
  info "Config indiriliyor ($REPO@$BRANCH)"
  fetch "https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH" |
    tar xz -C "$TMP/cfg" --strip-components=4 "dotfiles-$BRANCH/nvim/.config/nvim"
fi
[ -f "$TMP/cfg/init.lua" ] || die "config indirilemedi"
touch "$TMP/cfg/$MARKER"
rm -rf "$CONFIG_DIR"
mkdir -p "$(dirname "$CONFIG_DIR")"
mv "$TMP/cfg" "$CONFIG_DIR"
info "Config: $CONFIG_DIR"

# --- Plugin'ler -------------------------------------------------------------
info "Plugin'ler lockfile sürümleriyle kuruluyor"
rm -f "$STATE_DIR/nopack"
nvim --headless \
  -c "lua vim.pack.update(nil, { force = true, offline = true, target = 'lockfile' })" \
  -c 'qa' >/dev/null 2>&1 || warn "Plugin kurulumu başarısız, sade modda çalışır (:PackRetry)"

info "Hazır."
