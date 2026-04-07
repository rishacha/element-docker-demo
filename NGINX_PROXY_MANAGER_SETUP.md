# Nginx Proxy Manager Configuration Guide

This guide explains how to configure Nginx Proxy Manager to work with your Element Docker Demo setup.

## Overview

Since nginx and certbot have been removed from the docker-compose setup, you'll use your existing Nginx Proxy Manager running on Proxmox to handle SSL termination and reverse proxy functionality.

## Prerequisites

- Nginx Proxy Manager running on Proxmox
- Technitium DNS configured with appropriate DNS records
- All subdomains pointing to your Nginx Proxy Manager IP

## DNS Configuration (Technitium DNS)

Create A records for the following subdomains pointing to your Nginx Proxy Manager IP:

```
example.com           -> <NPM_IP>
matrix.example.com    -> <NPM_IP>
auth.example.com      -> <NPM_IP>
element.example.com   -> <NPM_IP>
call.example.com      -> <NPM_IP>
livekit.example.com   -> <NPM_IP>
livekit-jwt.example.com -> <NPM_IP>
```

Replace `example.com` with your actual domain and `<NPM_IP>` with your Nginx Proxy Manager IP address.

## Service Ports

The following services are exposed and need to be proxied:

| Service | Internal Port | Domain | Notes |
|---------|--------------|--------|-------|
| Synapse (main) | 8008 | matrix.example.com | Main homeserver |
| Synapse Worker | 8081 | matrix.example.com | For sync endpoints |
| MAS (Auth) | 8083 | auth.example.com | Authentication service |
| Element Web | 8080 | element.example.com | Web client |
| Element Call | 8082 | call.example.com | Video calling |
| LiveKit | 7880 | livekit.example.com | Media server |
| LiveKit JWT | 8084 | livekit-jwt.example.com | JWT service |
| MailHog (optional) | 8025 | mail.example.com | Email testing |
| Federation | 8448 | matrix.example.com | Federation port |

## Nginx Proxy Manager Configuration

### 1. Base Domain (example.com)

**Proxy Host Settings:**
- Domain Names: `example.com`
- Scheme: `http`
- Forward Hostname/IP: `<docker_host_ip>`
- Forward Port: `8080` (Element Web)
- Cache Assets: ✓
- Block Common Exploits: ✓
- Websockets Support: ✓

**Custom Locations:**

Add location for `.well-known` (for Matrix federation):
```nginx
location /.well-known/matrix/server {
    return 200 '{"m.server": "matrix.example.com:443"}';
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
}

location /.well-known/matrix/client {
    return 200 '{"m.homeserver": {"base_url": "https://matrix.example.com"},"m.identity_server": {"base_url": "https://vector.im"}}';
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
}

location /.well-known/openid-configuration {
    proxy_pass http://<docker_host_ip>:8083;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

**SSL:** Enable SSL with Let's Encrypt or your preferred certificate

### 2. Matrix Homeserver (matrix.example.com)

**Proxy Host Settings:**
- Domain Names: `matrix.example.com`
- Scheme: `http`
- Forward Hostname/IP: `<docker_host_ip>`
- Forward Port: `8008`
- Cache Assets: ✗
- Block Common Exploits: ✓
- Websockets Support: ✓

**Custom Nginx Configuration:**
```nginx
# Increase upload size for media
client_max_body_size 50M;

