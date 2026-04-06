#!/usr/bin/env bash
# ==========================================
#   🌐 TAILSCALE INSTALLER & SETUP
# ==========================================

set -e

# --- COLORS ---
G=$'\033[32m'
B=$'\033[34m'
Y=$'\033[33m'
R=$'\033[31m'
C=$'\033[36m'
W=$'\033[97m'
N=$'\033[0m'

clear
echo -e "${B}=========================================${N}"
echo -e "${C}    🌐  TAILSCALE VPN INSTALLER          ${N}"
echo -e "${B}=========================================${N}"
echo ""

# --- ROOT CHECK ---
if [[ "$EUID" -ne 0 ]]; then
    echo -e "${R}❌ Please run as root (sudo).${N}"
    exit 1
fi

# --- CHECK IF ALREADY INSTALLED ---
if command -v tailscale &>/dev/null; then
    echo -e "${Y}⚠️  Tailscale is already installed.${N}"
    echo -e "${Y}    Version: $(tailscale version | head -1)${N}"
    echo ""
    while true; do
        read -p "${Y}👉 Do you want to reinstall it? (y/n): ${N}" yn < /dev/tty
        case $yn in
            [Yy]* ) echo ""; break ;;
            [Nn]* )
                echo ""
                echo -e "${C}ℹ️  Skipping install. Running tailscale up...${N}"
                tailscale up
                echo ""
                echo -e "${G}✅ Tailscale is up!${N}"
                tailscale status
                exit 0 ;;
            * ) echo "Please answer yes (y) or no (n)." ;;
        esac
    done
fi

# --- INSTALL ---
echo -e "${Y}📦 Installing Tailscale...${N}"
echo ""
curl -fsSL https://tailscale.com/install.sh | sh

echo ""
echo -e "${G}✅ Tailscale installed successfully!${N}"
echo ""

# --- TAILSCALE UP ---
echo -e "${C}🔗 Bringing Tailscale up...${N}"
echo ""
tailscale up

echo ""
echo -e "${B}=========================================${N}"
echo -e "${G}  ✅  TAILSCALE IS RUNNING!              ${N}"
echo -e "${B}=========================================${N}"
echo ""
echo -e "${W}Useful commands:${N}"
echo "  tailscale status       — Show connected devices"
echo "  tailscale ip           — Show your Tailscale IP"
echo "  tailscale up           — Connect to Tailscale"
echo "  tailscale down         — Disconnect from Tailscale"
echo -e "${B}=========================================${N}"
echo ""
