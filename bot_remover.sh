#!/usr/bin/env bash
# ==========================================
#   🗑️  BOT REMOVER TOOL
# ==========================================

# --- COLORS ---
C=$'\033[36m'
G=$'\033[32m'
R=$'\033[31m'
B=$'\033[34m'
Y=$'\033[33m'
W=$'\033[97m'
N=$'\033[0m'

# --- HEADER ---
header() {
    clear
    echo -e "${R}=========================================${N}"
    echo -e "${Y}          🗑️  BOT REMOVER TOOL           ${N}"
    echo -e "${R}=========================================${N}"
    echo ""
}

# --- PAUSE ---
pause() {
    echo ""
    read -p "${W}Press [Enter] to return...${N}" dummy < /dev/tty
}

# --- MAIN LOOP ---
while true; do
    header
    echo -e "${C} 1) ${W}Remove Bot File    ${R}(Delete /root/app.js)${N}"
    echo -e "${C} 2) ${W}Remove Auto Restarter ${R}(Stop & Delete Service)${N}"
    echo -e "${C} 3) ${W}Remove Both        ${R}(Full Clean)${N}"
    echo -e "${C} 4) ${G}Exit${N}"
    echo ""
    echo -e "${R}=========================================${N}"

    read -p "${Y}👉 Select an option [1-4]: ${N}" choice < /dev/tty

    case $choice in
        1)
            echo ""
            echo -e "${Y}🗑️  Deleting /root/app.js...${N}"
            if [ -f "/root/app.js" ]; then
                rm -f "/root/app.js"
                echo -e "${G}✔ app.js deleted successfully!${N}"
            else
                echo -e "${R}❌ app.js not found at /root/app.js${N}"
            fi
            pause
            ;;
        2)
            echo ""
            echo -e "${Y}🛑 Stopping bot service...${N}"
            sudo systemctl stop mybot 2>/dev/null || echo -e "${R}⚠️  Service was not running.${N}"
            sudo systemctl disable mybot 2>/dev/null || true
            echo -e "${Y}🗑️  Removing service file...${N}"
            if [ -f "/etc/systemd/system/mybot.service" ]; then
                sudo rm -f "/etc/systemd/system/mybot.service"
                sudo systemctl daemon-reload
                echo -e "${G}✔ Auto Restarter removed successfully!${N}"
            else
                echo -e "${R}❌ Service file not found!${N}"
            fi
            pause
            ;;
        3)
            echo ""
            echo -e "${Y}🧹 Running full clean...${N}"
            # Remove bot file
            if [ -f "/root/app.js" ]; then
                rm -f "/root/app.js"
                echo -e "${G}✔ app.js deleted.${N}"
            else
                echo -e "${R}⚠️  app.js not found.${N}"
            fi
            # Remove service
            sudo systemctl stop mybot 2>/dev/null || true
            sudo systemctl disable mybot 2>/dev/null || true
            if [ -f "/etc/systemd/system/mybot.service" ]; then
                sudo rm -f "/etc/systemd/system/mybot.service"
                sudo systemctl daemon-reload
                echo -e "${G}✔ Auto Restarter removed.${N}"
            else
                echo -e "${R}⚠️  Service file not found.${N}"
            fi
            echo ""
            echo -e "${G}✅ Full clean complete!${N}"
            pause
            ;;
        4)
            echo ""
            echo -e "${G}👋 Exiting Bot Remover...${N}"
            exit 0
            ;;
        *)
            echo ""
            echo -e "${R}❌ Invalid Option!${N}"
            sleep 1
            ;;
    esac
done
