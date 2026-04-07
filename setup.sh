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
    echo "IMPORTANT: Configure your Nginx Proxy Manager with the following:"
    echo ""
    echo "Services and their ports:"
    echo "  - Synapse (homeserver):        localhost:8008"
    echo "  - Synapse Worker:              localhost:8081"
    echo "  - MAS (auth):                  localhost:8083"
    echo "  - Element Web:                 localhost:8080"
    echo "  - Element Call:                localhost:8082"
    echo "  - LiveKit:                     localhost:7880"
    echo "  - LiveKit JWT:                 localhost:8084"
    echo "  - MailHog (optional):          localhost:8025"
    echo ""
    echo "Federation port 8448 should point to localhost:8448 (LiveKit)"
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
