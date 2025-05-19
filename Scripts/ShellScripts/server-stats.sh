#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
SEPARATOR="${CYAN}======================================${NC}"

echo -e "${CYAN}======================================"
echo -e "            Server Stats"
echo -e "======================================${NC}"

# Server IP
IP=$(hostname -I | awk '{print $1}')
echo -e "${YELLOW}Server IP:${NC} $IP"
echo -e "$SEPARATOR"

# OS Info
echo -e "${YELLOW}OS Info:${NC} $(lsb_release -d | cut -f2-)"
echo -e "$SEPARATOR"

# CPU Uptime
echo -e "${YELLOW}CPU Uptime:${NC} $(uptime -p)"
echo -e "$SEPARATOR"

# CPU Usage (updated to calculate total used CPU percentage)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%.1f%%", $2 + $4 + $6 + $10 + $12 + $14}')
echo -e "${YELLOW}CPU Usage:${NC} $CPU_USAGE"
echo -e "$SEPARATOR"

# Memory Usage with percentages
MEM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/^Mem:/ {print $3}')
MEM_AVAILABLE=$(free -m | awk '/^Mem:/ {print $7}')
MEM_USED_PERCENT=$(awk "BEGIN {printf \"%.1f\", ${MEM_USED}/${MEM_TOTAL}*100}")
MEM_AVAILABLE_PERCENT=$(awk "BEGIN {printf \"%.1f\", ${MEM_AVAILABLE}/${MEM_TOTAL}*100}")

echo -e "${YELLOW}Memory Usage:${NC}"
echo -e "  Total: $MEM_TOTAL MB"
echo -e "  Used:  $MEM_USED MB (${MEM_USED_PERCENT}%)"
echo -e "  Available: $MEM_AVAILABLE MB (${MEM_AVAILABLE_PERCENT}%)"
echo -e "$SEPARATOR"

# Disk Usage (Updated format)
echo -e "${YELLOW}Disk Usage:${NC}"
ROOT_DISK=$(df -h / | awk 'NR==2 {print $2","$3","$4","$5}')
IFS=',' read -r total used available percent <<< "$ROOT_DISK"
echo -e "Disk Size      : $total"
echo -e "Used Space     : $used ($percent)"
echo -e "Available Space: $available ($(echo "100 - ${percent%\%}" | bc)%)"
echo -e "$SEPARATOR"

# Top 5 Processes by CPU
echo -e "${YELLOW}Top 5 Processes by CPU:${NC}"
ps -eo user,pid,pcpu,pmem,comm --sort=-pcpu | head -n 6
echo -e "$SEPARATOR"

# Top 5 Processes by Memory
echo -e "${YELLOW}Top 5 Processes by Memory:${NC}"
ps -eo user,pid,pcpu,pmem,comm --sort=-pmem | head -n 6
echo -e "$SEPARATOR"

# Docker Stats
if command -v docker &> /dev/null
then
    echo -e "${YELLOW}Docker Containers:${NC}"
    printf "%-30s %-50s %-s\n" "NAME" "PORTS" "COMPOSE FILE"
    while IFS= read -r container; do
        name=$(echo "$container" | awk '{print $1}')
        ports=$(echo "$container" | awk '{$1=""; print $0}' | sed 's/^[ \t]*//')
        compose_file=$(docker inspect --format='{{index .Config.Labels "com.docker.compose.project.config_files"}}' "$name")
        if [ -z "$compose_file" ]; then
            compose_file="N/A"
        fi
        printf "%-30s %-50s %-s\n" "$name" "$ports" "$compose_file"
    done < <(docker ps --format "{{.Names}} {{.Ports}}")
    echo -e "$SEPARATOR"
    
    echo -e "${YELLOW}Docker Stats (all containers):${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
    echo -e "$SEPARATOR"
else
    echo -e "${YELLOW}Docker is not installed or not running.${NC}"
    echo -e "$SEPARATOR"
fi
