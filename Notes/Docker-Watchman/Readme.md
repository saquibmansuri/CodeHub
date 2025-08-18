# Docker Compose Watchman POC

## Overview
This Proof of Concept shows how to automatically **restart a dependent service (`fe`) whenever the primary service (`api`) starts** (e.g., after a manual restart, crash, or daemon-driven restart). Docker Compose does not natively support “restart B when A restarts,” so we run a tiny **watchman** container that listens to Docker events and enforces the rule.

## docker-compose.yml
```yaml
services:
  api:
    image: nginx:alpine
    restart: always

  fe:
    image: nginx:alpine
    restart: always

  watchman:
    image: docker:cli
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock  # needed to connect with your onhost docker daemon
    command: >
      sh -c "
        docker events --filter 'event=start' --filter 'label=com.docker.compose.service=api' |
        while read line; do
          echo 'API service restarted — so restarting FE service...';
          docker restart $(docker ps -q -f label=com.docker.compose.service=fe);
        done
      "
```
**Why this works without `container_name`:**
Compose automatically adds labels like `com.docker.compose.service=api` and `com.docker.compose.service=fe`. The watchman filters Docker’s event stream by the API label and restarts containers matching the FE label, so no hardcoded names are required.

## How it Works
1. **watchman container** (based on `docker:cli`) is granted access to the host Docker daemon via the mounted socket: `/var/run/docker.sock`.
2. It subscribes to **Docker events** and filters **only** `start` events for containers labeled `com.docker.compose.service=api`.
3. Every time API **starts**, the watchman runs `docker ps -q -f label=com.docker.compose.service=fe` to find the FE container(s) and executes `docker restart` on them.
4. Result: FE restarts **after** API starts, keeping them in sync at the service level (no app-level scripts or health checks needed).

## Quick Start
1. Save the compose file above as `docker-compose.yml`.
2. Bring up the stack:
   ```bash
   docker compose up -d
   ```
3. Tail the watchman logs:
   ```bash
   docker logs -f <watchman container id>
   ```
4. Trigger an API restart (simulating crash recovery or manual restart):
   ```bash
   docker compose restart api
   ```
5. You should see in the watchman logs:
   ```
   API service restarted — so restarting FE service...
   ```
6. Verify FE restarted (fresh uptime):
   ```bash
   docker ps --format "table {{.Names}}	{{.Status}}"
   Or simply do this and check the timings
   docker ps

   ```

## Notes & Limitations
- **Security:** Mounting `/var/run/docker.sock` gives the watchman full control of the Docker daemon. Restrict who can modify or run this stack.
- **Events choice:** We listen to `event=start` (not `event=restart`) because a manual `docker restart` emits `stop` + `start`, and daemon restarts also culminate in a `start` event. This reliably captures all relevant cases.
- **Scaling:** If you scale FE to multiple replicas, `docker ps -q -f label=com.docker.compose.service=fe` returns all FE container IDs, and `docker restart` will restart each of them. If you scale API to multiple replicas, each API start will trigger the FE restart once per starting replica.
- **Delay (optional):** If API needs a moment to become fully ready, you can add a brief delay before restarting FE, e.g., change the watchman command to:
  ```sh
  docker events --filter 'event=start' --filter 'label=com.docker.compose.service=api' |   while read line; do
    echo 'API started — restarting FE after delay...';
    sleep 3;
    docker restart $(docker ps -q -f label=com.docker.compose.service=fe);
  done
  ```

## Troubleshooting
- **watchman can’t connect to Docker:** Ensure the socket is mounted:
  ```yaml
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
  ```
- **No reaction on API restart:** Confirm events appear:
  ```bash
  docker events --filter 'event=start' --filter 'label=com.docker.compose.service=api'
  ```

## Why not `depends_on`?
`depends_on` affects **startup order only** and does not enforce restarts when a dependency restarts later. This POC uses Docker’s **event stream** to enforce *ongoing* restart coupling between services.
