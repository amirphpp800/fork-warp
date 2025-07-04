#!/bin/bash

# WARP Scanner v1.3.80
# An optimized version of Ptechgithub with WHA support and improved UI

# Colors
RED='\033[1;31m'      # Brighter red
GREEN='\033[1;32m'    # Brighter green
YELLOW='\033[1;33m'   # Brighter yellow
BLUE='\033[1;34m'     # Brighter blue
PURPLE='\033[1;35m'   # Brighter purple
CYAN='\033[1;36m'     # Brighter cyan
WHITE='\033[1;37m'    # Bright white
NC='\033[0m'          # No Color

# Version
VERSION="1.3.80"

# Testing Parameters
PING_COUNT=5          # Number of pings per IP
TIMEOUT=2             # Timeout in seconds
MIN_SUCCESS_RATE=80   # Minimum success rate required (%)

# Loading animation
show_loading() {
    local pid=$1
    local delay=0.2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " %c  Scanning endpoints..." "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        echo -en "\r"
        sleep $delay
    done
    echo -en "\r"
}

# Generate WireGuard URL for v2ray
generate_wireguard_url() {
    local ip=$1
    local private_key=$(wg genkey)
    # Extract IP and port from the best_ip (format: IP:PORT)
    local base_ip=$(echo "$ip" | cut -d':' -f1)
    local port=$(echo "$ip" | cut -d':' -f2)
    local url="wireguard://${private_key}@${base_ip}:${port}?address=172.16.0.2/32&presharedkey=&reserved=125,208,143&publickey=bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=&mtu=1280#@void1x0"
    echo "$url"
}

# ASCII Art Header
print_header() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${PURPLE}             WARP SCANNER              ${BLUE}║${NC}"
    echo -e "${BLUE}║${CYAN}      An optimized version of Ptechgithub    ${BLUE}║${NC}"
    echo -e "${BLUE}║${CYAN}               Version ${VERSION}              ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
    echo -e "${PURPLE}              By: void1x0${NC}\n"
}

# Check CPU architecture
check_cpu() {
    case "$(uname -m)" in
        x86_64 | x64 | amd64)
            cpu=amd64
            ;;
        i386 | i686)
            cpu=386
            ;;
        armv8 | armv8l | arm64 | aarch64)
            cpu=arm64
            ;;
        armv7l)
            cpu=arm
            ;;
        *)
            echo -e "${RED}Error: Architecture $(uname -m) not supported${NC}"
            exit 1
            ;;
    esac
}

# Setup warpendpoint
setup_warpendpoint() {
    if [[ ! -f "$PREFIX/bin/warpendpoint" ]]; then
        echo -e "${CYAN}Downloading warpendpoint program...${NC}"
        if [[ -n $cpu ]]; then
            curl -L -o warpendpoint -# --retry 2 "https://raw.githubusercontent.com/void1x0/warp/main/endip/$cpu"
            cp warpendpoint $PREFIX/bin
            chmod +x $PREFIX/bin/warpendpoint
        fi
    fi
}

# Generate IPv4 endpoints
generate_ipv4() {
    n=0
    iplist=100
    while [ $n -lt $iplist ]; do
        temp[$n]=$(echo "162.159.192.$(($RANDOM % 256))")
        n=$(($n + 1))
        [ $n -ge $iplist ] && break
        temp[$n]=$(echo "162.159.193.$(($RANDOM % 256))")
        n=$(($n + 1))
        [ $n -ge $iplist ] && break
        temp[$n]=$(echo "162.159.195.$(($RANDOM % 256))")
        n=$(($n + 1))
        [ $n -ge $iplist ] && break
        temp[$n]=$(echo "188.114.96.$(($RANDOM % 256))")
        n=$(($n + 1))
        [ $n -ge $iplist ] && break
        temp[$n]=$(echo "188.114.97.$(($RANDOM % 256))")
        n=$(($n + 1))
        [ $n -ge $iplist ] && break
        temp[$n]=$(echo "188.114.98.$(($RANDOM % 256))")
        n=$(($n + 1))
        [ $n -ge $iplist ] && break
        temp[$n]=$(echo "188.114.99.$(($RANDOM % 256))")
        n=$(($n + 1))
         temp[$n]=$(echo "172.64.240.$(($RANDOM % 256))")
        n=$(($n + 1))
        [ $n -ge $iplist ] && break
        temp[$n]=$(echo "172.64.245.$(($RANDOM % 256))")
        n=$(($n + 1))
        [ $n -ge $iplist ] && break
        temp[$n]=$(echo "172.67.$(($RANDOM % 256)).$(($RANDOM % 256))")
        n=$(($n + 1))
        [ $n -ge $iplist ] && break
        temp[$n]=$(echo "172.68.$(($RANDOM % 256)).$(($RANDOM % 256))")
        n=$(($n + 1))
    done
}

