# Local Client Setup - Connect to Remote MCP Gateway

Configure your laptop/desktop to use the remote Docker MCP Gateway deployed on your Hostinger VPS.

## Claude Desktop Configuration

### Step 1: Locate Configuration File

**macOS:**
```bash
# Claude Desktop config location
~/.claude/config.json

# Or use full path
/Users/YOUR_USERNAME/.claude/config.json
```

**Windows:**
```powershell
# Claude Desktop config location
%APPDATA%\Claude\config.json

# Or use full path
C:\Users\YOUR_USERNAME\AppData\Roaming\Claude\config.json
```

**Linux:**
```bash
# Claude Desktop config location
~/.config/Claude/config.json
```

### Step 2: Configure MCP Connection

Edit the config.json file:

```json
{
  "mcpServers": {
    "remote-docker-mcp": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/mcp-remote@latest",
        "connect",
        "https://mcp.your-domain.com"
      ]
    },
    "n8n-mcp-remote": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/mcp-remote@latest",
        "connect",
        "https://n8n-mcp.your-domain.com/mcp"
      ],
      "env": {
        "MCP_AUTH_TOKEN": "your-n8n-mcp-auth-token-here"
      }
    }
  }
}
```

**Important**: Replace:
- `your-domain.com` with your actual domain
- `your-n8n-mcp-auth-token-here` with the token from your `.env` file

### Step 3: Restart Claude Desktop

Close and reopen Claude Desktop. You should now see MCP tools available.

### Step 4: Test Connection

In Claude Desktop, try:
```
Can you list the available MCP tools?
```

You should see all 12 MCP servers from your Docker MCP Gateway plus the 39 n8n-MCP tools.

## Cursor IDE Configuration

### Step 1: Open Cursor Settings

1. Open Cursor IDE
2. Go to Settings (Cmd/Ctrl + ,)
3. Search for "MCP"
4. Click "Edit in settings.json"

### Step 2: Add MCP Configuration

Add to your `settings.json`:

```json
{
  "mcp.servers": {
    "remote-mcp-gateway": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/mcp-remote@latest",
        "connect",
        "https://mcp.your-domain.com"
      ]
    }
  }
}
```

### Step 3: Restart Cursor

Reload window or restart Cursor IDE.

## VSCode (with GitHub Copilot)

### Step 1: Install MCP Extension

```bash
# Search for "MCP" in VSCode extensions
# Install: "Model Context Protocol Client"
```

### Step 2: Configure

Create `.vscode/mcp.json` in your project:

```json
{
  "mcpServers": {
    "remote-tools": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/mcp-remote@latest",
        "connect",
        "https://mcp.your-domain.com"
      ]
    }
  }
}
```

## Zed Editor

### Step 1: Open Zed Settings

1. Open Zed
2. Cmd/Ctrl + , for settings
3. Go to "MCP" section

### Step 2: Add Server

```json
{
  "context_servers": {
    "docker-mcp-remote": {
      "settings": {
        "command": "npx",
        "args": [
          "-y",
          "@modelcontextprotocol/mcp-remote",
          "https://mcp.your-domain.com"
        ]
      }
    }
  }
}
```

## Testing Your Connection

### Test MCP Gateway

```bash
# From your laptop terminal
curl https://mcp.your-domain.com/health

# Expected output:
# {"status":"healthy","uptime":123.45,...}
```

### Test n8n-MCP

```bash
# Test health (no auth required)
curl https://n8n-mcp.your-domain.com/health

# Test with authentication
curl -X POST https://n8n-mcp.your-domain.com/mcp \
  -H "Authorization: Bearer your-auth-token" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'

# Should return list of 39 tools
```

### Test in Claude Desktop

Try these prompts:

```
1. "Use the Supabase MCP tool to list all tables in my database"

2. "Use Playwright to take a screenshot of google.com"

3. "Use the n8n-MCP tool to list all my workflows"

4. "Use the GitHub MCP to show me my recent repositories"

5. "Search DuckDuckGo for Docker MCP tutorials"
```

## Troubleshooting

### Issue: "Command not found: npx"

**Solution**: Install Node.js 18+

```bash
# macOS (using Homebrew)
brew install node

# Windows (using Chocolatey)
choco install nodejs

# Linux (Ubuntu/Debian)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
node --version  # Should be v18+
npx --version
```

### Issue: "Cannot connect to server"

**Causes & Solutions:**

1. **DNS not resolving**
   ```bash
   # Test DNS
   nslookup mcp.your-domain.com

   # If fails, check domain DNS settings
   ```

2. **Firewall blocking**
   ```bash
   # Test from different network
   # Or check your local firewall/VPN
   ```

3. **Server not running**
   ```bash
   # SSH to server and check
   ssh user@your-vps
   docker compose ps
   docker compose logs mcp-gateway
   ```

### Issue: "Authentication failed" (n8n-MCP)

**Solution**: Check auth token

```bash
# On server
cat .env | grep N8N_MCP_AUTH_TOKEN

# Copy the exact token (should be 64 characters)
# Update your local config with this exact value
```

### Issue: "TransformStream is not defined"

**Solution**: Update Node.js to 18+

```bash
# Check current version
node --version

# If < 18, update:
# macOS
brew upgrade node

# Windows
# Download latest from nodejs.org

# Linux
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Issue: Tools not showing up

**Solution**: Clear Claude cache and restart

```bash
# macOS
rm -rf ~/Library/Caches/Claude/*

# Windows
# Delete: C:\Users\YOUR_USERNAME\AppData\Local\Claude\Cache

# Then restart Claude Desktop
```

## Advanced: Multiple Machines

You can use the same configuration on multiple machines!

### Setup on Laptop

```json
// ~/.claude/config.json on laptop
{
  "mcpServers": {
    "shared-mcp": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/mcp-remote@latest", "connect", "https://mcp.your-domain.com"]
    }
  }
}
```

### Setup on Desktop

```json
// ~/.claude/config.json on desktop
{
  "mcpServers": {
    "shared-mcp": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/mcp-remote@latest", "connect", "https://mcp.your-domain.com"]
    }
  }
}
```

### Setup on Work Machine

Same config! All machines share the same MCP Gateway.

## Security Notes

1. **HTTPS Only**: Never use HTTP for remote MCP connections
2. **Token Security**: Don't commit auth tokens to git
3. **Network Security**: Consider VPN for extra security
4. **Token Rotation**: Rotate your N8N_MCP_AUTH_TOKEN monthly

## Performance Tips

1. **Use CDN**: If multiple locations, consider Cloudflare in front
2. **Keep-Alive**: mcp-remote maintains persistent connections
3. **Caching**: MCP Gateway caches tool definitions
4. **Monitoring**: Watch latency in Claude Desktop

## Next Steps

1. ✅ Configure Claude Desktop
2. 📝 Test all MCP tools
3. 🤖 Set up Gemini CLI (see GEMINI_CLI_SETUP.md)
4. 🔄 Create automation workflows (see AUTOMATION_WORKFLOWS.md)
5. 📊 Build monitoring agent

## Summary

You've connected your local AI tools to your remote MCP Gateway! Now all 12 MCP servers + n8n-MCP (39 tools) are available from any machine, anywhere.

**Benefits:**
- ✅ Central tool management
- ✅ Access from all your machines
- ✅ Team collaboration ready
- ✅ No local setup per machine
- ✅ Easy to add new tools (just update server)
