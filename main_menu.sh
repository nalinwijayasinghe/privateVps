#!/usr/bin/env bash
# ==========================================
#   🚀 MY ALL IN ONE TOOL
# ==========================================

set -u

# --- ANSI COLORS ---
C=$'\033[36m'  # Cyan
G=$'\033[32m'  # Green
R=$'\033[31m'  # Red
B=$'\033[34m'  # Blue
Y=$'\033[33m'  # Yellow
W=$'\033[97m'  # White
N=$'\033[0m'   # Reset

# ==========================================
#  ✏️  SET YOUR GITHUB DETAILS HERE
# ==========================================
GITHUB_USER="YOUR_USERNAME"
GITHUB_REPO="YOUR_REPO"
GITHUB_BRANCH="main"
RAW="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/refs/heads/${GITHUB_BRANCH}"
# ==========================================

# --- HEADER FUNCTION ---
header() {
    clear
    echo -e "${B}  __  __         _____           _ ${N}"
    echo -e "${B} |  \/  |_   _  |_   _|__   ___ | |${N}"
    echo -e "${B} | |\/| | | | |   | |/ _ \ / _ \| |${N}"
    echo -e "${B} | |  | | |_| |   | | (_) | (_) | |${N}"
    echo -e "${B} |_|  |_|\__, |   |_|\___/ \___/|_|${N}"
    echo -e "${B}          |___/                     ${N}"
    echo -e "${B}=====================================================${N}"
    echo -e "${Y}          🚀 MY ALL IN ONE TOOL                      ${N}"
    echo -e "${B}=====================================================${N}"
    echo ""
}

# --- PAUSE FUNCTION ---
pause() {
    echo ""
    read -p "${W}Press [Enter] to return to menu...${N}" dummy
}

# --- MAIN LOOP ---
while true; do
    header
    echo -e "${C} 1) ${W}Dependency Installer   ${G}(Node + Mineflayer)${N}"
    echo -e "${C} 2) ${W}Bot Maker              ${G}(Create app.js)${N}"
    echo -e "${C} 3) ${W}Auto Restarter Setup   ${G}(Systemd Service)${N}"
    echo -e "${C} 4) ${W}Bot Remover            ${G}(Manager)${N}"
    echo -e "${C} 5) ${W}VM Installer           ${G}(IDX VPS)${N}"
    echo -e "${C} 6) ${W}RDP Installer          ${G}(Desktop Environment)${N}"
    echo -e "${C} 7) ${W}Tailscale Installer    ${G}(VPN)${N}"
    echo -e "${R} 8) Exit${N}"
    echo ""
    echo -e "${B}=====================================================${N}"
    read -p "${Y}👉 Select an option [1-8]: ${N}" choice

    case $choice in
        1)
            echo ""
            echo -e "${Y}🔄 Running Dependency Installer...${N}"
            curl -fsSL "${RAW}/dependency.sh" | sed 's/\r$//' | bash
            pause
            ;;
        2)
            echo ""
            echo -e "${Y}🛠️  Running Bot Maker...${N}"
            curl -fsSL "${RAW}/bot_maker.sh" | sed 's/\r$//' | bash
            pause
            ;;
        3)
            echo ""
            echo -e "${Y}⚙️  Setting up Auto Restarter...${N}"
            curl -fsSL "${RAW}/autorestarter.sh" | sed 's/\r$//' | bash
            pause
            ;;
        4)
            echo ""
            echo -e "${Y}🚀 Opening Bot Remover...${N}"
            curl -fsSL "${RAW}/bot_remover.sh" | sed 's/\r$//' | bash
            pause
            ;;
        5)
            echo ""
            echo -e "${Y}💻 Installing VM (IDX VPS)...${N}"
            bash <(curl -fsSL "${RAW}/vm_installer.sh")
            pause
            ;;
        6)
            echo ""
            echo -e "${Y}🖥️  Installing RDP Desktop Environment...${N}"
            curl -fsSL "${RAW}/rdp_installer.sh" | sed 's/\r$//' | bash
            pause
            ;;
        7)
            echo ""
            echo -e "${Y}🌐 Installing Tailscale VPN...${N}"
            curl -fsSL "${RAW}/tailscale_installer.sh" | sed 's/\r$//' | bash
            pause
            ;;
        8)
            echo ""
            echo -e "${G}👋 Exiting... Goodbye!${N}"
            exit 0
            ;;
        *)
            echo ""
            echo -e "${R}❌ Invalid Option! Please select between 1-8.${N}"
            sleep 2
            ;;
    esac
done
