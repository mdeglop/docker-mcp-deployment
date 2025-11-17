# Docker MCP Gateway + n8n Deployment Package

Complete deployment package for running Docker MCP Gateway with n8n-MCP on a headless Ubuntu server (Hostinger VPS).

## 📋 What's Included

This package contains everything needed to deploy:
- **Docker MCP Gateway** - Centralized MCP server orchestration
- **n8n-MCP Server** - Workflow documentation and management (39 tools)
- **n8n Instance** - Your existing workflow automation platform
- **12 MCP Servers** - All your currently configured MCP tools
- **Caddy** - Automatic HTTPS reverse proxy
- **Portainer** - Optional web-based Docker management

## 🎯 Your Use Case

**Monitoring & Automation Agent** that can:
- Monitor your website and Supabase database
- Detect issues automatically
- Read from Google Sheets and Supabase
- Propose solutions via AI analysis
- Execute fixes (with confirmation)
- Send notifications
- Create/modify n8n workflows
- Run automated migrations

## 📁 File Structure

```
deployment/
├── README.md                    # This file
├── docker-compose.yml           # Main deployment configuration
├── Caddyfile                    # HTTPS reverse proxy config
├── .env.example                 # Environment variables template
├── deploy.sh                    # Automated deployment script
├── GEMINI_CLI_SETUP.md         # AI CLI integration guide
├── AUTOMATION_WORKFLOWS.md     # Example workflows (coming)
├── DEPLOYMENT_GUIDE.md         # Step-by-step walkthrough (below)
└── mcp-config/
    ├── catalog.yaml            # Your 12 MCP servers configuration
    └── registry.yaml           # Enabled servers tracking
```

## 🚀 Quick Start (5 Minutes)

### Prerequisites

- Hostinger VPS with Ubuntu 24.04 (2 CPU, 8GB RAM, 100GB disk)
- Domain name pointed to your VPS IP
- SSH access to server
- Docker installed (script will install if missing)

### Step 1: Upload Files to Server

```bash
# On your local machine
cd /Users/md6597mac.com/docker_mcp_project/deployment

# Upload to server (replace with your details)
scp -r * user@your-vps-ip:~/docker-mcp/

# SSH into server
ssh user@your-vps-ip
cd ~/docker-mcp
```

### Step 2: Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit with your values
nano .env

# Required values:
# - DOMAIN: your-domain.com
# - N8N_USER: admin (or your choice)
# - N8N_PASSWORD: strong-password-here
# - N8N_MCP_AUTH_TOKEN: (generate with: openssl rand -hex 32)
# - N8N_API_KEY: (get from n8n after first login)
```

**Generate secure tokens:**
```bash
# Auth token (save this!)
openssl rand -hex 32

# Or use this one-liner to set it in .env
echo "N8N_MCP_AUTH_TOKEN=$(openssl rand -hex 32)" >> .env
```

### Step 3: Deploy with Hostinger Docker Manager

**Option A: Using Hostinger Docker Manager UI**
1. Log in to your Hostinger VPS panel
2. Navigate to Docker Manager
3. Click "Import Project"
4. Point to your `docker-compose.yml` location: `~/docker-mcp/docker-compose.yml`
5. Docker Manager will detect and deploy all services

**Option B: Using CLI**
```bash
# Start services
docker compose up -d

# View logs
docker compose logs -f

# Check status
docker compose ps
```

### Step 4: Wait for Services to Start

```bash
# Monitor startup (takes 30-60 seconds)
watch docker compose ps

# Check health
curl http://localhost:5678/healthz    # n8n
curl http://localhost:3000/health     # n8n-MCP
curl http://localhost:8811/health     # MCP Gateway
```

### Step 5: Access & Configure n8n

1. **Access n8n UI**: `https://your-domain.com`
   - Username: (from .env N8N_USER)
   - Password: (from .env N8N_PASSWORD)

2. **Generate n8n API Key**:
   - Go to Settings → API
   - Click "Create API Key"
   - Copy the key

3. **Update .env with API key**:
   ```bash
   nano .env
   # Add: N8N_API_KEY=n8n_api_xxxxxxxxx

   # Restart to apply
   docker compose up -d
   ```

### Step 6: Test MCP Connections

