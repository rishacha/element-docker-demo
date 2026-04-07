#!/bin/bash

set -e
#set -x

# set up data & secrets dir with the right ownerships in the default location
# to stop docker autocreating them with random owners.
# originally these were checked into the git repo, but that's pretty ugly, so doing it here instead.
mkdir -p data/{element-{web,call},livekit,mas,postgres,synapse}
mkdir -p secrets/{livekit,postgres,synapse}

# create blank secrets to avoid docker creating empty directories in the host
touch secrets/livekit/livekit_{api,secret}_key \
      secrets/postgres/postgres_password \
      secrets/synapse/signing.key

# grab an env if we don't have one already
if [[ ! -e .env  ]]; then
    cp .env-sample .env

    sed -ri.orig "s/^USER_ID=/USER_ID=$(id -u)/" .env
    sed -ri.orig "s/^GROUP_ID=/GROUP_ID=$(id -g)/" .env

    read -p "Enter base domain name (e.g. example.com): " DOMAIN
    sed -ri.orig "s/example.com/$DOMAIN/" .env

    # try to guess your livekit IP
    if [ -x "$(command -v getent)" ]; then
        NODE_IP=`getent hosts livekit.$DOMAIN | cut -d' ' -f1`
        if ! [ -z "$NODE_IP" ]; then
            sed -ri.orig "s/LIVEKIT_NODE_IP=127.0.0.1/LIVEKIT_NODE_IP=$NODE_IP/" .env
        fi
    fi

    echo ""
    echo "=========================================="
    echo "Setup complete!"
    echo "=========================================="
    echo ""
    echo "IMPORTANT: Configure your DNS and Nginx Proxy Manager"
    echo ""
    echo "1. DNS RECORDS (Add these A records in Technitium DNS):"
    echo "   All records should point to your Nginx Proxy Manager IP"
    echo ""
    echo "   - matrix.$DOMAIN       → <NPM_IP>"
    echo "   - auth.$DOMAIN         → <NPM_IP>"
    echo "   - element.$DOMAIN      → <NPM_IP>"
    echo "   - call.$DOMAIN         → <NPM_IP>"
    echo "   - livekit.$DOMAIN      → <NPM_IP>"
    echo "   - livekit-jwt.$DOMAIN  → <NPM_IP>"
    echo "   - mail.$DOMAIN         → <NPM_IP> (optional)"
    echo ""
    echo "2. NGINX PROXY MANAGER - Create these Proxy Hosts:"
    echo "   (Replace <docker_host_ip> with your Docker host IP)"
    echo ""
    echo "   Subdomain              Forward To                  Port   SSL  WebSockets"
    echo "   ─────────────────────  ──────────────────────────  ─────  ───  ──────────"
    echo "   matrix.$DOMAIN         <docker_host_ip>            8008   ✓    ✓"
    echo "   auth.$DOMAIN           <docker_host_ip>            8093   ✓    ✓"
    echo "   element.$DOMAIN        <docker_host_ip>            8090   ✓    ✓"
    echo "   call.$DOMAIN           <docker_host_ip>            8092   ✓    ✓"
    echo "   livekit.$DOMAIN        <docker_host_ip>            7880   ✓    ✓"
    echo "   livekit-jwt.$DOMAIN    <docker_host_ip>            8094   ✓    ✓"
    echo "   mail.$DOMAIN           <docker_host_ip>            8025   ✓    ✓ (optional)"
    echo ""
    echo "3. SPECIAL CONFIGURATIONS:"
    echo ""
    echo "   a) Matrix homeserver (matrix.$DOMAIN) - Add Custom Nginx Configuration:"
    echo "      - client_max_body_size 50M;"
    echo "      - Route /_matrix/client/.*/login|logout|refresh to port 8093 (MAS)"
    echo "      - Route /_matrix/client/.*/sync to port 8081 (Worker)"
    echo "      - Add .well-known endpoints for federation"
    echo ""
    echo "   b) Federation - Create TCP Stream:"
    echo "      - Incoming Port: 8448"
    echo "      - Forward to: <docker_host_ip>:8448"
    echo "      - Enable SSL with matrix.$DOMAIN certificate"
    echo ""
    echo "   c) LiveKit (livekit.$DOMAIN) - Add Custom Nginx Configuration:"
    echo "      - proxy_http_version 1.1;"
    echo "      - proxy_set_header Upgrade \$http_upgrade;"
    echo "      - proxy_set_header Connection \"upgrade\";"
    echo ""
    echo "4. INTERNAL DOCKER SERVICE NAMES (for reference):"
    echo "   Services communicate using these DNS names within Docker:"
    echo ""
    echo "   - postgres:5432           (Database - backend only)"
    echo "   - redis:6379              (Cache - backend only)"
    echo "   - synapse:8008            (Main homeserver)"
    echo "   - synapse-generic-worker-1:8081  (Worker)"
    echo "   - mas:8080                (Auth service)"
    echo "   - mailhog:1025            (SMTP - backend only)"
    echo "   - element-web:80          (Web client)"
    echo "   - element-call:8080       (Call client)"
    echo "   - livekit:7880            (Media server)"
    echo "   - livekit-jwt:8080        (JWT service)"
    echo ""
    echo "See docs/NGINX_PROXY_MANAGER_SETUP.md for detailed configuration"
    echo ""
    echo "You can now run: docker compose up"
    echo ""
    success=true
else
    echo ".env already exists; move it out of the way first to re-setup"
fi

if ! [ -z "$success" ]; then
    echo "Configuration complete; you can now docker compose up"
fi
