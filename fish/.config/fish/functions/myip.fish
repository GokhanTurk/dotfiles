function myip
    set -l eth (/usr/bin/ip -4 -br addr | awk '$1 ~ /^en/ && $3 != "" {split($3, a, "/"); print a[1]}')
    set -l wifi (/usr/bin/ip -4 -br addr | awk '$1 ~ /^wl/ && $3 != "" {split($3, a, "/"); print a[1]}')
    
    if test -n "$eth"
        echo "Ethernet: $eth"
    end
    if test -n "$wifi"
        echo "Wifi: $wifi"
    end
end
