#!/bin/bash
# Deployment Script for Docker MCP Gateway + n8n on Headless Ubuntu Server
# For Hostinger VPS: 2 CPU, 8GB RAM, 100GB disk, Ubuntu 24.04

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Ubuntu
check_os() {
    log_info "Checking operating system..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" ]]; then
            log_error "This script is designed for Ubuntu. Detected: $ID"
            exit 1
        fi
        log_success "Running on Ubuntu $VERSION"
    else
        log_error "Cannot determine OS"
        exit 1
    fi
}

# Check system resources
check_resources() {
    log_info "Checking system resources..."

    # Check CPU cores
    cpu_cores=$(nproc)
    if [ "$cpu_cores" -lt 2 ]; then
        log_warning "Less than 2 CPU cores detected. Performance may be impacted."
    else
        log_success "CPU cores: $cpu_cores"
    fi

    # Check RAM
    total_ram=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$total_ram" -lt 8 ]; then
        log_warning "Less than 8GB RAM detected. Consider reducing container limits."
    else
        log_success "RAM: ${total_ram}GB"
    fi

    # Check disk space
    available_disk=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_disk" -lt 20 ]; then
        log_error "Less than 20GB disk space available. Please free up space."
        exit 1
    else
        log_success "Available disk space: ${available_disk}GB"
    fi
}

# Install Docker if not present
install_docker() {
    if command -v docker &> /dev/null; then
        log_success "Docker is already installed ($(docker --version))"
    else
        log_info "Installing Docker..."
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker $USER
        log_success "Docker installed successfully"
        log_warning "You may need to log out and back in for group changes to take effect"
    fi
}

# Install Docker Compose if not present
install_docker_compose() {
    if command -v docker compose version &> /dev/null; then
        log_success "Docker Compose is already installed ($(docker compose version))"
    else
        log_info "Installing Docker Compose plugin..."
        sudo apt-get update
        sudo apt-get install -y docker-compose-plugin
        log_success "Docker Compose installed successfully"
    fi
}

# Check if .env file exists
check_env_file() {
    if [ ! -f .env ]; then
        log_error ".env file not found!"
        log_info "Please copy .env.example to .env and configure it:"
        log_info "  cp .env.example .env"
        log_info "  nano .env  # Edit with your values"
        exit 1
    fi

    # Check for required variables
    source .env
    local missing_vars=()

    [ -z "$DOMAIN" ] && missing_vars+=("DOMAIN")
    [ -z "$N8N_USER" ] && missing_vars+=("N8N_USER")
    [ -z "$N8N_PASSWORD" ] && missing_vars+=("N8N_PASSWORD")
    [ -z "$N8N_MCP_AUTH_TOKEN" ] && missing_vars+=("N8N_MCP_AUTH_TOKEN")

    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        log_info "Please edit .env file and add these variables"
        exit 1
    fi

    # Check token length
    if [ ${#N8N_MCP_AUTH_TOKEN} -lt 32 ]; then
        log_error "N8N_MCP_AUTH_TOKEN must be at least 32 characters"
        log_info "Generate with: openssl rand -hex 32"
        exit 1
    fi

    log_success ".env file is properly configured"
}

# Create necessary directories
create_directories() {
    log_info "Creating directory structure..."
    mkdir -p mcp-config mcp-data
    log_success "Directories created"
}

# Pull Docker images
pull_images() {
    log_info "Pulling Docker images (this may take a few minutes)..."

    # Pull with progress
    docker compose pull

    log_success "All images pulled successfully"
}

# Configure firewall
configure_firewall() {
    log_info "Configuring firewall..."

    if command -v ufw &> /dev/null; then
        sudo ufw allow 80/tcp comment "HTTP for Caddy"
        sudo ufw allow 443/tcp comment "HTTPS for Caddy"
        sudo ufw allow 22/tcp comment "SSH"

        # Enable firewall if not already enabled
        sudo ufw --force enable

        log_success "Firewall configured"
    else
        log_warning "UFW not found, skipping firewall configuration"
    fi
}

# Start services
start_services() {
    log_info "Starting services..."

    # Start in detached mode
    docker compose up -d

    log_success "Services started"

    # Wait for services to be healthy
    log_info "Waiting for services to be healthy (this may take 30-60 seconds)..."
    sleep 10

    # Check service status
    docker compose ps
}

# Check service health
check_health() {
    log_info "Checking service health..."

    local max_attempts=12
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        # Check n8n
        if curl -f -s http://localhost:5678/healthz > /dev/null 2>&1; then
            log_success "n8n is healthy"
            break
        fi

        attempt=$((attempt + 1))
        if [ $attempt -lt $max_attempts ]; then
            log_info "Waiting for n8n... (attempt $attempt/$max_attempts)"
            sleep 5
        else
            log_warning "n8n health check timed out"
        fi
    done

    # Check n8n-mcp
    if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
        log_success "n8n-MCP is healthy"
    else
        log_warning "n8n-MCP health check failed"
    fi

    # Check MCP Gateway
    if curl -f -s http://localhost:8811/health > /dev/null 2>&1; then
        log_success "MCP Gateway is healthy"
    else
        log_warning "MCP Gateway health check failed"
    fi
}

# Display connection information
display_info() {
    source .env

    echo ""
    log_success "==================================================================="
    log_success "Deployment Complete!"
    log_success "==================================================================="
    echo ""
    log_info "Your services are now running:"
    echo ""
    echo "  📊 n8n Workflow UI:"
    echo "     https://${DOMAIN}"
    echo "     Username: ${N8N_USER}"
    echo "     Password: ${N8N_PASSWORD}"
    echo ""
    echo "  🔌 MCP Gateway (for remote clients):"
    echo "     https://mcp.${DOMAIN}"
    echo ""
    echo "  📚 n8n-MCP Server (for n8n MCP Client Tool):"
    echo "     https://n8n-mcp.${DOMAIN}/mcp"
    echo "     Auth Token: ${N8N_MCP_AUTH_TOKEN}"
    echo ""
    echo "  🐳 Portainer (container management):"
    echo "     https://portainer.${DOMAIN}"
    echo ""
    log_info "Next steps:"
    echo "  1. Wait 2-3 minutes for SSL certificates to be issued"
    echo "  2. Access n8n at https://${DOMAIN}"
    echo "  3. Generate n8n API key: Settings → API → Create API Key"
    echo "  4. Update .env with N8N_API_KEY and restart: docker compose up -d"
    echo "  5. Configure your local Claude Desktop to connect to MCP Gateway"
    echo ""
    log_warning "IMPORTANT: Save your credentials securely!"
    log_warning "MCP Auth Token: ${N8N_MCP_AUTH_TOKEN}"
    echo ""
}

# Main deployment flow
main() {
    echo ""
    log_info "==================================================================="
    log_info "Docker MCP Gateway + n8n Deployment"
    log_info "==================================================================="
    echo ""

    check_os
    check_resources
    install_docker
    install_docker_compose
    check_env_file
    create_directories
    configure_firewall
    pull_images
    start_services
    check_health
    display_info

    log_success "Deployment script completed!"
    log_info "View logs with: docker compose logs -f"
    log_info "Stop services: docker compose down"
    log_info "Update services: docker compose pull && docker compose up -d"
    echo ""
}

# Run main function
main "$@"
