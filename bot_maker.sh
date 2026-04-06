#!/usr/bin/env bash
# ==========================================
#   🤖 BOT MAKER
#   Creates a custom Mineflayer AFK bot
# ==========================================

set -e

# --- COLORS ---
G=$'\033[32m'
C=$'\033[36m'
Y=$'\033[33m'
R=$'\033[31m'
N=$'\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

clear
echo -e "${C}=========================================${N}"
echo -e "${G}      MINECRAFT BOT MAKER 🚀            ${N}"
echo -e "${C}=========================================${N}"
echo ""

# --- CHECK FOR EXISTING BOT FILE ---
MAKE_NEW="true"

if [ -f "/root/app.js" ]; then
    echo -e "${Y}[!] An existing bot file (app.js) was found.${N}"
    while true; do
        read -p "${Y}👉 Do you want to DELETE it and create a new one? (y/n): ${N}" yn < /dev/tty
        case $yn in
            [Yy]* )
                echo -e "${R}🗑️  Deleting old bot file...${N}"
                rm -f /root/app.js
                MAKE_NEW="true"
                break;;
            [Nn]* )
                echo -e "${G}✅ Keeping existing bot file.${N}"
                MAKE_NEW="false"
                break;;
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
fi

# --- COLLECT BOT DETAILS ---
if [ "$MAKE_NEW" == "true" ]; then

    # Server IP
    while true; do
        echo ""
        echo -e "${Y}[?] Enter Server IP Address:${N}"
        read -p "👉 IP: " SERVER_IP < /dev/tty
        if [[ -n "$SERVER_IP" ]]; then
            break
        else
            echo -e "${R}❌ IP Address cannot be empty!${N}"
        fi
    done

    # Server Port
    echo ""
    echo -e "${Y}[?] Enter Server Port (Default: 25565):${N}"
    read -p "👉 Port: " SERVER_PORT < /dev/tty
    SERVER_PORT=${SERVER_PORT:-25565}

    # Bot Name
    while true; do
        echo ""
        echo -e "${Y}[?] Enter Bot Username:${N}"
        read -p "👉 Name: " BOT_NAME < /dev/tty
        if [[ -n "$BOT_NAME" ]]; then
            break
        else
            echo -e "${R}❌ Bot Name cannot be empty!${N}"
        fi
    done

    # --- WRITE app.js ---
    echo ""
    echo -e "${C}📝 Writing bot file to /root/app.js ...${N}"

cat <<JS > /root/app.js
const mineflayer = require("mineflayer");

// =================== CONFIG ===================
const config = {
  host: "$SERVER_IP",
  port: $SERVER_PORT,
  username: "$BOT_NAME",
  version: false,          // auto-detect server version

  jumpInterval: 3000,      // jump every 3s
  runInterval: 1000,       // change direction every 1s
  breakInterval: 6000,     // attempt block break every 6s
  breakScanRadius: 4,      // max block search distance
  breakOnly: ["dirt", "grass_block", "stone"],

  rejoinInterval: 30000,   // leave + rejoin every 30s
};
// ===============================================

let bot;

function createBot() {
  bot = mineflayer.createBot({
    host: config.host,
    port: config.port,
    username: config.username,
    version: config.version,
  });

  bot.on("login", () => {
    console.log(\`[bot] Logged in as \${bot.username} on \${config.host}:\${config.port}\`);
    startAFK();
  });

  bot.on("end", () => {
    console.log("[bot] Disconnected. Waiting to rejoin...");
  });

  bot.on("kicked", (reason) => console.log("[bot] Kicked:", reason));
  bot.on("error", (err) => console.log("[bot] Error:", err.message));
}

function startAFK() {
  // Jump loop
  const jumpLoop = setInterval(() => {
    if (!bot || !bot.entity) return;
    bot.setControlState("jump", true);
    setTimeout(() => bot.setControlState("jump", false), 200);
  }, config.jumpInterval);

  // Random movement loop
  const moveLoop = setInterval(() => {
    if (!bot || !bot.entity) return;
    const directions = ["forward", "back", "left", "right"];
    directions.forEach((d) => bot.setControlState(d, false));
    const dir = directions[Math.floor(Math.random() * directions.length)];
    bot.setControlState(dir, true);
  }, config.runInterval);

  // Block breaking loop
  const breakLoop = setInterval(() => {
    if (!bot || !bot.entity) return;
    tryBreakBlock();
  }, config.breakInterval);

  // Leave + rejoin cycle
  setTimeout(() => {
    console.log("[bot] Leaving server to rejoin...");
    clearInterval(jumpLoop);
    clearInterval(moveLoop);
    clearInterval(breakLoop);
    bot.quit();
    setTimeout(() => {
      console.log("[bot] Rejoining server...");
      createBot();
    }, 2000);
  }, config.rejoinInterval);
}

function tryBreakBlock() {
  const block = bot.findBlock({
    matching: (b) => {
      if (!b || !b.position) return false;
      if (b.type === 0) return false;
      if (!config.breakOnly.includes(b.name)) return false;
      return bot.entity.position.distanceTo(b.position) <= config.breakScanRadius;
    },
    maxDistance: config.breakScanRadius,
  });

  if (!block) return;

  console.log(\`[bot] Breaking block: \${block.name} at \${block.position}\`);
  bot.dig(block).catch((err) => console.log("[bot] Dig error:", err.message));
}

createBot();
JS

    echo -e "${G}✅ Bot file created at /root/app.js${N}"

else
    echo ""
    echo -e "${C}ℹ️  Skipped creation. Using existing /root/app.js${N}"
fi

# --- CHECK DEPENDENCIES ---
echo ""
echo -e "${C}⚙️  Checking Node.js and Mineflayer...${N}"

if ! command -v node &> /dev/null; then
    echo -e "${R}❌ Node.js is not installed. Please run Option 1 (Dependency Installer) first.${N}"
    exit 1
fi

cd /root
if [ ! -d "node_modules" ]; then
    echo -e "${Y}📦 Installing Mineflayer...${N}"
    npm init -y > /dev/null 2>&1
    npm install mineflayer > /dev/null 2>&1
else
    echo -e "${G}✅ Mineflayer already installed.${N}"
fi

# --- SUMMARY ---
echo ""
echo -e "${G}==============================================${N}"
echo -e "${G}       🚀 BOT SETUP COMPLETE!               ${N}"
echo -e "${G}==============================================${N}"
if [ "$MAKE_NEW" == "true" ]; then
    echo "  Server  : $SERVER_IP : $SERVER_PORT"
    echo "  Bot Name: $BOT_NAME"
fi
echo "  Run bot : node /root/app.js"
echo -e "${G}==============================================${N}"
echo ""

# --- OFFER AUTO RESTARTER ---
while true; do
    read -p "${Y}[?] Do you want to setup the Auto Restarter now? (y/n): ${N}" yn < /dev/tty
    case $yn in
        [Yy]* )
            echo -e "${C}🚀 Launching Auto Restarter Setup...${N}"
            bash "$SCRIPT_DIR/autorestarter.sh"
            break;;
        [Nn]* )
            echo -e "${G}✅ Done. Start bot manually with: node /root/app.js${N}"
            exit 0;;
        * ) echo "Please answer yes (y) or no (n).";;
    esac
done
