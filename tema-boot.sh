#!/usr/bin/env bash
# Tema do GRUB em ASCII. Padrão: arte do dashboard do Neovim à direita, menu à esquerda.
# Uso: sudo bash tema-boot.sh   |   sudo LOGO=arch bash tema-boot.sh   |   sudo FUNDO=imagem.png bash tema-boot.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo: sudo bash tema-boot.sh"; exit 1; }

TEMA=/boot/grub/themes/genese   # "gênese": as mãos da Criação de Adão com o Arch no ponto do toque
# Nome antigo deste mesmo script; sai para não ficar tema órfão em /boot.
[[ -f /boot/grub/themes/cohle/theme.txt ]] && rm -rf /boot/grub/themes/cohle
NOME=${NOME:-Arthos}

pacman -S --needed --noconfirm grub freetype2 fontconfig imagemagick python os-prober >/dev/null

# JetBrains Mono em tudo: menu, rodapé e arte.
mono=$(fc-match -f '%{file}' 'JetBrainsMono Nerd Font Mono:style=Regular')
texto=$mono
echo ">> Fonte: $texto"

rm -rf "$TEMA"; mkdir -p "$TEMA"
grub-mkfont -s 26 -o "$TEMA/titulo.pf2" "$texto"
grub-mkfont -s 16 -o "$TEMA/menu.pf2" "$texto"
grub-mkfont -s 12 -o "$TEMA/rodape.pf2" "$texto"

nome_pf2() { python3 - "$1" <<'PY'
import sys, struct
d = open(sys.argv[1], 'rb').read()
i = d.index(b'NAME') + 4
n = struct.unpack('>I', d[i:i+4])[0]
print(d[i+4:i+4+n].rstrip(b'\0').decode())
PY
}
ft=$(nome_pf2 "$TEMA/titulo.pf2"); fm=$(nome_pf2 "$TEMA/menu.pf2"); fr=$(nome_pf2 "$TEMA/rodape.pf2")

