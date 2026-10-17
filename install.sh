#!/bin/sh
# Dotfiles kurulumu (Arch, Debian, Ubuntu)
#
#   curl -fsSL gokhanturk.com/dotfiles | sh
#   curl -fsSL gokhanturk.com/dotfiles | sh -s -- fish tmux nvim   # sadece bunlar
#
# Repoyu klonlar (varsa günceller), çakışan dosyaları yedekler, stow'lar.
# Tekrar çalıştırmak güvenli.
#
#   DOTFILES_DIR=dir  klon yeri (varsayılan ~/dotfiles)
#   WALLPAPERS=1      duvar kağıtlarını ~/wallpapers'a klonla (~570 MB)
#   PKGS=1            pkglist.txt'yi kur (sadece Arch)
set -eu

REPO=https://github.com/GokhanTurk/dotfiles.git
WALLPAPERS_REPO=https://github.com/GokhanTurk/wallpapers.git
DIR=${DOTFILES_DIR:-$HOME/dotfiles}
BACKUP=$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)

if [ -t 1 ]; then
  B='\033[1;34m' Y='\033[1;33m' R='\033[1;31m' G='\033[1;32m' D='\033[2m' N='\033[0m'
else
  B= Y= R= G= D= N=
fi
info() { printf "${B}==>${N} %s\n" "$*"; }
warn() { printf "${Y}==>${N} %s\n" "$*" >&2; }
die() { printf "${R}HATA:${N} %s\n" "$*" >&2; exit 1; }
has() { command -v "$1" >/dev/null 2>&1; }

banner() {
  [ -t 1 ] || return 0
  i=0
  for c in '203;166;247' '245;194;231' '243;139;168' '250;179;135' '249;226;175' '166;227;161' '148;226;213'; do
    i=$((i + 1))
    printf '\033[1;38;2;%sm' "$c"
    case $i in
      1) echo '           ▄▄  ▄▄' ;;
      2) echo ' ██████╗  ██████╗ ██╗  ██╗██╗  ██╗ █████╗ ███╗   ██╗' ;;
      3) echo '██╔════╝ ██╔═══██╗██║ ██╔╝██║  ██║██╔══██╗████╗  ██║' ;;
      4) echo '██║  ███╗██║   ██║█████╔╝ ███████║███████║██╔██╗ ██║' ;;
      5) echo '██║   ██║██║   ██║██╔═██╗ ██╔══██║██╔══██║██║╚██╗██║' ;;
      6) echo '╚██████╔╝╚██████╔╝██║  ██╗██║  ██║██║  ██║██║ ╚████║' ;;
      7) echo ' ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝' ;;
    esac
  done
  printf "${N}${D}%s${N}\n\n" '                                            dotfiles'
}

banner

[ "$(uname -s)" = Linux ] || die "sadece Linux"
[ -r /etc/os-release ] || die "/etc/os-release yok, dağıtım tanınamadı"

ID= ID_LIKE= PRETTY_NAME=
. /etc/os-release
case " $ID $ID_LIKE " in
  *" arch "*) DISTRO=arch ;;
  *" debian "* | *" ubuntu "*) DISTRO=debian ;;
  *) die "desteklenmeyen dağıtım: $ID" ;;
esac

if [ "$(id -u)" -eq 0 ]; then SUDO=
elif has sudo; then SUDO=sudo
else SUDO=false
fi

# --- git + stow -------------------------------------------------------------
if ! has git || ! has stow; then
  [ "$SUDO" = false ] && die "git ve stow gerekli (root/sudo yok)"
  info "$PRETTY_NAME: git stow kuruluyor"
  case $DISTRO in
    arch) $SUDO pacman -S --needed --noconfirm git stow ;;
    debian)
      $SUDO env DEBIAN_FRONTEND=noninteractive apt-get -qq update
      $SUDO env DEBIAN_FRONTEND=noninteractive apt-get -y -qq install --no-install-recommends ca-certificates git stow
      ;;
  esac
fi

# --- Repo -------------------------------------------------------------------
# clone_or_pull URL DIR
clone_or_pull() {
  if [ -d "$2/.git" ]; then
    info "Güncelleniyor: $2"
    git -C "$2" pull -q --ff-only || warn "git pull başarısız, mevcut haliyle devam"
  elif [ -e "$2" ]; then
    die "$2 var ama git reposu değil"
  else
    info "Klonlanıyor: $2"
    git clone -q --depth 1 "$1" "$2"
  fi
}

clone_or_pull "$REPO" "$DIR"
[ "${WALLPAPERS:-0}" = 1 ] && clone_or_pull "$WALLPAPERS_REPO" "$HOME/wallpapers"

# --- Paket listesi ----------------------------------------------------------
if [ "${PKGS:-0}" = 1 ]; then
  if [ "$DISTRO" = arch ] && [ "$SUDO" != false ]; then
    info "pacman: pkglist.txt"
    grep -v '^\s*\(#\|$\)' "$DIR/pkglist.txt" | $SUDO pacman -S --needed --noconfirm -
  else
    warn "PKGS=1 sadece Arch'ta, atlandı"
  fi
fi

# --- Stow -------------------------------------------------------------------
if [ $# -eq 0 ]; then
  set -- $(cd "$DIR" && for d in */; do echo "${d%/}"; done)
fi

for pkg; do
  [ -d "$DIR/$pkg" ] || die "paket yok: $pkg"
done

# Stow'un üzerine yazamayacağı dosyaları yedekle
for pkg; do
  (cd "$DIR/$pkg" && find . -type f -o -type l) | while IFS= read -r rel; do
    rel=${rel#./}
    t=$HOME/$rel
    [ -e "$t" ] || [ -L "$t" ] || continue
    [ "$(readlink -f "$t")" = "$(readlink -f "$DIR/$pkg/$rel")" ] && continue
    mkdir -p "$BACKUP/$(dirname "$rel")"
    mv "$t" "$BACKUP/$rel"
    warn "Yedeklendi: ~/$rel"
  done
done

stow -d "$DIR" -t "$HOME" --restow "$@"
for pkg; do printf "  ${G}✓${N} %s\n" "$pkg"; done

[ -d "$BACKUP" ] && info "Eski dosyalar: $BACKUP"
info "Hazır."
