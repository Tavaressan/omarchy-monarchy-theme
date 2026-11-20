#!/bin/bash
# Instala os extras opcionais do tema Monarchy: protetor de tela e rotação de wallpaper.
# Uso: bash install-extras.sh [--screensaver] [--rotate] [--uninstall]
# Sem argumentos, instala os dois.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRANDING="$HOME/.config/omarchy/branding/screensaver.txt"
UNITS="$HOME/.config/systemd/user"

do_screensaver=0; do_rotate=0; uninstall=0
for a in "$@"; do
  case $a in
    --screensaver) do_screensaver=1 ;;
    --rotate) do_rotate=1 ;;
    --uninstall) uninstall=1 ;;
    *) echo "Opção desconhecida: $a" >&2; exit 1 ;;
  esac
done
((do_screensaver || do_rotate)) || { do_screensaver=1; do_rotate=1; }

if ((uninstall)); then
  if ((do_rotate)); then
    systemctl --user disable --now monarchy-bg-rotate.timer 2>/dev/null || true
    rm -f "$UNITS"/monarchy-bg-rotate.{service,timer}
    systemctl --user daemon-reload
    echo "Rotação removida."
  fi
  if ((do_screensaver)); then
    omarchy-branding-screensaver reset
    echo "Protetor de tela restaurado para o padrão do Omarchy."
  fi
  exit 0
fi

if ((do_screensaver)); then
  mkdir -p "$(dirname "$BRANDING")"
  if [[ -f $BRANDING ]] && ! cmp -s "$BRANDING" "$DIR/screensaver.txt"; then
    cp "$BRANDING" "$BRANDING.bak-antes-monarchy"
    echo "Backup do protetor atual: $BRANDING.bak-antes-monarchy"
  fi
  cp "$DIR/screensaver.txt" "$BRANDING"
  echo "Protetor de tela instalado (teste com SUPER + CTRL + S)."
fi

if ((do_rotate)); then
  mkdir -p "$UNITS"
  cp "$DIR"/extras/monarchy-bg-rotate.{service,timer} "$UNITS/"
  systemctl --user daemon-reload
  systemctl --user enable --now monarchy-bg-rotate.timer
  echo "Rotação de wallpaper ativa (intervalo em $UNITS/monarchy-bg-rotate.timer)."
fi
