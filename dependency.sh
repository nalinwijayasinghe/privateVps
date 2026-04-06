#!/usr/bin/env bash
# ==========================================
#   📦 DEPENDENCY INSTALLER
#   Installs: Node.js v22 + NPM + Mineflayer
# ==========================================

set -e

# --- COLORS ---
G=$'\033[32m'  # Green
Y=$'\033[33m'  # Yellow
C=$'\033[36m'  # Cyan
R=$'\033[31m'  # Red
N=$'\033[0m'   # Reset

echo ""
echo -e "${Y}🔧 Step 1: Fixing any broken packages...${N}"
dpkg --configure -a || true
apt --fix-broken install -y || true
apt-get autoremove -y || true

echo ""
echo -e "${C}📦 Step 2: Updating system packages...${N}"
apt update -y

echo ""
echo -e "${Y}🗑️  Step 3: Removing old Node.js / NPM versions...${N}"
apt-get remove -y nodejs npm libnode72 || true

echo ""
echo -e "${C}🌐 Step 4: Adding Node.js v22 repository...${N}"
apt install -y curl
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -

echo ""
echo -e "${C}⚙️  Step 5: Installing Node.js, NPM, Git & Build Tools...${N}"
apt install -y nodejs
apt install -y build-essential git

echo ""
echo -e "${C}🎮 Step 6: Installing Mineflayer in /root...${N}"
cd /root
if [ ! -f "package.json" ]; then
    npm init -y
fi
npm install mineflayer

echo ""
echo -e "${G}============================================${N}"
echo -e "${G}  ✅  ALL DEPENDENCIES INSTALLED!          ${N}"
echo -e "${G}============================================${N}"
echo "  👉 Node.js : $(node -v)"
echo "  👉 NPM     : $(npm -v)"
echo "  👉 Git     : $(git --version)"
echo -e "${G}============================================${N}"
echo ""
