#!/usr/bin/env bash
# Diagnóstico do boot numa tela só: tire uma foto e mande.
# Uso: sudo bash diag-boot.sh
[[ $EUID -eq 0 ]] || { echo "Rode com sudo: sudo bash diag-boot.sh"; exit 1; }
CASA=$(getent passwd "${SUDO_USER:-arthos}" | cut -d: -f6)
t() { printf '\n## %s\n' "$*"; }

t "pacotes"
pacman -Q grub neofetch imagemagick python 2>&1 | paste -sd' '
t "tema em /boot/grub/themes"
for d in /boot/grub/themes/*/; do printf '%s: %s\n' "$d" "$(ls "$d" | paste -sd' ' | cut -c1-110)"; done 2>/dev/null || echo "(nenhum)"
t "/etc/default/grub"
grep -E '^GRUB_(THEME|GFXMODE|GFXPAYLOAD|TERMINAL|TIMEOUT|DISABLE_OS|FONT)' /etc/default/grub
t "grub.cfg (tema e vídeo)"
grep -nE 'set theme=|terminal_output|loadfont|gfxmode' /boot/grub/grub.cfg | head -8
t "quem cria as entradas BootNext"
for f in $(grep -l 'BootNext' /etc/grub.d/* 2>/dev/null); do
  echo "$f"; grep -oE 'GRUB_[A-Z_]+' "$f" | sort -u | paste -sd' '
done
t "fim do log do tema"
tail -12 "$CASA/tema-boot.log" 2>/dev/null || echo "(sem tema-boot.log: o tema não foi aplicado)"
t "theme.txt (primeiras linhas do menu)"
tema=$(sed -n 's/^GRUB_THEME=//p' /etc/default/grub | tr -d '"')
[[ -f $tema ]] && grep -nE 'font|desktop-image|boot_menu' "$tema" | head -8 || echo "(não existe: $tema)"