arte=$(cat <<'ARTE'
/#######,%%%%,,%%  %%%%(%%%**%%%%%%#%%%%/(%##(#%#%*%%%%%(%%%%#%%,#%(  /%# ###%&@
#( .*##.#%%%%%%%%%%%%%%#*,(#%(#%%/(%%.,%%#(,#/.%((%%%%,%%%%%%%%%%%%%*.(#%%%&@@@@
###/%.%%%%%%%%%%/(%%#%%%%%%%%%*./ #.%%%( .,%/./#*,(%#%#   ,%%%%%%%%%%#((%&@**&@@
(%#%%%%%%%%%%%&&%%&%%%%( .%  /( #%###%%%%#. # %* ,,#%.#*/%#/%%%%%%%%%%%&@%%&&##&
%#%%%%%%%##%%&&&&%/ %%%%%%//*#((#*%%#%.#%%%#%%%%%%/#,/**,,%.%%%%%%%#&&@#@@@@&&&&
%%%%%%%/%%#%%%&&&(*##    #(#(#(#.. . .   .%((%%%%%%%/%%*,/// %%%%&#&%&@@@@&&%%/#
% %%%%%%%%%(,&&&&/#,(%/  ./#*....,*/.,.,..... *#%%/%%./,/,  .#%%&&(*&&&&&&%%&&&@
%%%%%%%%%%%%%% *&*(% % *,,/ .,.      . ..    ...,, .%/%,# **#%&&&&&&&&&&&&@@@@#/
%&%%%%%%%%%%%%& %&.# #*%% .  ...,(((#((###(((* ., .. ,#%%/ .%%&&&@,@%&@@,@@@@( @
&@ %%%&% % #%%( %%%.*#(.( .,  *(#((..%##,*#(//(/ ,   .%%,&#&%&&&&& (@&(@&@@@@@@#
@@@@@@%%%%*. ,,%,&.   /&& .. .(#//( %### &./##(/, ,  ., %. &&&&&%#&,&%&&&@@&&@@@
@@@@@%% %%%#,%( &&* & %&&*,. *///(((.  .,%#%#(,/,*   . //%%#&&&&&&###(%@@@@@@@@@
@@@&@@%%%%%.%(%&%.&/.#&(%*  ,/.      .***,.    ..**  /%%.*,%&/ & % &&&&@@@@&@&.(
@@%&@&&% %, *%@&& %@@ /##.  */        .#(.,..   *,* *  %%%%*%,%%#%&,&&&&&&&%@@@@
@@@@@&&&**% &&&&@@*.@(&#/.. /*/#*((/*(*#(*(#,*(##/*. .#%%%/ ,%&#/ .%&&@&@@%(@@@@
@@&&%@(&%*&&&%@@@@,@@../.%,.*(,**##((./#(/,((/*(,.*.,,%#*%#(%&&%%%%%%@@@@&@@@..@
@#&&&&&//&&&%@@@@@ &/ .  *%..*.. ,**/      &/*,..,, .%.&%%%  //%%%%%@@@@@@@@@@@@
&&&@@ @@@ @@@@@@@@&,&@&.%*.*%&,..,,((... ,*(/*,,,,,%.%,  %#* *##%&&@@@@@@@&@@@@@
&#,@@@@@@ @@@@@@@@&&@&&&# %% %*,*/,.   ***   .,.../%/  &&#%%%&&@@@@@@&@@@@&@@@@@
@@#*@@@/@,@ @@@%@&&&&%&&.#%%,& ,,,             .,.#( &&%& %%%@@@@@@@@@@@@@@@@@@@
@@@@@@*@@ &@@@&&@&&@@&@(%%%%&%/.   . ,///**,.  . ,.% *&%,.(@@/ @@@@@@@@@@%@@. &@
@@@@@@&@#@@@@&  #&@&@@&%%%%%%%/,   .           ..,,.  ,(&@ @@*@@@@@//(@@@@@@@@ @
/%@@/@@*/@@ @.%%&@@%@&(%%%/@. /..    ..       .... ,   @@@@@* #@@@@@@@@ *@@%@//%
@@@%,/,@@@@@@ &&@@@&@&@&&     .*.     ..       .  *,       *@@@@@.&@@%@@@@@@@@@@
@@@@@@@@@@@@,@(@@& &@          /(                **,            @@@@@&@@@@@@@@@@
@@*#@@@ .@@@,//%%&             .(#              */*.                /@@@@@@@@@@@
@&@@@@@@@@@@&,                  */(#          ,****.                    @@@@@@@@
@@@@@@@@,                       ***//%       /***,,.                       @@@@@
@/@@.&@@@                       ,///(  /(  ,(     ..                         @@@
&@@%@@@                          *.  .   ./                                  @@@
@@@@@@                                ,.                                     @@@
@@@@@@                              .  .                                     @@@
@@@@@@                              ., .        .                            @@@
@@@@@%                               ,..       .                              @@
@@@@@                                .,                                       &@
@@@@*                                 .                                       .@
@@@@                                  .                                        @
&&@,                                                                           ,
%%@                                                                             
ARTE
)

# IMAGEM=/caminho/foto.png troca a arte do Neovim por ASCII gerado da imagem (tinta escura vira caractere denso).
IMAGEM=${IMAGEM:-}
ARTE=${ARTE:-}       # ARTE=/caminho/arte.txt usa um ASCII pronto (um tom só, tela cheia)
LOGO=${LOGO:-}       # LOGO=arch: logo do Arch tirado do neofetch instalado, centralizado
INVERTE=${INVERTE:-0} # INVERTE=1: parte clara da imagem vira caractere denso (desenho claro em fundo escuro)
LAYOUT=${LAYOUT:-}   # LAYOUT=centro: sem saudação, menu centralizado embaixo, arte sem sombra
logo_arch() { # -L só o logo; sed tira cores e comandos de cursor que o neofetch manda junto.
  command -v neofetch >/dev/null || { echo "Precisa do neofetch: yay -S neofetch" >&2; exit 1; }
  local l; l=$(neofetch --config none -L --ascii_distro arch 2>/dev/null | sed 's/\x1b\[[0-9;?]*[a-zA-Z]//g; s/[[:space:]]*$//' | sed '/^$/d')
  [[ -n $l ]] || { echo "O neofetch não devolveu o logo." >&2; exit 1; }
  printf '%s\n' "$l"
}
FUNDO=${FUNDO:-}     # FUNDO=/caminho/imagem.png usa a imagem pronta como fundo, em preto e branco, menu centralizado
modo=neovim
if [[ -n $FUNDO ]]; then
  [[ -f $FUNDO ]] || { echo "Imagem não encontrada: $FUNDO"; exit 1; }
  modo=foto; LAYOUT=centro
elif [[ $LOGO == arch ]]; then
  arte=$(logo_arch)
  modo=logo; LAYOUT=centro
elif [[ -n $ARTE ]]; then
  [[ -f $ARTE ]] || { echo "Arquivo não encontrado: $ARTE"; exit 1; }
  arte=$(sed 's/[[:space:]]*$//' "$ARTE")
  COLUNAS=$(awk '{ if (length > m) m = length } END { print m }' <<< "$arte")
  modo=cheio
elif [[ -n $IMAGEM ]]; then
  modo=cheio
  [[ -f $IMAGEM ]] || { echo "Imagem não encontrada: $IMAGEM"; exit 1; }
  COLUNAS=${COLUNAS:-160}
  arte=$(magick "$IMAGEM" -colorspace gray -auto-level -depth 8 pgm:- | python3 -c '
import sys
d = sys.stdin.buffer.read()
campos, i = [], 0
while len(campos) < 4:                      # P5 largura altura maxval
    while d[i:i+1].isspace(): i += 1
    j = i
    while not d[j:j+1].isspace(): j += 1
    campos.append(d[i:j]); i = j
i += 1
w, h = int(campos[1]), int(campos[2]); px = d[i:]
cols = int(sys.argv[1]); rows = max(1, round(cols * h / w * 0.5))   # célula de texto tem o dobro da altura
rampa = " .,:;-=+*#%@"
for r in range(rows):
    y0, y1 = r * h // rows, max(r * h // rows + 1, (r + 1) * h // rows)
    linha = []
    for c in range(cols):
        x0, x1 = c * w // cols, max(c * w // cols + 1, (c + 1) * w // cols)
        soma = n = 0
        for y in range(y0, y1, max(1, (y1 - y0) // 4)):
            for x in range(x0, x1, max(1, (x1 - x0) // 4)):
                soma += px[y * w + x]; n += 1
        tinta = soma / n / 255 if sys.argv[2] == "1" else 1 - soma / n / 255
        linha.append(rampa[min(len(rampa) - 1, int(tinta * len(rampa)))])
    print("".join(linha).rstrip())
' "$COLUNAS" "$INVERTE")
fi

# Fundo 1920x1080 (o GRUB estica para a tela).
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
if [[ $modo == foto ]]; then   # preenche 1920x1080 sem distorcer; -level clareia o cinza que sobra da cor
  # 2560x1440: o GRUB só reduz nas telas menores (nítido no LG); posições abaixo seguem em escala 1920x1080.
  FW=2560; FH=1440; esc() { echo $(( $1 * FW / 1920 )); }
  # O menu é centralizado na tela: o ponto do logo também precisa cair no centro. Amplia o mínimo que
  # permite recortar com esse ponto no meio sem sobrar borda vazia (deslizar deixava uma faixa sem imagem).
  zoom=1; px=$(( FW / 2 )); py=$(( FH / 2 ))
  if [[ $LOGO == arch ]]; then
    IFS=, read -r px py <<< "${LOGO_CENTRO:-960,540}"; px=$(esc "$px"); py=$(esc "$py")
    zoom=$(awk -v p="$px" -v W="$FW" 'BEGIN { d = p - W / 2; if (d < 0) d = -d; printf "%.5f", (W / 2) / (W / 2 - d) }')
  fi
  read -r nw nh x0 y0 cy_logo < <(awk -v z="$zoom" -v W="$FW" -v H="$FH" -v p="$px" -v q="$py" 'BEGIN {
    nw = int(W * z + 0.999); nh = int(H * z + 0.999)
    x0 = int(p * z - W / 2 + 0.5); if (x0 < 0) x0 = 0; if (x0 > nw - W) x0 = nw - W
    y0 = int((nh - H) / 2)
    print nw, nh, x0, y0, int(q * z - y0 + 0.5) }')
  magick "$FUNDO" -resize "${nw}x${nh}^" -gravity center -extent "${nw}x${nh}" +repage \
    +gravity -crop "${FW}x${FH}+${x0}+${y0}" +repage -colorspace gray -level 0%,60% "$TEMA/fundo.png"
  if (( ${DESLOCA:-0} != 0 )); then   # DESLOCA=-60 puxa a parte esquerda (até CORTE% da largura) para o lado
    corte=$(( FW * ${CORTE:-52} / 100 ))
    cor=$(magick "$TEMA/fundo.png" -format '%[pixel:p{5,5}]' info:)
    magick -size ${FW}x${FH} xc:"$cor"       \( "$TEMA/fundo.png" -crop "${corte}x${FH}+0+0" +repage \) -geometry "$(printf '%+d+0' "$(esc "$DESLOCA")")" -composite       \( "$TEMA/fundo.png" -crop "$(( FW - corte ))x${FH}+${corte}+0" +repage \) -geometry "+${corte}+0" -composite "$TEMA/fundo.png"
  fi
  if [[ $LOGO == arch ]]; then   # logo pequeno no meio da tela (no vão entre as mãos da imagem de referência)
    l=$(logo_arch); b='\'; l=${l//"$b"/"$b$b"}; l=${l//%/%%}
    # Recorta as sobras do label, ajusta a largura e encaixa o centro do logo em LOGO_CENTRO (px de 1920x1080).
    # Fonte grossa e grande, reduzida com Lanczos: o traço do ASCII sobrevive à redução.
    negrito=$(fc-match -f '%{file}' 'JetBrainsMono Nerd Font Mono:style=Bold')
    magick -background none -font "$negrito" -pointsize 56 -interline-spacing 0 -fill '#f2f2f2' label:" $l" \
      -trim +repage -filter Lanczos -resize "$(esc "${LOGO_LARGURA:-160}")x" "$tmp/logo.png"
    read -r lw lh < <(magick identify -format '%w %h' "$tmp/logo.png")
    cx=$(( FW / 2 )); cy=$cy_logo   # o recorte acima já trouxe o ponto do logo para o centro
    magick "$TEMA/fundo.png" "$tmp/logo.png" -gravity northwest -geometry "+$(( cx - lw / 2 ))+$(( cy - lh / 2 ))"       -compose over -composite "$TEMA/fundo.png"
  fi
else
ponto=18; espaco=3
[[ $modo == cheio ]] && { ponto=$(( 1920 * 10 / 6 / COLUNAS )); espaco=0; }
[[ $modo == logo ]] && { ponto=22; espaco=2; }
desenha() { # label: lê % e \ como comandos; dobrar deixa literal. Espaço na frente impede o @ inicial de virar "ler arquivo".
  local b='\' t; t=${2//"$b"/"$b$b"}; t=${t//%/%%}
  magick -background none -font "$mono" -pointsize "$ponto" -interline-spacing "$espaco" -fill "$1" label:" ${t}" "$3"; }
if [[ $modo == neovim ]]; then   # dois tons: @&%# claros, o resto escuro
  desenha '#3e3e44' "$(sed 's/[@&%#]/ /g' <<< "$arte")" "$tmp/claro.png"
  desenha '#85858d' "$(sed 's/[^@&%#]/ /g' <<< "$arte")" "$tmp/denso.png"
else                            # um tom só: logo e ASCII de foto usam letras como tinta
  desenha '#00000000' " " "$tmp/claro.png"
  desenha "$([[ $modo == logo ]] && echo '#eeeeee' || echo '#a8a8ae')" "$arte" "$tmp/denso.png"
fi
magick "$tmp/claro.png" "$tmp/denso.png" -background none -layers merge "$tmp/arte.png"
read -r w h < <(magick identify -format '%w %h' "$tmp/arte.png")

fundo="'#1b1b1e'-'#09090a'"; esq=1; some=1
case $modo in
  neovim) esq=$(( w * 35 / 100 )); grav=east; geo=+110+0 ;;
  cheio) grav=south; geo=+0+130
         [[ $LAYOUT == centro ]] && { some=0; grav=center; geo=+0+0; fundo="'#0e0e10'-'#060607'"; } ;;
  logo)  some=0; grav=north; geo=+0+150; fundo="'#2a2a2d'-'#141416'" ;;
esac
if (( some )); then   # some pela esquerda (só a arte do Neovim) e pelo pé
  magick -size "${w}x${h}" -define gradient:vector=0,0,$esq,0 gradient:black-white \
    \( -size "${w}x${h}" -define gradient:vector=0,$h,0,$(( h * 78 / 100 )) gradient:black-white \) \
    -compose multiply -composite "$tmp/mascara.png"
  magick "$tmp/arte.png" \( +clone -alpha extract "$tmp/mascara.png" -compose multiply -composite \) \
    -alpha off -compose CopyOpacity -composite "$tmp/arte.png"
fi
eval "magick -size 1920x1080 radial-gradient:$fundo" '"$tmp/arte.png" -gravity "$grav" -geometry "$geo" -compose over -composite "$tmp/fundo.png"'
if [[ $modo == cheio && $LAYOUT != centro ]]; then   # sombra à esquerda para o menu ficar legível sobre a arte
  magick "$tmp/fundo.png" \( -size 1920x1080 -define gradient:vector=0,0,900,0 gradient:'#09090ae6'-'#09090a00' \) \
    -compose over -composite "$TEMA/fundo.png"
else
  cp "$tmp/fundo.png" "$TEMA/fundo.png"
fi
fi

# Caixa arredondada da seleção, fatiada em 9 pedaços.
magick -size 24x24 xc:none -fill '#ffffff12' -stroke '#7a7a80' -strokewidth 1.5 \
  -draw 'roundrectangle 1,1 22,22 6,6' "$TEMA/caixa.png"
for p in nw:6x6+0+0 n:12x6+6+0 ne:6x6+18+0 w:6x12+0+6 c:12x12+6+6 e:6x12+18+6 sw:6x6+0+18 s:12x6+6+18 se:6x6+18+18; do
  magick "$TEMA/caixa.png" -crop "${p#*:}" +repage "$TEMA/select_${p%%:*}.png"
done
rm "$TEMA/caixa.png"

if [[ $LAYOUT == centro ]]; then
  saudacao=""
  # Medido em 1366x768, 1920x1080 e 2560x1440: menu entre o logo e o rodapé, longe das mãos.
  menu_pos="left = 50%-200 top = $([[ $modo == logo ]] && echo 66% || echo 68%) width = 400 height = 22%"
  rod1="100%-60"; rod2="100%-34"
  rod_pos='left = 0 width = 100% align = "center"'
else
  saudacao="+ label { left = 7% top = 7% width = 40% height = 40 font = \"$ft\" color = \"#e6e6e8\" text = \"Bem-vindo de volta, $NOME . . .\" }"
  menu_pos="left = 7%-12 top = 18% width = 34% height = 50%"
  rod_pos="left = 7% width = 40%"; rod1="100%-84"; rod2="100%-52"
fi

cat > "$TEMA/theme.txt" <<TEMA
title-text: ""
desktop-image: "fundo.png"
desktop-color: "#09090a"
terminal-font: "$fm"
message-font: "$fm"
message-color: "#c8c8cc"

$saudacao

+ boot_menu {
  $menu_pos
  item_font = "$fm" item_color = "#8e8e94"
  selected_item_font = "$fm" selected_item_color = "#ffffff"
  selected_item_pixmap_style = "select_*.png"
  item_height = 30 item_padding = 10 item_spacing = 10
  icon_width = 0 icon_height = 0 item_icon_space = 0
  scrollbar = false
}

+ label { $rod_pos top = $rod1 height = 20 font = "$fr" color = "#8e8e94" text = "[E] Editar entrada   [C] Linha de comando" }
+ label { id = "__timeout__" $rod_pos top = $rod2 height = 20 font = "$fr" color = "#c8c8cc" text = "Iniciando em %d segundos..." }
TEMA

def() { # troca ou acrescenta uma chave do /etc/default/grub
  if grep -q "^#\?$1=" /etc/default/grub; then sed -i "s|^#\?$1=.*|$1=$2|" /etc/default/grub
  else echo "$1=$2" >> /etc/default/grub; fi
}
def GRUB_THEME "\"$TEMA/theme.txt\""
def GRUB_GFXMODE auto
def GRUB_TIMEOUT 5
def GRUB_DISABLE_OS_PROBER false   # entrada do Windows (Kingston) no menu
sed -i 's|^GRUB_TERMINAL_OUTPUT=console|#GRUB_TERMINAL_OUTPUT=console|' /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg
echo ">> Pronto. Reinicie para ver."
