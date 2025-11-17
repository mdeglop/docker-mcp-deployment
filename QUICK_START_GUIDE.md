# 🚀 Quick Start Guide - 30 Minute Deployment

**Goal**: Get Docker MCP Gateway + n8n + n8n-MCP running on your Hostinger VPS in 30 minutes.

## Prerequisites Checklist

- [ ] Hostinger VPS (Ubuntu 24.04, 2 CPU, 8GB RAM)
- [ ] Domain name pointed to VPS IP
- [ ] SSH access to server
- [ ] This deployment folder

## 30-Minute Deployment

### Minute 0-5: Upload & Setup

```bash
# 1. Upload files (from your laptop)
cd /Users/md6597mac.com/docker_mcp_project/deployment
scp -r * user@your-vps-ip:~/docker-mcp/

# 2. SSH to server
ssh user@your-vps-ip

# 3. Navigate to deployment
cd ~/docker-mcp
```

### Minute 5-10: Configure Environment

```bash
# 1. Create .env from template
cp .env.example .env

# 2. Generate auth token
AUTH_TOKEN=$(openssl rand -hex 32)
echo "Your token (SAVE THIS!): $AUTH_TOKEN"

# 3. Edit .env
nano .env

# Set these values:
# DOMAIN=your-domain.com
# N8N_USER=admin
# N8N_PASSWORD=create-strong-password-here
# N8N_MCP_AUTH_TOKEN=<paste-token-from-above>

# Optional (set later):
# N8N_API_KEY=<get-after-first-login>
# SUPABASE_URL=<your-supabase-url>
# SUPABASE_SERVICE_ROLE_KEY=<your-key>

# Save and exit (Ctrl+X, Y, Enter)
```

### Minute 10-15: Deploy

**Option A: Hostinger Docker Manager** (Recommended)
```
1. Open Hostinger panel in browser
2. Go to "Docker Manager"
3. Click "Import Project"
4. Select: ~/docker-mcp/docker-compose.yml
5. Click "Deploy"
6. Done! (Docker Manager handles everything)
```

**Option B: Command Line**
```bash
# Check Docker is installed
docker --version

# If not installed:
curl -fsSL https://get.docker.com | sh

# Deploy
docker compose up -d

# Check status
docker compose ps
```

### Minute 15-20: Wait & Verify

```bash
# Watch services start (wait 30-60 seconds)
docker compose logs -f

# Once you see "Server started" messages, press Ctrl+C

# Check health
curl http://localhost:5678/healthz    # n8n
curl http://localhost:3000/health     # n8n-MCP
curl http://localhost:8811/health     # MCP Gateway

# All should return "ok" or healthy status
```

### Minute 20-25: First Login

```bash
# 1. Open browser: https://your-domain.com
# (If DNS not propagated yet, use: http://VPS-IP:5678)

# 2. Log in:
#    Username: (from .env N8N_USER)
#    Password: (from .env N8N_PASSWORD)

# 3. Go to: Settings → API → Create API Key
# 4. Copy the API key (starts with n8n_api_)

# 5. Add to .env on server:
echo "N8N_API_KEY=n8n_api_paste_here" >> .env

# 6. Restart services
docker compose up -d
```

### Minute 25-30: Connect Laptop

```bash
# On your laptop, edit Claude Desktop config
# macOS: ~/.claude/config.json

{
  "mcpServers": {
    "remote-mcp": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/mcp-remote@latest",
        "connect",
        "https://mcp.your-domain.com"
      ]
    },
    "n8n-mcp": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/mcp-remote@latest",
        "connect",
        "https://n8n-mcp.your-domain.com/mcp"
      ],
      "env": {
        "MCP_AUTH_TOKEN": "paste-token-from-env"
      }
    }
  }
}

# Restart Claude Desktop
```

## ✅ Success Test

### In Claude Desktop, try:

```
1. "List all available MCP tools"
   Expected: See tools from 12 MCP servers + 39 n8n-MCP tools

2. "Use n8n-MCP to list my workflows"
   Expected: Shows your n8n workflows

3. "Use DuckDuckGo to search for 'Docker MCP'"
   Expected: Returns search results
```

### If tests pass: **🎉 SUCCESS!**

