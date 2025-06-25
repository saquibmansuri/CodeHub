#!/bin/bash
set -e

# ===== CONFIGURATION =====
COMPOSE_DIR="/root/myapp"
COMPOSE_FILE="docker-compose-myapp.yml"  # Change this to your actual file if different

# Format: "service_name:memory_limit_in_MB"
SERVICES_WITH_LIMITS=(
  "app:512"   # 0.5GB
  "api:1024"  # 1GB
)

# ===== FUNCTIONS =====
get_container_id() {
  local svc="$1"
  docker ps --filter "name=${svc}" --format "{{.ID}}" | head -n 1
}

get_memory_usage_mb() {
  local cid="$1"
  docker stats --no-stream --format "{{.MemUsage}}" "$cid" | awk -F '[ /]+' '
  {
    val = $1
    unit = toupper($2)
    if (unit == "KB") val = val / 1024
    else if (unit == "MB") val = val
    else if (unit == "GB") val = val * 1024
    printf "%.0f", val
  }'
}

# ===== EXECUTION =====
for entry in "${SERVICES_WITH_LIMITS[@]}"; do
  SERVICE="${entry%%:*}"
  LIMIT_MB="${entry##*:}"

  CONTAINER_ID=$(get_container_id "$SERVICE")

  if [ -z "$CONTAINER_ID" ]; then
    echo "[$(date)] Service '$SERVICE' is not running. Skipping..."
    continue
  fi

  USAGE_MB=$(get_memory_usage_mb "$CONTAINER_ID")

  if [ "$USAGE_MB" -ge "$LIMIT_MB" ]; then
    echo "[$(date)] Service '$SERVICE' exceeded memory limit (${USAGE_MB}MB >= ${LIMIT_MB}MB). Restarting..."
    cd "$COMPOSE_DIR" && docker compose -f "$COMPOSE_FILE" restart "$SERVICE"
  else
    echo "[$(date)] Service '$SERVICE' is within limits (${USAGE_MB}MB < ${LIMIT_MB}MB)."
  fi
done
