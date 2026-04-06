#!/usr/bin/env bash
# ==========================================
#   ⚙️  AUTO RESTARTER SETUP
#   Creates a Systemd service for your bot
# ==========================================

set -euo pipefail

# --- COLORS ---
G=$'\033[32m'
B=$'\033[34m'
R=$'\033[31m'
C=$'\033[36m'
W=$'\033[97m'
Y=$'\033[33m'
N=$'\033[0m'

# --- CONFIG ---
BOT_FILE="/root/app.js"
SERVICE_NAME="mybot"

# --- ROOT CHECK ---
if [[ "$EUID" -ne 0 ]]; then
    echo -e "${R}❌ Please run as root (sudo).${N}"
    exit 1
fi

clear
echo -e "${B}=========================================${N}"
echo -e "${C}    ⚙️  NODE.JS BOT AUTO RESTARTER       ${N}"
echo -e "${B}=========================================${N}"
echo ""

# --- PRE-CHECKS ---
NODE_PATH=$(which node 2>/dev/null || true)
if [[ -z "$NODE_PATH" ]]; then
    echo -e "${R}❌ Node.js not found! Run the Dependency Installer first (Option 1).${N}"
    exit 1
fi

if [[ ! -f "$BOT_FILE" ]]; then
    echo -e "${R}❌ Bot file not found at $BOT_FILE! Run Bot Maker first (Option 2).${N}"
    exit 1
fi

# --- CONFIRM ---
while true; do
    echo -e "${Y}[?] This will STOP any existing bot service and create a new one.${N}"
    read -p "👉 Do you want to proceed? (y/n): " yn < /dev/tty
    case $yn in
        [Yy]* ) echo ""; break;;
        [Nn]* )
            echo -e "${C}🚫 Cancelled. Nothing was changed.${N}"
            exit 0;;
        * ) echo "Please answer yes (y) or no (n).";;
    esac
done

# --- CLEANUP OLD SERVICE ---
echo -e "${R}🧹 Removing old service if it exists...${N}"
systemctl stop $SERVICE_NAME 2>/dev/null || true
systemctl disable $SERVICE_NAME 2>/dev/null || true
rm -f /etc/systemd/system/${SERVICE_NAME}.service
systemctl daemon-reload
echo -e "${G}✔ Old service cleared.${N}"
echo ""

# --- CREATE NEW SERVICE ---
echo -e "${W}⚙️  Creating new systemd service...${N}"

cat > /etc/systemd/system/${SERVICE_NAME}.service <<EOF
[Unit]
Description=Minecraft AFK Bot (Auto Restarter)
After=network.target

[Service]
User=root
WorkingDirectory=/root
ExecStart=$NODE_PATH $BOT_FILE
Restart=always
RestartSec=10
SyslogIdentifier=$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF

# --- ENABLE & START ---
echo -e "${W}🚀 Enabling and starting bot service...${N}"
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

echo ""
echo -e "${G}================================================${N}"
echo -e "${G}  ✅ Bot is now running with Auto Restarter!   ${N}"
echo -e "${G}================================================${N}"
echo "  📋 View Logs  :  journalctl -u $SERVICE_NAME -f"
echo "  🛑 Stop Bot   :  systemctl stop $SERVICE_NAME"
echo "  ▶️  Start Bot  :  systemctl start $SERVICE_NAME"
echo "  🔄 Restart Bot:  systemctl restart $SERVICE_NAME"
echo -e "${G}================================================${N}"
echo ""
