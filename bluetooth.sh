#!/usr/bin/env bash
# Pareia mouse e teclado Bluetooth: liga o serviço, procura, você escolhe pelo número, ele pareia e confia.
# Uso: sudo bash bluetooth.sh
set -uo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo: sudo bash bluetooth.sh"; exit 1; }

echo ">> Preparando o Bluetooth"
pacman -S --needed --noconfirm bluez bluez-utils >/dev/null
rfkill unblock bluetooth 2>/dev/null
systemctl enable --now bluetooth.service >/dev/null 2>&1
sleep 2
bluetoothctl power on >/dev/null || { echo "Não achei adaptador Bluetooth ligado."; exit 1; }

while true; do
  echo
  echo ">> Coloque o aparelho em modo de pareamento (luz piscando) e aperte Enter"
  read -r _
  echo ">> Procurando por 20 segundos..."
  bluetoothctl --timeout 20 scan on >/dev/null 2>&1

  mapfile -t lista < <(bluetoothctl devices | sed -n 's/^Device \([0-9A-F:]\{17\}\) \(.*\)$/\1 \2/p')
  (( ${#lista[@]} )) || { echo "Nada encontrado. Confira o modo de pareamento."; continue; }
  echo
  for i in "${!lista[@]}"; do
    mac=${lista[$i]%% *}; nome=${lista[$i]#* }
    estado=$(bluetoothctl info "$mac" | grep -q 'Connected: yes' && echo ' (já conectado)')
    printf '  %2d) %s  %s%s\n' $(( i + 1 )) "$nome" "$mac" "$estado"
  done
  echo
  read -rp "Número do aparelho (Enter para sair): " n
  [[ -z $n ]] && break
  [[ $n =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#lista[@]} )) || { echo "Número inválido."; continue; }
  mac=${lista[$((n - 1))]%% *}; nome=${lista[$((n - 1))]#* }

  echo ">> Pareando $nome"
  echo "   Se aparecer 'Passkey: 123456', digite esse número NO teclado Bluetooth e aperte Enter nele."
  bluetoothctl --agent KeyboardDisplay pair "$mac"
  bluetoothctl trust "$mac" >/dev/null     # trust: reconecta sozinho nos próximos boots
  if bluetoothctl connect "$mac" | grep -q 'Connection successful'; then
    echo "   [ok] $nome conectado"
  else
    echo "   [!!] $nome não conectou; aperte uma tecla/botão no aparelho e rode de novo"
  fi

  read -rp "Parear outro aparelho? (s/N) " de_novo
  [[ $de_novo =~ ^[sS] ]] || break
done
echo ">> Pronto. Os aparelhos pareados reconectam sozinhos ao ligar."