**Test from your laptop:**
```bash
# Test MCP Gateway
curl https://mcp.your-domain.com/health

# Test n8n-MCP
curl https://n8n-mcp.your-domain.com/health

# List n8n-MCP tools (requires auth)
curl -X POST https://n8n-mcp.your-domain.com/mcp \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

## 🎨 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│  Internet                                                    │
│  ├─ https://your-domain.com      → n8n UI                  │
│  ├─ https://mcp.your-domain.com  → MCP Gateway (SSE)       │
│  └─ https://n8n-mcp.your-domain.com/mcp → n8n-MCP Server   │
└─────────────────────────┬───────────────────────────────────┘
                          │ (Caddy - Auto HTTPS)
┌─────────────────────────┴───────────────────────────────────┐
│  Docker Network (172.28.0.0/16)                             │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  MCP Gateway Container (Port 8811)                   │  │
│  │  ├─ context7          (code docs)                    │  │
│  │  ├─ desktop-commander (system ops)                   │  │
│  │  ├─ duckduckgo        (web search)                   │  │
│  │  ├─ github-official   (GitHub ops)                   │  │
│  │  ├─ markdownify       (web to markdown)              │  │
│  │  ├─ memory            (persistent memory)            │  │
│  │  ├─ next-devtools     (Next.js tools)                │  │
│  │  ├─ playwright        (browser automation)           │  │
│  │  ├─ puppeteer         (browser automation)           │  │
│  │  ├─ sequentialthinking (chain-of-thought)            │  │
│  │  ├─ supabase          (database ops)                 │  │
│  │  └─ youtube_transcript (video transcripts)           │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  n8n-MCP Container (Port 3000)                       │  │
│  │  - 23 documentation tools                            │  │
│  │  - 16 workflow management tools                      │  │
│  │  - Connected to n8n API                              │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  n8n Container (Port 5678)                           │  │
│  │  - Workflow automation                               │  │
│  │  - MCP Client Tool node                              │  │
│  │  - AI Agent nodes                                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Caddy Container (Ports 80, 443)                     │  │
│  │  - Automatic HTTPS (Let's Encrypt)                   │  │
│  │  - Reverse proxy for all services                    │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Configuration Details

### Your 12 MCP Servers

All configured based on your local `~/.docker/mcp/registry.yaml`:

1. **context7** - Code documentation (React, Next.js, Vue, etc.)
2. **desktop-commander** - System operations
3. **duckduckgo** - Web search
4. **github-official** - GitHub API operations
5. **markdownify** - Convert web content to markdown
6. **memory** - Persistent context across sessions
7. **next-devtools-mcp** - Next.js development tools
8. **playwright** - Browser automation (E2E testing)
9. **puppeteer** - Browser automation (alternative)
10. **sequentialthinking** - Chain-of-thought reasoning
11. **supabase** - Your Supabase database operations
12. **youtube_transcript** - Video transcripts

### n8n-MCP Server (39 Tools)

**Documentation Tools (23)**:
- `list_nodes` - List all n8n nodes
- `search_nodes` - Search by keyword
- `get_node_info` - Detailed node info
- `get_node_essentials` - Essential properties
- `validate_workflow` - Validate configurations
- And 18 more...

**Workflow Management Tools (16)** - Requires N8N_API_KEY:
- `n8n_create_workflow` - Create workflows
- `n8n_update_workflow` - Update workflows
- `n8n_get_workflow` - Retrieve workflow details
- `n8n_list_workflows` - List all workflows
- `n8n_trigger_webhook_workflow` - Execute workflows
- And 11 more...

## 🔐 Security Configuration

### Firewall (Automatic)

```bash
# Ports opened by deployment:
# - 80/tcp   (HTTP - redirects to HTTPS)
# - 443/tcp  (HTTPS - all services)
# - 22/tcp   (SSH - for management)

# All other ports blocked
# MCP Gateway (8811), n8n (5678), n8n-MCP (3000) only accessible via Caddy
```

### Authentication Layers

1. **MCP Gateway** - SSE transport (future: add auth)
2. **n8n-MCP** - Bearer token authentication
3. **n8n UI** - Basic auth (username/password)
4. **n8n API** - API key authentication

### Rate Limiting

Configured in docker-compose.yml for n8n-MCP:
- 50 requests per 15 minutes per IP
- Protects against brute force attacks

### SSRF Protection

Configured for n8n-MCP:
- `WEBHOOK_SECURITY_MODE=moderate` - Allows localhost n8n, blocks external private IPs
- Cloud metadata endpoints always blocked

## 📊 Resource Usage

**Expected resource consumption:**

| Service | CPU | RAM | Disk |
|---------|-----|-----|------|
| MCP Gateway | 0.5-1.5 cores | 512MB-2GB | ~500MB |
| n8n-MCP | 0.2-0.5 cores | 256MB-512MB | ~300MB |
| n8n | 0.5-1.5 cores | 1GB-3GB | ~2GB + data |
| Caddy | 0.1-0.25 cores | 128MB-256MB | ~50MB |
| **Total** | **~2 cores** | **~4-6GB** | **~3GB + data** |

Your VPS (2 cores, 8GB RAM) is perfect for this!

## 🔍 Monitoring & Management

### Docker Compose Commands

```bash
# View logs
docker compose logs -f                    # All services
docker compose logs -f mcp-gateway       # Specific service
docker compose logs --tail 100 n8n       # Last 100 lines

