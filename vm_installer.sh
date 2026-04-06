#!/usr/bin/env bash
# ==========================================
#   💻 VM INSTALLER (IDX VPS)
#   Multi-VM Manager using QEMU
# ==========================================

set -euo pipefail

# --- COLORS ---
B=$'\033[34m'
G=$'\033[32m'
Y=$'\033[33m'
R=$'\033[31m'
C=$'\033[36m'
W=$'\033[97m'
N=$'\033[0m'

# --- PRINT STATUS ---
print_status() {
    local type=$1
    local message=$2
    case $type in
        "INFO")    echo -e "${B}[INFO]${N} $message" ;;
        "WARN")    echo -e "${Y}[WARN]${N} $message" ;;
        "ERROR")   echo -e "${R}[ERROR]${N} $message" ;;
        "SUCCESS") echo -e "${G}[SUCCESS]${N} $message" ;;
        "INPUT")   echo -e "${C}[INPUT]${N} $message" ;;
        *)         echo "[$type] $message" ;;
    esac
}

# --- HEADER ---
display_header() {
    clear
    echo -e "${B}=======================================${N}"
    echo -e "${C}    💻  MY VM MANAGER (IDX VPS)       ${N}"
    echo -e "${B}=======================================${N}"
    echo ""
}

# --- INPUT VALIDATION ---
validate_input() {
    local type=$1
    local value=$2
    case $type in
        "number") [[ "$value" =~ ^[0-9]+$ ]] || { print_status "ERROR" "Must be a number"; return 1; } ;;
        "size")   [[ "$value" =~ ^[0-9]+[GgMm]$ ]] || { print_status "ERROR" "Must be a size like 20G or 512M"; return 1; } ;;
        "port")   [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 23 ] && [ "$value" -le 65535 ] || { print_status "ERROR" "Port must be 23-65535"; return 1; } ;;
        "name")   [[ "$value" =~ ^[a-zA-Z0-9_-]+$ ]] || { print_status "ERROR" "Only letters, numbers, hyphens, underscores"; return 1; } ;;
        "username") [[ "$value" =~ ^[a-z_][a-z0-9_-]*$ ]] || { print_status "ERROR" "Must start with letter/underscore"; return 1; } ;;
    esac
    return 0
}