# Pass auth endpoints to MAS
location ~ ^/_matrix/client/(.*)/(login|logout|refresh) {
    proxy_pass http://<docker_host_ip>:8083;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Use generic worker for sync endpoints
location ~ ^/_matrix/client/(r0|v3)/sync$ {
    proxy_pass http://<docker_host_ip>:8081;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

location ~ ^/_matrix/client/(api/v1|r0|v3)/events$ {
    proxy_pass http://<docker_host_ip>:8081;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

location ~ ^/_matrix/client/(api/v1|r0|v3)/initialSync$ {
    proxy_pass http://<docker_host_ip>:8081;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

location ~ ^/_matrix/client/(api/v1|r0|v3)/rooms/[^/]+/initialSync$ {
    proxy_pass http://<docker_host_ip>:8081;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

**SSL:** Enable SSL with Let's Encrypt

### 3. Federation Port (matrix.example.com:8448)

**Stream Configuration (TCP):**
- Incoming Port: `8448`
- Forward Host: `<docker_host_ip>`
- Forward Port: `8448`
- Enable SSL: ✓ (use same certificate as matrix.example.com)

### 4. MAS Authentication (auth.example.com)

**Proxy Host Settings:**
- Domain Names: `auth.example.com`
- Scheme: `http`
- Forward Hostname/IP: `<docker_host_ip>`
- Forward Port: `8083`
- Cache Assets: ✗
- Block Common Exploits: ✓
- Websockets Support: ✓

**SSL:** Enable SSL with Let's Encrypt

### 5. Element Web (element.example.com)

**Proxy Host Settings:**
- Domain Names: `element.example.com`
- Scheme: `http`
- Forward Hostname/IP: `<docker_host_ip>`
- Forward Port: `8080`
- Cache Assets: ✓
- Block Common Exploits: ✓
- Websockets Support: ✓

**SSL:** Enable SSL with Let's Encrypt

### 6. Element Call (call.example.com)

**Proxy Host Settings:**
- Domain Names: `call.example.com`
- Scheme: `http`
- Forward Hostname/IP: `<docker_host_ip>`
- Forward Port: `8082`
- Cache Assets: ✓
- Block Common Exploits: ✓
- Websockets Support: ✓

**SSL:** Enable SSL with Let's Encrypt

### 7. LiveKit (livekit.example.com)

**Proxy Host Settings:**
- Domain Names: `livekit.example.com`
- Scheme: `http`
- Forward Hostname/IP: `<docker_host_ip>`
- Forward Port: `7880`
- Cache Assets: ✗
- Block Common Exploits: ✓
- Websockets Support: ✓ (REQUIRED)

**Custom Nginx Configuration:**
```nginx
# WebSocket support
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

**SSL:** Enable SSL with Let's Encrypt

### 8. LiveKit JWT (livekit-jwt.example.com)

**Proxy Host Settings:**
- Domain Names: `livekit-jwt.example.com`
- Scheme: `http`
- Forward Hostname/IP: `<docker_host_ip>`
- Forward Port: `8084`
- Cache Assets: ✗
- Block Common Exploits: ✓
- Websockets Support: ✓

**SSL:** Enable SSL with Let's Encrypt

### 9. MailHog (Optional - mail.example.com)

**Proxy Host Settings:**
- Domain Names: `mail.example.com`
- Scheme: `http`
- Forward Hostname/IP: `<docker_host_ip>`
- Forward Port: `8025`
- Cache Assets: ✗
- Block Common Exploits: ✓
- Websockets Support: ✓

**SSL:** Enable SSL with Let's Encrypt

## HTTP Configuration

Since you mentioned Element Mobile works with HTTP, you can configure NPM to work with HTTP by:

1. **Disable Force SSL** in each proxy host configuration
2. **Use HTTP scheme** instead of HTTPS in your .env file URLs
3. **Skip SSL certificate** configuration in NPM

However, for production use, HTTPS is strongly recommended for security.

## Firewall Configuration

Ensure the following ports are open on your Proxmox firewall:

- `80` (HTTP) - for Let's Encrypt validation
- `443` (HTTPS) - for all web traffic
- `8448` (TCP) - for Matrix federation

## Testing

After configuration, test each service:

```bash
# Test homeserver
curl https://matrix.example.com/_matrix/client/versions

# Test federation
curl https://matrix.example.com:8448/_matrix/federation/v1/version

# Test Element Web
curl https://element.example.com

# Test MAS
curl https://auth.example.com/.well-known/openid-configuration
```

## Troubleshooting

### WebSocket Connection Issues
- Ensure "Websockets Support" is enabled in NPM
- Check that `proxy_http_version 1.1` is set for LiveKit

### Federation Not Working
- Verify port 8448 is forwarded correctly
- Check `.well-known` endpoints are accessible
- Ensure DNS records are correct

### Authentication Issues
- Verify MAS is accessible at auth.example.com
- Check that login/logout endpoints are proxied to MAS (port 8083)
- Ensure OIDC configuration is correct in Synapse

### Media Upload Issues
- Increase `client_max_body_size` in Matrix homeserver proxy configuration
- Default is 50M, adjust as needed

## Notes

- Replace `<docker_host_ip>` with the actual IP address of your Docker host
- Replace `example.com` with your actual domain throughout
- All services run on HTTP internally; NPM handles SSL termination
- The federation port (8448) must be accessible externally for federation to work
- LiveKit requires WebSocket support for real-time communication