# Check status
docker compose ps
docker compose ps --all

# Restart service
docker compose restart n8n-mcp

# Stop all
docker compose down

# Stop and remove volumes (careful!)
docker compose down -v

# Update images and restart
docker compose pull
docker compose up -d

# View resource usage
docker stats
```

### Portainer (Web UI)

Access at: `https://portainer.your-domain.com`

Features:
- Visual container management
- Real-time logs
- Resource usage graphs
- Console access to containers
- Quick restart/stop/start

### Health Checks

```bash
# Check all services
curl https://your-domain.com/healthz
curl https://mcp.your-domain.com/health
curl https://n8n-mcp.your-domain.com/health

# Detailed health info
curl https://n8n-mcp.your-domain.com/health | jq
# Shows: status, uptime, memory, version, features
```

## 🚨 Troubleshooting

### Issue: Services Won't Start

```bash
# Check logs for errors
docker compose logs

# Common causes:
# 1. Port already in use
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# 2. Insufficient memory
free -h

# 3. Docker daemon not running
sudo systemctl status docker
sudo systemctl start docker
```

### Issue: Can't Access via Domain

```bash
# Check DNS
nslookup your-domain.com
nslookup mcp.your-domain.com

# Check Caddy logs
docker compose logs caddy

# Check if ports are open
sudo ufw status

# Test locally first
curl http://localhost:5678/healthz
```

### Issue: MCP Tools Not Working

```bash
# Check MCP Gateway logs
docker compose logs mcp-gateway

# List running MCP containers
docker ps | grep mcp/

# Test tool directly
docker exec mcp-gateway docker mcp server ls

# Check network connectivity
docker network inspect docker-mcp_mcp-network
```

### Issue: n8n-MCP Authentication Failed

```bash
# Check auth token length
echo $N8N_MCP_AUTH_TOKEN | wc -c  # Should be 64

# Verify both tokens match in .env
grep AUTH_TOKEN .env

# Test authentication
curl -X POST http://localhost:3000/mcp \
  -H "Authorization: Bearer $N8N_MCP_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

## 📚 Next Steps

1. ✅ Deploy services (you're here!)
2. 📝 Configure Supabase MCP with your credentials
3. 🤖 Set up Gemini CLI for remote access (see GEMINI_CLI_SETUP.md)
4. 🔄 Create monitoring workflows in n8n
5. 📊 Build automation agent (see AUTOMATION_WORKFLOWS.md)
6. 🚀 Test end-to-end monitoring and fixing flow

## 📖 Additional Guides

- **GEMINI_CLI_SETUP.md** - Connect AI CLI tools to remote MCP Gateway
- **AUTOMATION_WORKFLOWS.md** - Example monitoring and automation workflows
- **Local Client Setup** - Configure Claude Desktop on your laptop

## 🆘 Getting Help

- **Check logs**: `docker compose logs -f`
- **Portainer UI**: `https://portainer.your-domain.com`
- **n8n Community**: https://community.n8n.io
- **Docker MCP Issues**: https://github.com/docker/mcp-gateway/issues

## 📝 Maintenance

### Regular Tasks

```bash
# Update all images (monthly)
cd ~/docker-mcp
docker compose pull
docker compose up -d

# Check disk usage
docker system df

# Clean up old images
docker system prune -a

# Backup n8n data
docker run --rm \
  -v docker-mcp_n8n-data:/source:ro \
  -v $(pwd):/backup \
  alpine tar czf /backup/n8n-backup-$(date +%Y%m%d).tar.gz -C /source .

# Backup .env file
cp .env .env.backup
```

### Updating Configuration

```bash
# Edit docker-compose.yml or .env
nano docker-compose.yml

# Apply changes
docker compose up -d

# Watch logs for errors
docker compose logs -f
```

## 🎉 Success!

You now have a complete, production-ready MCP Gateway deployment with:
- ✅ 12 MCP servers accessible remotely
- ✅ n8n-MCP for workflow management (39 tools)
- ✅ n8n for automation workflows
- ✅ Automatic HTTPS
- ✅ Container management UI (Portainer)
- ✅ Ready for AI agent integration

Your monitoring and automation agent can now:
- Check Supabase for errors
- Monitor your website
- Read Google Sheets data
- Propose and execute fixes
- Create n8n workflows
- Send notifications

**Next**: Follow GEMINI_CLI_SETUP.md to connect your AI agents! 🚀
