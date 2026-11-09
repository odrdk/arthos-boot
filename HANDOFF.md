# Handoff: boot do Arthos-PC (para o Claude rodando no Arch)

Responder em português brasileiro, direto. Usuário: Arthur, login `arthos`, máquina `arthos-pc`.

## Máquina
- Lenovo IdeaPad 330 (81FE), UEFI, Secure Boot desligado.
- Arch no SSD **MSI S270** (p1 EFI 256 MiB em `/efi`; p2 `/boot` LUKS2-PBKDF2, aberto pelo GRUB com teclado US;
  p3 `/` LUKS2-Argon2id, aberto pelo sd-encrypt; keyfile do /boot no crypttab).
- Windows no **KINGSTON SA400S37240G**. Nunca escrever nesse disco.
- GRUB 2.16, `grub-install --efi-directory=/efi --bootloader-id=GRUB` + cópia `--removable`.
- Monitores: notebook 1366x768, Philips 1920x1080 (adaptador USB SMI/evdi), LG 2560x1440.

## Objetivo
Menu do GRUB com o tema **gênese**: imagem das mãos (Criação de Adão em ASCII, preto e branco) em tela cheia,
logo do Arch (tirado do `neofetch -L --ascii_distro arch`) no vão entre os dedos, menu centralizado embaixo,
fonte JetBrains Mono, Windows no menu. Prévia aprovada em 1366/1920/2560.

- Gerador: `tema-boot.sh` (fonte: github.com/odrdk/dotfiles, cópia aqui).
- Comando: `sudo FUNDO=~/Documents/Arthur-OS/00-inbox/maos.png LOGO=arch LOGO_CENTRO=990,549 bash tema-boot.sh`
  (`LOGO_CENTRO` = ponto médio entre as pontas dos dedos, medido em escala 1920x1080).
- Saída: `/boot/grub/themes/genese/{theme.txt,fundo.png,*.pf2,select_*.png}`; `GRUB_THEME` em `/etc/default/grub`.

## Estado (08/11/2026)
- rEFInd foi instalado e removido; `arruma-boot.sh` deveria limpar entrada NVRAM e `/efi/EFI/refind`. Conferir.
- Ao ligar: o GRUB aparece no **visual padrão** (tema não carregou) e lista entradas **"(EFI BootNext)"**
  (Windows, GRUB, MSI, USB, DVD, Network), provavelmente geradas por um script novo em `/etc/grub.d` do 2.16.
- Primeiro passo: `sudo bash diag-boot.sh` e ler a saída. Depois: ver `~/tema-boot.log` e `~/arruma-boot.log`.

## Hipóteses
1. `tema-boot.sh` falhou no meio (neofetch ausente, imagem ausente no Arch, fonte JetBrains não instalada,
   magick). Ele usa `set -euo pipefail`; o `grub-mkconfig` fica no fim, então falha antes dele = sem tema.
2. `theme.txt` com erro: GRUB cai no padrão. Testar com `grub-script-check` não cobre tema; olhar nomes das
   fontes (`item_font` precisa casar com o nome gravado no .pf2) e se os .pf2 são carregados pelo grub.cfg.
3. Entradas BootNext: achar o script em `/etc/grub.d` que as cria e a variável que o desliga.

## Limites
- Não mexer em LUKS, crypttab, partições, nem no disco KINGSTON.
- Não apagar nada fora do que é do tema/rEFInd sem mostrar o caminho exato ao Arthur antes.
- Senha do /boot no GRUB: só letras/números (teclado US no GRUB).
- Mudança no GRUB: sempre `grub-mkconfig -o /boot/grub/grub.cfg` no fim; nunca deixar grub.cfg quebrado
  (testar com `grub-script-check /boot/grub/grub.cfg`).
