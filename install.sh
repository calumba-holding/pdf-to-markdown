#!/bin/sh
set -eu

INSTALL_DIR="${INSTALL_DIR:-${HOME}/.local/bin}"
RAW_BASE_URL="${RAW_BASE_URL:-https://raw.githubusercontent.com/PSPDFKit/pdf-to-markdown/main}"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
COMMANDS="pdf-to-markdown pdf-to-text"

CURRENT_TMP=""

cleanup() {
  if [ -n "$CURRENT_TMP" ]; then
    rm -f "$CURRENT_TMP"
  fi
}

trap cleanup EXIT INT TERM HUP

download() {
  url="$1"
  destination="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$destination"
    return 0
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -q -O "$destination" "$url"
    return 0
  fi

  echo "install.sh requires curl or wget" >&2
  exit 1
}

install_command() {
  name="$1"
  target="$INSTALL_DIR/$name"
  CURRENT_TMP="$(mktemp "${TMPDIR:-/tmp}/${name}-install.XXXXXX")"

  if [ -f "$SCRIPT_DIR/bin/$name" ]; then
    cp "$SCRIPT_DIR/bin/$name" "$CURRENT_TMP"
  else
    download "$RAW_BASE_URL/bin/$name" "$CURRENT_TMP"
  fi

  chmod 0755 "$CURRENT_TMP"
  mv "$CURRENT_TMP" "$target"
  CURRENT_TMP=""

  printf 'Installed %s to %s\n' "$name" "$target"
}

mkdir -p "$INSTALL_DIR"

for command_name in $COMMANDS; do
  install_command "$command_name"
done

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    printf 'Add %s to PATH if it is not already available in your shell.\n' "$INSTALL_DIR"
    ;;
esac
