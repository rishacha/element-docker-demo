# element-docker-demo

element-docker-demo is a minimal example of how to rapidly stand up a Matrix 2.0 stack on macOS or Linux using Docker,
featuring:

 * Element Web
 * Element Call
 * Synapse
 * Matrix Authentication Service
 * LiveKit
 * Postgres

**This version has been modified to work with external reverse proxy (Nginx Proxy Manager, Traefik, Caddy, etc.) instead of bundled nginx.**

This is **not** intended for serious production usage, but instead as a tool for curious sysadmins to easily experiment
with Matrix 2.0 in a simple docker compose environment.  As of Nov 2024, it's considered beta.

In particular, this has:
 * No support, security or maintenance guarantees whatsoever
 * No high availability, horizontal scalability, elastic scaling, clustering, backup etc.
 * No admin interface
 * No monitoring
 * No fancy config management (eg ansible), just env vars and templates
 * No fancy secret management (stored in plaintext on disk)
 * No UDP traffic or TURN for LiveKit (all traffic is tunnelled over TCP for simplicity)
 * No push server, integration manager, integrations, or identity lookup server
 * No bundled reverse proxy (you must use your own - Nginx Proxy Manager, Traefik, Caddy, etc.)

For production-grade Matrix from Element, please see https://element.io/server-suite (ESS).

## Prerequisites

 1. Install [Docker Compose](https://docs.docker.com/compose/install/)
 2. Have a reverse proxy ready (Nginx Proxy Manager, Traefik, Caddy, etc.)
 3. Configure DNS to point your domain and subdomains to your reverse proxy

## To run

```bash
./setup.sh

# Configure your reverse proxy according to NGINX_PROXY_MANAGER_SETUP.md
# (or adapt for your reverse proxy of choice)

docker compose up
# Access Element Web at https://element.yourdomain.com
```

**For Nginx Proxy Manager users:** See [NGINX_PROXY_MANAGER_SETUP.md](NGINX_PROXY_MANAGER_SETUP.md) for detailed configuration instructions.

![docker demo](https://github.com/user-attachments/assets/c17e42f7-3442-478a-9ae4-ad2709885386)

Watch the full video:

<div align="left">
      <a href="https://www.youtube.com/watch?v=6iMi5BiQcoI">
         <img src="https://img.youtube.com/vi/6iMi5BiQcoI/maxresdefault.jpg" style="width:100%; border: 1px solid">
      </a>
</div>
<br/>

For more info, see https://element.io/blog/experimenting-with-matrix-2-0-using-element-docker-demo/

## Exposed Ports

The following ports are exposed for your reverse proxy to connect to:

| Service | Port | Purpose |
|---------|------|---------|
| Synapse | 8008 | Main homeserver API |
| Synapse Worker | 8081 | Sync endpoints |
| MAS | 8083 | Authentication service |
| Element Web | 8080 | Web client |
| Element Call | 8082 | Video calling |
| LiveKit | 7880 | Media server HTTP |
| LiveKit | 7881 | WebRTC transport (TCP) |
| LiveKit | 8448 | Federation port |
| LiveKit JWT | 8084 | JWT service |
| MailHog | 8025 | Email testing UI |

## To configure

Check the .env file, or customise the templates in `/data-templates` and then `docker compose down && docker compose up -d`.

In particular, you may wish to:
 * Point at your own SMTP server rather than mailhog
 * Use your own database cluster
 * Adjust the LIVEKIT_NODE_IP to your public IP

Container data gets stored in `./data`, and secrets in `./secrets`.
N.B. that config files in `./data` will get overwritten by the templates from `./data-template` every time the cluster
is launched.

## To admin

```bash
# To upgrade
docker compose pull
```

```bash
# To register a user
docker compose exec mas mas-cli -c /data/config.yaml manage register-user
```

## Diagnostics

```bash
# check that OIDC is working - useful for debugging TLS problems
docker compose exec mas mas-cli -c /data/config.yaml doctor
````

## Other resources

 * This was originally based on https://github.com/element-hq/synapse/tree/master/contrib/docker_compose_workers
 * Other guides for MAS and Element Call from Sebastian Späth at:
   * https://sspaeth.de/2024/08/matrix-server-with-nextcloud-login/
   * https://sspaeth.de/2024/11/sfu/
 * https://cyberhost.uk/element-matrix-setup/ is a good Matrix 1.0 docker-compose guide too

## Todo

 * [ ] pop up https://element in your browser once synapse has started up successfully for the first time, perhaps
 * [ ] test $VOLUME_PATH (or remove it)
 * [ ] swap nginx for caddy or traefik to simplify Letsencrypt
 * [ ] set up livekit TURN (tcp & udp port 443) for better firewall traversal and voip performance
