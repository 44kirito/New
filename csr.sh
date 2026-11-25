#!/usr/bin/env bash

center() {
  local clean=$(echo -e "$1" | sed -r 's/\x1B\[[0-9;]*[mK]//g')
  local pad=$(( ($(tput cols) - ${#clean}) / 2 ))
  (( pad < 0 )) && pad=0
  printf "%*s%b\n" "$pad" "" "$1"
}

if [[ "$EUID" -ne 0 ]]; then
  echo ""
  center "\033[0;31mError: This script must be run as root (use sudo or log in as root).\033[0m"
  echo ""
  exit 1
fi

SCRIPT_PATH="$(realpath "${BASH_SOURCE}")"
chown root:root "$SCRIPT_PATH"
chmod 700 "$SCRIPT_PATH"

OUT_DIR="/root/certs"
mkdir -p "$OUT_DIR"
chmod 700 "$OUT_DIR"

center_read() {
  local prompt="$1"
  local varname="${2:-REPLY}"
  local default_val="${3:-}"
  local color="${4:-}"
  local clean=$(echo -e "$prompt$default_val" | sed -r 's/\x1B\[[0-9;]*[mK]//g')
  local pad=$(( ($(tput cols) - ${#clean}) / 2 ))
  (( pad < 0 )) && pad=0
  local spaces
  printf -v spaces "%*s" "$pad" ""

  if [[ -n "$default_val" ]]; then
    if [[ -n "$color" ]]; then
      read -e -p "${spaces}${prompt}"$'\001'"${color}"$'\002' -i "$default_val" "$varname"
      printf "\033[0m"
    else
      read -e -p "${spaces}${prompt}" -i "$default_val" "$varname"
    fi
  else
    read -e -p "${spaces}${prompt}" "$varname"
  fi
}

echo ""
echo ""
center "====== Oracle Linux 8 RSA 2048-bit CSR Generator with private key ======"
center "\033[0;31mPlease enter all required certificate details below.\033[0m"
center "\033[0;31mSpaces are not supported and will cause an error.\033[0m"
echo ""
echo ""
center_read "Beginning The Certificate Signing Request (CSR) if READY press Enter to start, or to cancel, press CTRL-C. "
center "\033[0;31mNote: File extensions (.key and .csr) are added automatically.\033[0m"
echo ""
echo ""
center_read "Enter a name for your private key file (do not include .key): " KEYNAME "Key-FileName" $'\033[0;32m'
center_read "Enter a name for your Certificate Signing Request file (do not include .csr): " CSRNAME "CSR-FileName" $'\033[0;32m'
echo ""
echo ""
center "\033[0;31mPress Enter to accept the default values below, or edit as needed:\033[0m"
center_read "Country Code (2 letters): " C "US" $'\033[0;32m'
center_read "Organizational Unit (OU): " OU "USA,PKI,DoD" $'\033[0;32m'
center_read "Organization (O): " O "U.S. Government" $'\033[0;32m'
echo ""
echo ""
center "\033[0;31mEnter your server-specific details:\033[0m"
center_read "Common Name (FQDN): " CN "HostName.fully-qualified-domain" $'\033[0;32m'
center_read "Server IP Address: " IPADDR "192.168.0.0" $'\033[0;32m'
center_read "Short Hostname: " HOSTANME "HostName" $'\033[0;32m'
center_read "State / Province (ST): " ST "State" $'\033[0;32m'
center_read "City / Locality (L): " L "City" $'\033[0;32m'
echo ""
echo ""

KEY_PATH="${OUT_DIR}/${KEYNAME}.key"
CSR_PATH="${OUT_DIR}/${CSRNAME}.csr"

if [[ -f "$KEY_PATH" || -f "$CSR_PATH" ]]; then
  echo ""
  center "\033[0;31mWARNING: Existing file(s) found in ${OUT_DIR}:\033[0m"
  [[ -f "$KEY_PATH" ]] && center "\033[0;31m  - ${KEY_PATH}\033[0m"
  [[ -f "$CSR_PATH" ]] && center "\033[0;31m  - ${CSR_PATH}\033[0m"
  echo ""
  center_read "Do you want to overwrite them? (y/N): " OVERWRITE "N" $'\033[0;31m'
  if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
    echo ""
    center "\033[0;31mOperation cancelled. Existing files were not modified.\033[0m"
    echo ""
    exit 1
  fi
  echo ""
fi

openssl req -nodes -sha256 -newkey rsa:2048 -keyout "$KEY_PATH" -out "$CSR_PATH" -subj "/C=$C/OU=$OU/O=$O/CN=$CN/ST=$ST/L=$L" -addext "subjectAltName=DNS:$CN,DNS:$HOSTANME,IP:$IPADDR" >/dev/null 2>&1 & pid=$!; p=0; while kill -0 $pid 2>/dev/null; do ((p = p < 95 ? p + 5 : 95)); bar=$(printf "%-$((p/5))s" "#" | tr ' ' '#'); pad=$(( ($(tput cols) - 35) / 2 )); (( pad < 0 )) && pad=0; printf "\r%*sGenerating: [%-20s] %d%%" "$pad" "" "$bar" "$p"; sleep 0.05; done; wait $pid; pad=$(( ($(tput cols) - 36) / 2 )); (( pad < 0 )) && pad=0; printf "\r%*sGenerating: [####################] 100%%\n" "$pad" ""

chmod 600 "$KEY_PATH"
chmod 644 "$CSR_PATH"

echo ""
echo ""
center "----------------------------------------------------------------"
center "---------------------- Below is your Key -----------------------"
center "----------------------------------------------------------------"
echo ""
printf "\033[1;33m"
cat "$KEY_PATH"
printf "\033[0m"
echo ""
echo ""
center "----------------------------------------------------------------"
center "---------------------- Below is your CSR -----------------------"
center "----------------------------------------------------------------"
echo ""
printf "\033[1;33m"
cat "$CSR_PATH"
printf "\033[0m"
echo ""
echo ""
center "----------------------------------------------------------------"
center "------------------- CSR Verification Summary -------------------"
center "----------------------------------------------------------------"
echo ""
openssl req -text -noout -verify -reqopt no_pubkey,no_sigdump -in "$CSR_PATH" 2>&1 | sed 's/^[[:space:]]*//' | while IFS= read -r line; do
  if [[ "$line" == *"verify OK"* ]]; then
    center "\033[0;32m$line\033[0m"
  else
    center "$line"
  fi
done
echo ""
center "\033[0;32mSaved Key: $KEY_PATH\033[0m"
center "\033[0;32mSaved CSR: $CSR_PATH\033[0m"
echo ""
center "****************************************************************"
center_read "Verification complete. Press ENTER to exit..."
center "****************************************************************"
exit 0
