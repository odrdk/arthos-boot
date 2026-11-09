#!/usr/bin/env bash
# Restaura o Arthur-OS a partir do pendrive e deixa o Claude Code pronto.
# Pendrive com: arthur-os.zip, arthur-os-segredos.zip (opcional), arthos-boot.zip.
# Uso (como seu usuário, SEM sudo na frente): bash restaurar.sh
set -euo pipefail
[[ $EUID -ne 0 ]] || { echo "Rode sem sudo: bash restaurar.sh (ele pede a senha quando precisar)"; exit 1; }
ok()   { printf '  [ok] %s\n' "$*"; }
aviso(){ printf '  [!!] %s\n' "$*"; }
passo(){ printf '\n== %s\n' "$*"; }

DESTINO="$HOME/Documents/Arthur-OS"
BOOT="$HOME/arthos-boot"
MEM="$HOME/.claude/projects/-home-${USER}-Documents-Arthur-OS/memory"
PONTO=/mnt/pendrive

passo "1. Ferramentas"
sudo pacman -S --needed --noconfirm unzip exfatprogs ntfs-3g >/dev/null && ok "unzip e leitores de pendrive"

passo "2. Achar o pendrive"
achou=""
mountpoint -q "$PONTO" && sudo umount "$PONTO"
# Só partições removíveis (HOTPLUG=1): o SSD do Windows e o do Arch nunca entram aqui.
while read -r dev fs hp; do
  [[ $hp == 1 && -n $fs ]] || continue
  sudo mount --mkdir "$dev" "$PONTO" 2>/dev/null || continue
  if [[ -f $PONTO/arthur-os.zip ]]; then achou=$dev; break; fi
  sudo umount "$PONTO"
done < <(lsblk -nrpo NAME,FSTYPE,HOTPLUG)
[[ -n $achou ]] || { aviso "não achei um pendrive com arthur-os.zip; espete e rode de novo"; exit 1; }
ok "pendrive $achou montado em $PONTO"

passo "3. Arthur-OS"
if [[ -d $DESTINO && -n $(ls -A "$DESTINO" 2>/dev/null) ]]; then
  aviso "$DESTINO já existe; os arquivos do zip vão por cima (os seus que não estão no zip ficam)"
fi
mkdir -p "$DESTINO"
unzip -q -o "$PONTO/arthur-os.zip" -d "$DESTINO" && ok "Arthur-OS em $DESTINO"

if [[ -f $PONTO/arthur-os-segredos.zip ]]; then
  unzip -q -o "$PONTO/arthur-os-segredos.zip" -d "$DESTINO"
  if [[ -d $DESTINO/.cloudflared ]]; then
    mkdir -p "$HOME/.cloudflared"; cp -a "$DESTINO/.cloudflared/." "$HOME/.cloudflared/"; rm -rf "$DESTINO/.cloudflared"
  fi
  chmod 600 "$DESTINO"/60-sistema/painel/{.chave,https.local.key.pem} "$DESTINO"/60-sistema/painel/*.local.json "$HOME"/.cloudflared/* 2>/dev/null || true
  ok "segredos do painel e credencial do túnel (~/.cloudflared)"
else
  aviso "sem arthur-os-segredos.zip no pendrive; o painel não vai rodar sem ele"
fi

passo "4. Scripts do boot"
mkdir -p "$BOOT"
if [[ -f $PONTO/arthos-boot.zip ]]; then
  unzip -q -o "$PONTO/arthos-boot.zip" -d "$BOOT" && ok "scripts em $BOOT"
else
  git clone -q https://github.com/odrdk/arthos-boot "$BOOT" 2>/dev/null && ok "scripts baixados do GitHub em $BOOT" \
    || aviso "sem arthos-boot.zip e sem internet para baixar"
fi

passo "5. Memória do Claude"
if [[ -d $DESTINO/memoria-claude ]]; then
  mkdir -p "$MEM"; cp -a "$DESTINO/memoria-claude/." "$MEM/" && ok "$(ls "$MEM" | wc -l) notas em $MEM"
else
  aviso "sem memoria-claude/ no Arthur-OS"
fi

passo "6. Limpar o pendrive"
if [[ -f $PONTO/arthur-os-segredos.zip ]]; then
  sudo rm -f "$PONTO/arthur-os-segredos.zip" && ok "segredos apagados do pendrive"
fi
sudo umount "$PONTO" && ok "pendrive pode ser retirado"

passo "7. Claude Code"
if command -v claude >/dev/null || [[ -x $HOME/.local/bin/claude ]]; then
  ok "já instalado"
else
  curl -fsSL https://claude.ai/install.sh | bash >/dev/null 2>&1 && ok "instalado" || aviso "falhou; confira a internet e rode de novo"
fi
grep -q '.local/bin' "$HOME/.zshrc" "$HOME/.config/zsh/.zshrc" 2>/dev/null \
  || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${ZDOTDIR:-$HOME/.config/zsh}/.zshrc"

passo "8. sudo sem senha para o Claude (temporário)"
read -rp "  Liberar agora? Sem isso o Claude trava em comandos com sudo. (s/N) " r
if [[ $r =~ ^[sS] ]]; then
  echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/90-claude-temporario >/dev/null
  sudo chmod 440 /etc/sudoers.d/90-claude-temporario && ok "liberado; para tirar depois: sudo rm /etc/sudoers.d/90-claude-temporario"
fi

cat <<FIM

Pronto. Feche este terminal, abra outro e rode:

  cd ~/Documents/Arthur-OS && claude

Depois de entrar na conta, cole:

  Leia ~/arthos-boot/HANDOFF.md e continue o conserto do boot.
FIM
