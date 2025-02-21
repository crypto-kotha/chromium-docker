#!/bin/bash

mkdir chromium

# Error handling and logging
set -e
LOG_FILE="$HOME/chromium/chromium.log"

function log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

function handle_error() {
    log "ERROR: $1"
    exit 1
}

# Configuration variables
CUSTOM_USER="admin"
PASSWORD="admin"
CHROMIUM_DIR="$HOME/chromium"
NGINX_PORT=15125  # Fixed port for Chromium Nginx

# Stop and remove existing Chromium & Nginx containers
function stop_existing_containers() {
    log "Stopping any existing Chromium and Nginx containers..."
    
    docker stop chromium chromium_nginx 2>/dev/null || true
    docker rm chromium chromium_nginx 2>/dev/null || true
    
    log "Existing Chromium setup stopped successfully."
}

# Setup Chromium with Docker Compose
function setup_chromium() {
    log "Setting up Chromium environment..."
    
    # Remove old config files before regenerating
    rm -rf "$CHROMIUM_DIR"
    mkdir -p "$CHROMIUM_DIR"

    # Create docker-compose.yml for Chromium and Nginx
    cat > "$CHROMIUM_DIR/docker-compose.yml" <<EOF
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    security_opt:
      - seccomp:unconfined
    environment:
      - VNC_USER=${CUSTOM_USER}
      - VNC_PW=${PASSWORD}
      - PUID=$(id -u)
      - PGID=$(id -g)
    volumes:
      - ${CHROMIUM_DIR}/config:/config
    restart: unless-stopped
    shm_size: "2gb"
    networks:
      - chromium_network

  nginx:
    image: nginx:latest
    container_name: chromium_nginx
    volumes:
      - ${CHROMIUM_DIR}/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ${CHROMIUM_DIR}/.htpasswd:/etc/nginx/.htpasswd:ro
    ports:
      - "${NGINX_PORT}:8080"
    depends_on:
      - chromium
    restart: unless-stopped
    networks:
      - chromium_network

networks:
  chromium_network:
    name: chromium_network
EOF

    # Nginx configuration file
    cat > "$CHROMIUM_DIR/nginx.conf" <<EOF
server {
    listen 8080;
    server_name _;

    location / {
        allow 37.111.0.0/16;
        allow 103.112.0.0/16;
        allow 182.160.0.0/16;
        allow 103.228.0.0/16;
        deny all;

        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/.htpasswd;

        proxy_pass http://chromium:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # WebSocket support
        proxy_read_timeout 86400;
        proxy_redirect off;
    }
}
EOF

    # Secure password storage
    htpasswd -bc "$CHROMIUM_DIR/.htpasswd" "$CUSTOM_USER" "$PASSWORD"

    # Stop any existing Chromium instances
    stop_existing_containers

    # Start new containers
    cd "$CHROMIUM_DIR"
    docker-compose up -d || handle_error "Failed to start containers"
}

# Apply UFW firewall rules
function configure_firewall() {
    log "Configuring UFW firewall rules..."

    # Allow access from specific IP ranges
    sudo ufw allow from 37.111.0.0/16 to any port $NGINX_PORT
    sudo ufw allow from 103.112.0.0/16 to any port $NGINX_PORT
    sudo ufw allow from 182.160.0.0/16 to any port $NGINX_PORT
    sudo ufw allow from 103.228.0.0/16 to any port $NGINX_PORT

    # Deny all other connections to Chromium
    sudo ufw deny to any port $NGINX_PORT

    log "Firewall rules applied successfully."
}

# Main Execution
log "Starting Chromium setup with Nginx authentication..."

# Check if docker and docker-compose are installed
if ! command -v docker &>/dev/null; then
    handle_error "Docker is not installed. Please install Docker first."
fi

if ! command -v docker-compose &>/dev/null; then
    handle_error "Docker Compose is not installed. Please install Docker Compose first."
fi

# Run Chromium setup
setup_chromium

# Configure firewall
configure_firewall

# Get public IP securely
PUBLIC_IP=$(wget -qO- --inet4-only http://ipecho.net/plain || wget -qO- --inet4-only http://ifconfig.meet )
log "Setup complete! Access your Chromium instance at: http://${PUBLIC_IP}:${NGINX_PORT}/"
log "Username: ${CUSTOM_USER}"
log "Password: ${PASSWORD}"
