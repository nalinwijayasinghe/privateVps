#!/usr/bin/env bash
# ==========================================
#   🚀 SETUP - Make all scripts executable
#   Run this ONCE after downloading
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

chmod +x "$SCRIPT_DIR/main_menu.sh"
chmod +x "$SCRIPT_DIR/dependency.sh"
chmod +x "$SCRIPT_DIR/bot_maker.sh"
chmod +x "$SCRIPT_DIR/autorestarter.sh"
chmod +x "$SCRIPT_DIR/bot_remover.sh"
chmod +x "$SCRIPT_DIR/vm_installer.sh"
chmod +x "$SCRIPT_DIR/rdp_installer.sh"
chmod +x "$SCRIPT_DIR/tailscale_installer.sh"

echo ""
echo "✅ All scripts are now executable!"
echo "👉 Run the tool with:  bash main_menu.sh"
echo ""
