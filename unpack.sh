#!/bin/sh

is_installed() {
  command -v "$1" >/dev/null 2>&1
}

unpack() {
  case "$1" in
    *.tar*)
      if ! is_installed tar; then
        echo "tar is not installed. Cannot unpack $1"
        exit 1
      fi
      case "$1" in
        *.tar)
          tar -xf "$1" ;;
        *.tar.gz)
          tar -xzf "$1" ;;
        *.tar.bz2)
          tar -xjf "$1" ;;
        *.tar.xz)
          tar -xJf "$1" ;;
      esac
      ;;
    *.zip)
      if ! is_installed unzip; then
        echo "unzip is not installed. Cannot unpack $1"
        exit 1
      fi
      unzip "$1"
      ;;
    *.rar)
      if ! is_installed unrar; then
        echo "unrar is not installed. Cannot unpack $1"
        exit 1
      fi
      unrar x "$1"
      ;;
    *.7z)
      if ! is_installed 7z; then
        echo "7z is not installed. Cannot unpack $1"
        exit 1
      fi
      7z x "$1"
      ;;
    *.bz2)
      if ! is_installed bunzip2; then
        echo "bunzip2 is not installed. Cannot unpack $1"
        exit 1
      fi
      bunzip2 "$1"
      ;;
    *)
      echo "Unsupported file type: $1"
      exit 1
      ;;
  esac
}

if [ -z "$1" ]; then
  echo "No file provided. Usage: $0 <archive>"
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "File does not exist: $1"
  exit 1
fi

unpack "$1"
