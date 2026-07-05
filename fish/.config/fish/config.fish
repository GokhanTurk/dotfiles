function source_if_exists
    if test -f $argv[1]
	source $argv[1]
    end
end

source_if_exists /usr/share/cachyos-fish-config/*

if command -q zoxide
    zoxide init fish | source
end

set -gx TERMINAL "alacritty -e"

abbr -a cls clear
abbr -a ff fastfetch
