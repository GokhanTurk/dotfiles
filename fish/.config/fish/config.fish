for f in /usr/share/cachyos-fish-config/*
    source $f
end

# zoxide ve starship init çıktıları statik; her açılışta üretmek yerine
# cache'le, sadece binary güncellenince yenile.
set -l cache_dir ~/.cache/fish
test -d $cache_dir; or mkdir -p $cache_dir

if command -q zoxide
    set -l f $cache_dir/zoxide.fish
    if not test -f $f; or test (command -s zoxide) -nt $f
        zoxide init fish >$f
    end
    source $f
end

if command -q starship
    set -l f $cache_dir/starship.fish
    if not test -f $f; or test (command -s starship) -nt $f
        starship init fish --print-full-init >$f
    end
    source $f
end

# Varsayılan "Welcome to fish" mesajı yerine fastfetch göster.
function fish_greeting
    if command -q fastfetch
        fastfetch
    end
end

set -gx TERMINAL "alacritty -e"

fish_add_path -g ~/.local/bin

abbr -a cls clear
abbr -a ff fastfetch

abbr -a v vim

if command -q eza
    abbr -a ls eza
    abbr -a ll 'eza -l'
end

if command -q bat
    abbr -a cat bat
end