# --- CHECK DEPENDENCIES ---
check_dependencies() {
    local deps=("qemu-system-x86_64" "wget" "cloud-localds" "qemu-img")
    local missing=()
    for dep in "${deps[@]}"; do
        command -v "$dep" &>/dev/null || missing+=("$dep")
    done
    if [ ${#missing[@]} -ne 0 ]; then
        print_status "ERROR" "Missing: ${missing[*]}"
        print_status "INFO" "Install with: sudo apt install qemu-system cloud-image-utils wget"
        exit 1
    fi
}

# --- CLEANUP TEMP FILES ---
cleanup() {
    rm -f "user-data" "meta-data" 2>/dev/null || true
}
trap cleanup EXIT

# --- VM DIRECTORY ---
VM_DIR="${HOME}/vms"
mkdir -p "$VM_DIR"

# --- OS OPTIONS ---
declare -A OS_OPTIONS=(
    ["Ubuntu 22.04"]="ubuntu|jammy|https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img|ubuntu22|ubuntu|ubuntu"
    ["Ubuntu 24.04"]="ubuntu|noble|https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img|ubuntu24|ubuntu|ubuntu"
    ["Debian 11"]="debian|bullseye|https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2|debian11|debian|debian"
    ["Debian 12"]="debian|bookworm|https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2|debian12|debian|debian"
)

# --- GET VM LIST ---
get_vm_list() {
    find "$VM_DIR" -name "*.conf" -exec basename {} .conf \; 2>/dev/null | sort
}

# --- LOAD VM CONFIG ---
load_vm_config() {
    local vm_name=$1
    local config_file="$VM_DIR/$vm_name.conf"
    if [[ -f "$config_file" ]]; then
        unset VM_NAME OS_TYPE CODENAME IMG_URL HOSTNAME USERNAME PASSWORD DISK_SIZE MEMORY CPUS SSH_PORT GUI_MODE PORT_FORWARDS IMG_FILE SEED_FILE CREATED
        source "$config_file"
        return 0
    else
        print_status "ERROR" "Config for '$vm_name' not found"
        return 1
    fi
}

# --- SAVE VM CONFIG ---
save_vm_config() {
    cat > "$VM_DIR/$VM_NAME.conf" <<EOF
VM_NAME="$VM_NAME"
OS_TYPE="$OS_TYPE"
CODENAME="$CODENAME"
IMG_URL="$IMG_URL"
HOSTNAME="$HOSTNAME"
USERNAME="$USERNAME"
PASSWORD="$PASSWORD"
DISK_SIZE="$DISK_SIZE"
MEMORY="$MEMORY"
CPUS="$CPUS"
SSH_PORT="$SSH_PORT"
GUI_MODE="$GUI_MODE"
PORT_FORWARDS="$PORT_FORWARDS"
IMG_FILE="$IMG_FILE"
SEED_FILE="$SEED_FILE"
CREATED="$CREATED"
EOF
    print_status "SUCCESS" "Config saved."
}

# --- SETUP VM IMAGE ---
setup_vm_image() {
    print_status "INFO" "Preparing VM image..."
    mkdir -p "$VM_DIR"

    if [[ ! -f "$IMG_FILE" ]]; then
        print_status "INFO" "Downloading $OS_TYPE image..."
        wget --progress=bar:force "$IMG_URL" -O "$IMG_FILE.tmp"
        mv "$IMG_FILE.tmp" "$IMG_FILE"
    else
        print_status "INFO" "Image already exists, skipping download."
    fi

    qemu-img resize "$IMG_FILE" "$DISK_SIZE" 2>/dev/null || true

    cat > user-data <<EOF
#cloud-config
hostname: $HOSTNAME
ssh_pwauth: true
disable_root: false
users:
  - name: $USERNAME
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    password: $(openssl passwd -6 "$PASSWORD" | tr -d '\n')
chpasswd:
  list: |
    root:$PASSWORD
    $USERNAME:$PASSWORD
  expire: false
EOF

    cat > meta-data <<EOF
instance-id: iid-$VM_NAME
local-hostname: $HOSTNAME
EOF

    cloud-localds "$SEED_FILE" user-data meta-data
    print_status "SUCCESS" "VM '$VM_NAME' image ready."
}

# --- CREATE NEW VM ---
create_new_vm() {
    print_status "INFO" "Creating a new VM"

    local os_options=()
    local i=1
    for os in "${!OS_OPTIONS[@]}"; do
        echo "  $i) $os"
        os_options[$i]="$os"
        ((i++))
    done

    while true; do
        read -p "$(print_status "INPUT" "Select OS (1-${#OS_OPTIONS[@]}): ")" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#OS_OPTIONS[@]} ]; then
            local os="${os_options[$choice]}"
            IFS='|' read -r OS_TYPE CODENAME IMG_URL DEFAULT_HOSTNAME DEFAULT_USERNAME DEFAULT_PASSWORD <<< "${OS_OPTIONS[$os]}"
            break
        else
            print_status "ERROR" "Invalid selection."
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "VM name (default: $DEFAULT_HOSTNAME): ")" VM_NAME
        VM_NAME="${VM_NAME:-$DEFAULT_HOSTNAME}"
        if validate_input "name" "$VM_NAME"; then
            [[ -f "$VM_DIR/$VM_NAME.conf" ]] && { print_status "ERROR" "VM '$VM_NAME' already exists."; continue; }
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Hostname (default: $VM_NAME): ")" HOSTNAME
        HOSTNAME="${HOSTNAME:-$VM_NAME}"
        validate_input "name" "$HOSTNAME" && break
    done

    while true; do
        read -p "$(print_status "INPUT" "Username (default: $DEFAULT_USERNAME): ")" USERNAME
        USERNAME="${USERNAME:-$DEFAULT_USERNAME}"
        validate_input "username" "$USERNAME" && break
    done

    while true; do
        read -s -p "$(print_status "INPUT" "Password (default: $DEFAULT_PASSWORD): ")" PASSWORD
        PASSWORD="${PASSWORD:-$DEFAULT_PASSWORD}"
        echo
        [[ -n "$PASSWORD" ]] && break || print_status "ERROR" "Password cannot be empty."
    done

    while true; do
        read -p "$(print_status "INPUT" "Disk size (default: 20G): ")" DISK_SIZE
        DISK_SIZE="${DISK_SIZE:-20G}"
        validate_input "size" "$DISK_SIZE" && break
    done

    while true; do
        read -p "$(print_status "INPUT" "Memory in MB (default: 2048): ")" MEMORY
        MEMORY="${MEMORY:-2048}"
        validate_input "number" "$MEMORY" && break
    done

    while true; do
        read -p "$(print_status "INPUT" "CPUs (default: 2): ")" CPUS
        CPUS="${CPUS:-2}"
        validate_input "number" "$CPUS" && break
    done

    while true; do
        read -p "$(print_status "INPUT" "SSH Port (default: 2222): ")" SSH_PORT
        SSH_PORT="${SSH_PORT:-2222}"
        if validate_input "port" "$SSH_PORT"; then
            ss -tln 2>/dev/null | grep -q ":$SSH_PORT " && { print_status "ERROR" "Port $SSH_PORT in use."; continue; }
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Enable GUI? (y/n, default: n): ")" gui_input
        gui_input="${gui_input:-n}"
        GUI_MODE=false
        [[ "$gui_input" =~ ^[Yy]$ ]] && GUI_MODE=true && break
        [[ "$gui_input" =~ ^[Nn]$ ]] && break
        print_status "ERROR" "Please answer y or n"
    done

    read -p "$(print_status "INPUT" "Extra port forwards e.g. 8080:80 (press Enter for none): ")" PORT_FORWARDS

    IMG_FILE="$VM_DIR/$VM_NAME.img"
    SEED_FILE="$VM_DIR/$VM_NAME-seed.iso"
    CREATED="$(date)"

    setup_vm_image
    save_vm_config
}

# --- START VM ---
start_vm() {
    local vm_name=$1
    load_vm_config "$vm_name" || return 1

    print_status "INFO" "Starting VM: $vm_name"
    print_status "INFO" "SSH: ssh -p $SSH_PORT $USERNAME@localhost"
    print_status "INFO" "Password: $PASSWORD"

    [[ ! -f "$IMG_FILE" ]] && { print_status "ERROR" "Image not found: $IMG_FILE"; return 1; }
    [[ ! -f "$SEED_FILE" ]] && { print_status "WARN" "Seed missing, recreating..."; setup_vm_image; }

    local qemu_cmd=(
        qemu-system-x86_64
        -enable-kvm -m "$MEMORY" -smp "$CPUS" -cpu host
        -drive "file=$IMG_FILE,format=qcow2,if=virtio"
        -drive "file=$SEED_FILE,format=raw,if=virtio"
        -boot order=c
        -device virtio-net-pci,netdev=n0
        -netdev "user,id=n0,hostfwd=tcp::$SSH_PORT-:22"
    )

    [[ "$GUI_MODE" == true ]] && qemu_cmd+=(-vga virtio -display gtk,gl=on) || qemu_cmd+=(-nographic -serial mon:stdio)
    qemu_cmd+=(-device virtio-balloon-pci -object rng-random,filename=/dev/urandom,id=rng0 -device virtio-rng-pci,rng=rng0)

    "${qemu_cmd[@]}"
    print_status "INFO" "VM $vm_name shut down."
}

# --- IS VM RUNNING ---
is_vm_running() {
    pgrep -f "qemu-system-x86_64.*$1" >/dev/null
}

# --- STOP VM ---
stop_vm() {
    local vm_name=$1
    load_vm_config "$vm_name" || return 1
    if is_vm_running "$vm_name"; then
        pkill -f "qemu-system-x86_64.*$IMG_FILE" || true
        sleep 2
        is_vm_running "$vm_name" && pkill -9 -f "qemu-system-x86_64.*$IMG_FILE" || true
        print_status "SUCCESS" "VM $vm_name stopped."
    else
        print_status "INFO" "VM $vm_name is not running."
    fi
}

# --- DELETE VM ---
delete_vm() {
    local vm_name=$1
    print_status "WARN" "This will permanently delete VM '$vm_name'!"
    read -p "$(print_status "INPUT" "Are you sure? (y/N): ")" -n 1 -r; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        load_vm_config "$vm_name" && rm -f "$IMG_FILE" "$SEED_FILE" "$VM_DIR/$vm_name.conf"
        print_status "SUCCESS" "VM '$vm_name' deleted."
    else
        print_status "INFO" "Deletion cancelled."
    fi
}

# --- SHOW VM INFO ---
show_vm_info() {
    local vm_name=$1
    load_vm_config "$vm_name" || return 1
    echo ""
    print_status "INFO" "VM Info: $vm_name"
    echo "=============================="
    echo "OS      : $OS_TYPE"
    echo "Hostname: $HOSTNAME"
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
    echo "SSH Port: $SSH_PORT"
    echo "RAM     : $MEMORY MB"
    echo "CPUs    : $CPUS"
    echo "Disk    : $DISK_SIZE"
    echo "GUI     : $GUI_MODE"
    echo "Created : $CREATED"
    echo "=============================="
    echo ""
    read -p "$(print_status "INPUT" "Press Enter to continue...")"
}

# --- MAIN MENU ---
main_menu() {
    while true; do
        display_header
        local vms=($(get_vm_list))
        local vm_count=${#vms[@]}

        if [ $vm_count -gt 0 ]; then
            print_status "INFO" "Existing VMs ($vm_count):"
            for i in "${!vms[@]}"; do
                local status="Stopped"
                is_vm_running "${vms[$i]}" && status="Running"
                printf "  %2d) %s (%s)\n" $((i+1)) "${vms[$i]}" "$status"
            done
            echo ""
        fi

        echo "Options:"
        echo "  1) Create a new VM"
        [ $vm_count -gt 0 ] && echo "  2) Start a VM"
        [ $vm_count -gt 0 ] && echo "  3) Stop a VM"
        [ $vm_count -gt 0 ] && echo "  4) Show VM info"
        [ $vm_count -gt 0 ] && echo "  5) Delete a VM"
        echo "  0) Back to main menu"
        echo ""

        read -p "$(print_status "INPUT" "Enter your choice: ")" choice

        case $choice in
            1) create_new_vm ;;
            2)
                [ $vm_count -gt 0 ] && read -p "$(print_status "INPUT" "VM number to start: ")" n && start_vm "${vms[$((n-1))]}" || true
                ;;
            3)
                [ $vm_count -gt 0 ] && read -p "$(print_status "INPUT" "VM number to stop: ")" n && stop_vm "${vms[$((n-1))]}" || true
                ;;
            4)
                [ $vm_count -gt 0 ] && read -p "$(print_status "INPUT" "VM number for info: ")" n && show_vm_info "${vms[$((n-1))]}" || true
                ;;
            5)
                [ $vm_count -gt 0 ] && read -p "$(print_status "INPUT" "VM number to delete: ")" n && delete_vm "${vms[$((n-1))]}" || true
                ;;
            0) exit 0 ;;
            *) print_status "ERROR" "Invalid option." ;;
        esac

        read -p "$(print_status "INPUT" "Press Enter to continue...")"
    done
}

# --- RUN ---
check_dependencies
main_menu