## 🔧 Troubleshooting (If Needed)

### Issue: Can't access domain

```bash
# Check DNS
nslookup your-domain.com

# If DNS not ready, use IP directly:
http://YOUR-VPS-IP:5678  # n8n
http://YOUR-VPS-IP:3000  # n8n-MCP
http://YOUR-VPS-IP:8811  # MCP Gateway
```

### Issue: Services won't start

```bash
# Check logs
docker compose logs

# Common fixes:
# 1. Memory issue
free -h
# Solution: Reduce container limits in docker-compose.yml

# 2. Port conflict
sudo netstat -tlnp | grep :80
# Solution: Stop conflicting service

# 3. Docker not running
sudo systemctl status docker
sudo systemctl start docker
```

### Issue: Authentication failed

```bash
# Check token length (should be 64)
cat .env | grep N8N_MCP_AUTH_TOKEN
echo $TOKEN | wc -c

# Regenerate if needed
openssl rand -hex 32
# Update .env and restart:
docker compose up -d
```

## 📋 Post-Deployment Checklist

- [ ] n8n accessible at https://your-domain.com
- [ ] n8n API key generated and added to .env
- [ ] Claude Desktop shows MCP tools
- [ ] Can query tools from Claude
- [ ] Supabase credentials added (if using)
- [ ] Google Sheets credentials added (if using)
- [ ] Saved auth token securely
- [ ] Configured firewall (ufw)
- [ ] Tested from multiple machines

## 🎯 Next Steps

1. **Configure Supabase MCP** (if using)
   ```bash
   # In .env, add:
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=your-key

   # Restart
   docker compose up -d
   ```

2. **Set up Gemini CLI** (for automation)
   - See: GEMINI_CLI_SETUP.md

3. **Create first monitoring workflow**
   - Open n8n UI
   - Use MCP Client Tool node
   - Connect to: http://n8n-mcp:3000/mcp

4. **Build AI agent**
   - Add AI Agent node
   - Connect MCP tools
   - Test with simple task

## 📚 Full Documentation

- **README.md** - Complete guide with architecture
- **DEPLOYMENT_SUMMARY.md** - Overview and decisions
- **GEMINI_CLI_SETUP.md** - AI CLI integration
- **LOCAL_CLIENT_SETUP.md** - Multi-machine setup

## 🆘 Need Help?

```bash
# View service logs
docker compose logs -f SERVICE_NAME

# Check container status
docker compose ps

# Restart specific service
docker compose restart SERVICE_NAME

# View resource usage
docker stats

# Access container shell
docker exec -it CONTAINER_NAME sh
```

## 💡 Pro Tips

1. **Bookmark Portainer**: https://portainer.your-domain.com
   - Easy container management
   - Visual logs
   - Resource monitoring

2. **Set up monitoring**
   ```bash
   # Watch resource usage
   watch docker stats

   # Set up alerts (cron job)
   # Add to crontab: */5 * * * * /path/to/health-check.sh
   ```

3. **Regular backups**
   ```bash
   # Backup n8n data (weekly)
   docker run --rm \
     -v docker-mcp_n8n-data:/source:ro \
     -v $(pwd):/backup \
     alpine tar czf /backup/n8n-backup-$(date +%Y%m%d).tar.gz -C /source .
   ```

4. **Update regularly**
   ```bash
   # Monthly updates
   cd ~/docker-mcp
   docker compose pull
   docker compose up -d
   ```

---

## ⏱️ Time Breakdown

| Phase | Time | Description |
|-------|------|-------------|
| Upload | 2 min | SCP files to server |
| Configure | 5 min | Edit .env file |
| Deploy | 3 min | Docker compose up |
| Wait | 5 min | Services start + SSL |
| n8n Setup | 5 min | First login, API key |
| Client Config | 5 min | Claude Desktop |
| Testing | 5 min | Verify everything works |
| **Total** | **30 min** | From zero to working |

## 🎉 Deployment Complete!

You now have:
- ✅ 12 MCP servers accessible remotely
- ✅ n8n-MCP with 39 tools
- ✅ n8n workflow automation
- ✅ Automatic HTTPS
- ✅ Remote access from all machines
- ✅ Ready for AI agent integration

**Welcome to the future of automation!** 🚀