# Generate IPv6 endpoints
generate_ipv6() {
    n=0
    iplist=100
    while [ $n -lt $iplist ]; do
        temp[$n]=$(echo "[2606:4700:d0::$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2)))]")
        n=$(($n + 1))
        [ $n -ge $iplist ] && break
        temp[$n]=$(echo "[2606:4700:d1::$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2)))]")
        n=$(($n + 1))
        temp[$n]=$(echo "[2606:4700:311c::$(printf '%x' $(($RANDOM % 65536))):$(printf '%x' $(($RANDOM % 65536))):$(printf '%x' $(($RANDOM % 65536))):$(printf '%x' $(($RANDOM % 65536)))]")
        n=$(($n + 1))
    done
}

# Process and display results
process_results() {
    echo "${temp[@]}" | sed -e 's/ /\n/g' | sort -u > ip.txt
    ulimit -n 102400
    chmod +x warpendpoint >/dev/null 2>&1

    # Show loading animation while scanning
    warpendpoint & 
    show_loading $!
    wait

    # Check if warpendpoint was successful
    if [ ! -f "result.csv" ]; then
        echo -e "${RED}Error: Failed to generate results. Please try again.${NC}"
        exit 1
    fi

    clear
    echo -e "${BLUE}╔═════════════ SCAN RESULTS ═════════════╗${NC}"
    # Show detailed test results including packet loss and jitter
    cat result.csv | awk -F, '$3!="timeout ms" {print} ' | sort -t, -nk2 -nk3 | uniq | head -11 | \
        awk -F, '{
            success_rate = 100 - $2
            quality = "Poor"
            if (success_rate >= 95 && $3 <= 100) quality = "Excellent"
            else if (success_rate >= 90 && $3 <= 150) quality = "Good"
            else if (success_rate >= 85 && $3 <= 200) quality = "Fair"
            printf "║ %-25s │ %5.1f%% │ %-6s │ %-9s ║\n", $1, success_rate, $3, quality
        }'
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}\n"

    best_ip=$(cat result.csv | awk -F, 'NR==2 {print $1}')
    delay=$(cat result.csv | grep -oE "[0-9]+ ms|timeout" | head -n 1)
    success_rate=$(cat result.csv | awk -F, 'NR==2 {print 100-$2}')

    # Generate URLs
    wha_url="warp://${best_ip}/?ifp=5-10@void1x0"
    wireguard_url=$(generate_wireguard_url "$best_ip")

    echo -e "${PURPLE}Best Endpoint Found:${NC}"
    echo -e "${WHITE}$best_ip${NC}"
    echo -e "${YELLOW}Delay: $delay │ Success Rate: ${success_rate}%${NC}\n"

    echo -e "${PURPLE}Warp Hiddify App (WHA) URL:${NC}"
    echo -e "${WHITE}$wha_url${NC}\n"

    echo -e "${PURPLE}WireGuard URL for v2ray:${NC}"
    echo -e "${WHITE}$wireguard_url${NC}\n"

    # Cleanup
    rm -f warpendpoint ip.txt 2>/dev/null
}

# Main menu
show_menu() {
    echo -e "${BLUE}╔═════════════ SELECT MODE ════════════╗${NC}"
    echo -e "${BLUE}║${NC} ${GREEN}1${NC}. Scan for IPv4 Endpoints          ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC} ${GREEN}2${NC}. Scan for IPv6 Endpoints          ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC} ${RED}0${NC}. Exit                             ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo -en "${CYAN}Enter your choice: ${NC}"
}

# Main execution
main() {
    print_header
    check_cpu
    setup_warpendpoint

    while true; do
        show_menu
        read -r choice

        case "$choice" in
            1)
                echo -e "\n${CYAN}Starting IPv4 endpoint scan...${NC}"
                generate_ipv4
                process_results
                ;;
            2)
                echo -e "\n${CYAN}Starting IPv6 endpoint scan...${NC}"
                generate_ipv6
                process_results
                ;;
            0)
                echo -e "\n${GREEN}Thank you for using WARP Scanner!${NC}"
                exit 0
                ;;
            *)
                echo -e "\n${RED}Invalid choice. Please try again.${NC}"
                ;;
        esac
    done
}

# Start the application
main
