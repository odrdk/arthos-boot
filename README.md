# arthos-boot

Scripts do boot do Arch (Arthos-PC).

- `arruma-boot.sh`: tira o rEFInd, põe o GRUB primeiro e reaplica o tema gênese. Mostra um resumo no fim.
- `tema-boot.sh`: tema do GRUB em ASCII (cópia; a fonte é odrdk/dotfiles).

No Arch, uma vez só: `sudo pacman -S --needed github-cli && gh auth login`.
Depois: `gh repo clone odrdk/arthos-boot && sudo bash arthos-boot/arruma-boot.sh`.
