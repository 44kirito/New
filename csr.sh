#!/usr/bin/env bash

center() {
  local clean=$(echo -e "$1" | sed -r 's/\x1B\[[0-9;]*[mK]//g')
  local pad=$(( ($(tput cols) - ${#clean}) / 2 ))
  (( pad < 0 )) && pad=0
  printf "%*s%b\n" "$pad" "" "$1"
}

echo ""
echo ""
center "=== Oracle Linux 8 RSA 2048-bit CSR Generator with private key ==="
center "\033[0;31mPlease enter all required certificate details below.\033[0m"
echo ""
echo ""







