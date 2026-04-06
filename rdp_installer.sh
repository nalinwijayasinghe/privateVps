#!/usr/bin/env bash
# ==========================================
#   🖥️  RDP INSTALLER
#   Installs XFCE Desktop + XRDP + Firefox
# ==========================================

set -euo pipefail

# --- COLORS ---
G=$'\033[32m'
B=$'\033[34m'
Y=$'\033[33m'
R=$'\033[31m'
C=$'\033[36m'
W=$'\033[97m'
N=$'\033[0m'

# --- ROOT CHECK ---
if [[ "$EUID" -ne 0 ]]; then
    echo -e "${R}❌ Please run as root (sudo).${N}"
    exit 1
fi

USER_NAME="${SUDO_USER:-root}"
USER_HOME="$(eval echo ~${USER_NAME})"

# --- HELPERS ---
divider() { echo -e "${B}==============================================================${N}"; }

progress_bar() {
    local percent=$1 width=40
    local filled=$((percent*width/100))
    local empty=$((width-filled))
    printf "%b[" "${Y}"
    printf "%0.s█" $(seq 1 "$filled")
    printf "%0.s░" $(seq 1 "$empty")
    printf "] %d%%%b\n" "$percent" "${N}"
}

spinner() {
    local pid=$!
    local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 "$pid" 2>/dev/null; do
        for ((i=0;i<${#frames};i++)); do
            printf "\r%b" "${C}${frames:i:1} Working...${N}"
            sleep 0.08
        done
    done
    printf "\r%b\n" "${G}✔ Done${N}"
}

run_step() {
    local label="$1"; shift
    echo -e "${G}🔹 ${label}${N}"
    ( "$@" ) & spinner
}

# --- INTRO ---
clear
divider
echo -e "${C}    🖥️  RDP DESKTOP ENVIRONMENT INSTALLER    ${N}"
divider
echo ""
sleep 0.3

# --- RAM CHECK ---
RAM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
echo -e "${B}🧠 RAM Detected: ${RAM_MB} MB${N}"
[[ "$RAM_MB" -lt 2000 ]] && echo -e "${Y}⚠️  Low RAM — optimized mode active${N}"
sleep 0.3

# --- STEPS ---
STEP=0; TOTAL=7
step() {
    STEP=$((STEP+1))
    echo -e "${W}➡️  Step ${STEP}/${TOTAL}${N}"
    progress_bar $((STEP*100/TOTAL))
}

step; run_step "Updating system"              apt update -y
step; run_step "Upgrading packages"           apt upgrade -y
step; run_step "Installing XFCE + XRDP"      apt install -y xfce4 xfce4-goodies xrdp
step; run_step "Installing Firefox ESR"       apt install -y firefox-esr

step
echo -e "${G}🔹 Configuring XFCE session for $USER_NAME${N}"
(
    printf "startxfce4\n" > "${USER_HOME}/.xsession"
    chown "${USER_NAME}:${USER_NAME}" "${USER_HOME}/.xsession"
) & spinner

step
echo -e "${G}🔹 Enabling XRDP service${N}"
(systemctl enable xrdp && systemctl restart xrdp) & spinner

step
echo -e "${G}🔹 Applying XRDP black-screen fix${N}"
(
    sed -i.bak 's/^test -x/#test -x/' /etc/xrdp/startwm.sh || true
    {
        printf "unset DBUS_SESSION_BUS_ADDRESS\n"
        printf "unset XDG_RUNTIME_DIR\n"
    } >> /etc/xrdp/startwm.sh
    systemctl restart xrdp

    # Allow RDP port through firewall if UFW is present
    if command -v ufw >/dev/null 2>&1; then
        ufw allow 3389/tcp
        ufw reload
    fi
) & spinner

# --- DONE ---
echo ""
divider
echo -e "${G}  ✅  RDP Installation Completed Successfully!  ${N}"
divider
echo "  🔗 Connect via:  Remote Desktop → Port 3389"
echo "  👤 Username   :  root (or your Linux username)"
echo "  🔑 Password   :  Your Linux user password"
divider
echo ""
