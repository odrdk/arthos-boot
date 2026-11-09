#!/usr/bin/env bash
# Tira o rEFInd, põe o GRUB primeiro na ordem de boot e reaplica o tema gênese.
# Uso: sudo bash arruma-boot.sh      (log em ~/arruma-boot.log)
set -uo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo: sudo bash arruma-boot.sh"; exit 1; }

USUARIO=${SUDO_USER:-arthos}
CASA=$(getent passwd "$USUARIO" | cut -d: -f6)
LOG="$CASA/arruma-boot.log"
exec > >(tee "$LOG") 2>&1
ok()   { printf '  [ok]   %s\n' "$*"; }
aviso(){ printf '  [!!]   %s\n' "$*"; }
passo(){ printf '\n== %s\n' "$*"; }

passo "1. rEFInd"
pacman -Q refind &>/dev/null && { pacman -Rns --noconfirm refind >/dev/null && ok "pacote refind removido"; }
# efibootmgr: "Boot0003* rEFInd Boot Manager	HD(...)"
mapfile -t entradas < <(efibootmgr | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\)\*\{0,1\} \(.*rEFInd.*\)$/\1/p')
if (( ${#entradas[@]} )); then
  for n in "${entradas[@]}"; do
    linha=$(efibootmgr | grep "^Boot$n")
    efibootmgr -b "$n" -B >/dev/null && ok "entrada apagada: ${linha%%$'\t'*}"
  done
else
  ok "nenhuma entrada do rEFInd na BIOS"
fi
for d in /efi/EFI/refind /boot/efi/EFI/refind; do
  [[ -d $d ]] && rm -rf "$d" && ok "pasta apagada: $d"
done
[[ -f /boot/refind_linux.conf ]] && rm -f /boot/refind_linux.conf && ok "apagado /boot/refind_linux.conf"

passo "2. Ordem de boot"
grub=$(efibootmgr | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\)\*\{0,1\} GRUB.*/\1/p' | head -1)
win=$(efibootmgr | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\)\*\{0,1\} Windows Boot Manager.*/\1/p' | head -1)
if [[ -z $grub ]]; then
  aviso "sem entrada GRUB na BIOS; recriando"
  grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --recheck >/dev/null \
    && grub=$(efibootmgr | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\)\*\{0,1\} GRUB.*/\1/p' | head -1)
fi
if [[ -n $grub ]]; then
  resto=$(efibootmgr | sed -n 's/^BootOrder: //p' | tr ',' '\n' | grep -vix -e "$grub" -e "${win:-XXXX}" | paste -sd,)
  ordem=$grub${win:+,$win}${resto:+,$resto}
  efibootmgr -o "$ordem" >/dev/null && ok "ordem: GRUB ($grub) primeiro${win:+, Windows ($win) em seguida}"
else
  aviso "não consegui achar nem recriar o GRUB na BIOS"
fi

passo "3. Tema gênese"
imagem="$CASA/Documents/Arthur-OS/00-inbox/maos.png"
script="$CASA/tema-boot.sh"
curl -fsSL https://raw.githubusercontent.com/odrdk/dotfiles/main/tema-boot.sh -o "$script" && ok "tema-boot.sh baixado"
if [[ -f $imagem ]]; then
  if FUNDO="$imagem" LOGO=arch LOGO_CENTRO=990,549 bash "$script" > "$CASA/tema-boot.log" 2>&1; then
    ok "tema aplicado com as mãos e o logo"
  else
    aviso "tema-boot.sh falhou; últimas linhas:"; tail -5 "$CASA/tema-boot.log" | sed 's/^/         /'
  fi
else
  aviso "imagem não encontrada em $imagem; aplicando o tema padrão (arte do Neovim)"
  bash "$script" > "$CASA/tema-boot.log" 2>&1 && ok "tema padrão aplicado" \
    || { aviso "tema-boot.sh falhou; últimas linhas:"; tail -5 "$CASA/tema-boot.log" | sed 's/^/         /'; }
fi

# Garante modo gráfico e menu visível (sem isso o GRUB pode abrir em texto puro e ignorar o tema).
def() { if grep -q "^#\?$1=" /etc/default/grub; then sed -i "s|^#\?$1=.*|$1=$2|" /etc/default/grub; else echo "$1=$2" >> /etc/default/grub; fi; }
def GRUB_TERMINAL_OUTPUT gfxterm
def GRUB_GFXMODE auto
def GRUB_TIMEOUT_STYLE menu
grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 && ok "grub.cfg regerado"

passo "4. Conferência (mande foto desta parte)"
tema=$(sed -n 's/^GRUB_THEME=//p' /etc/default/grub | tr -d '"')
[[ -f $tema ]] && ok "tema existe: $tema" || aviso "arquivo do tema não existe: ${tema:-GRUB_THEME vazio}"
[[ -f $(dirname "${tema:-/x}")/fundo.png ]] && ok "fundo.png gerado" || aviso "fundo.png ausente"
grep -q "set theme=" /boot/grub/grub.cfg && ok "grub.cfg carrega o tema" || aviso "grub.cfg não carrega o tema"
grep -q "terminal_output gfxterm" /boot/grub/grub.cfg && ok "grub.cfg em modo gráfico" || aviso "grub.cfg sem gfxterm"
efibootmgr | grep -iq refind && aviso "ainda há rEFInd na BIOS" || ok "rEFInd fora da BIOS"
efibootmgr | sed -n 's/^BootOrder: /  ordem de boot: /p'
printf '\nLog completo: %s\nSe tudo estiver [ok], rode: reboot\n' "$LOG"
