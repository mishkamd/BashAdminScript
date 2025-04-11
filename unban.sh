#!/bin/bash
sudo fail2ban-client status sshd
sudo fail2ban-client status bind9-dos
echo "=== Fail2Ban Unban Script ==="
read -p "Introdu IP-ul pe care vrei să-l deblochezi: " IP

# Obține jail-urile active
jails=$(fail2ban-client status | grep "Jail list:" | cut -d':' -f2 | tr -d ' ' | tr ',' '\n')

found_in=()

# Verifică fiecare jail dacă IP-ul este blocat
echo "Caut IP-ul $IP în jail-urile active..."
for jail in $jails; do
    banned=$(fail2ban-client status "$jail" | grep -E "Banned IP list" | grep -o "$IP")
    if [[ "$banned" == "$IP" ]]; then
        found_in+=("$jail")
    fi
done

if [[ ${#found_in[@]} -eq 0 ]]; then
    echo "⚠️  IP-ul $IP nu este blocat în niciun jail."
    exit 1
fi

echo "✅ IP-ul $IP este blocat în următoarele jail-uri:"
for i in "${!found_in[@]}"; do
    echo " [$((i+1))] ${found_in[$i]}"
done
echo " [0] Deblochează din toate jail-urile de mai sus"

read -p "Alege o opțiune (0 pentru toate / 1-n pentru unul): " opt

if [[ "$opt" == "0" ]]; then
    for jail in "${found_in[@]}"; do
        echo "➡️  Deblochez $IP din $jail..."
        fail2ban-client set "$jail" unbanip "$IP"
    done
    echo "✔️  Deblocat din toate jail-urile."
else
    index=$((opt-1))
    if [[ $index -ge 0 && $index -lt ${#found_in[@]} ]]; then
        jail=${found_in[$index]}
        echo "➡️  Deblochez $IP din $jail..."
        fail2ban-client set "$jail" unbanip "$IP"
        echo "✔️  Deblocat din $jail."
    else
        echo "❌ Opțiune invalidă."
        exit 1
    fi
fi
