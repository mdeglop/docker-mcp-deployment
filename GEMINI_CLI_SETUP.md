# Gemini CLI + MCP Integration Guide

## Overview

This guide shows you how to use Gemini CLI (or any CLI-based AI) to interact with your remote Docker MCP Gateway for monitoring, automation, and troubleshooting.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Your Laptop/Local Machine                                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Gemini CLI / aider / claude-code                      │ │
│  │  + MCP Client (mcp-remote)                             │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTPS
┌──────────────────────────┴──────────────────────────────────┐
│  Hostinger VPS                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Docker MCP Gateway (SSE)                              │ │
│  │  ├─ Supabase MCP                                       │ │
│  │  ├─ GitHub MCP                                         │ │
│  │  ├─ Playwright (browser automation)                    │ │
│  │  ├─ n8n-MCP (workflow management)                      │ │
│  │  └─ +9 other tools                                     │ │
│  └────────────────────────────────────────────────────────┘ │
│                           │                                  │
│  ┌────────────────────────┴──────────────────────────────┐  │
│  │  n8n Instance                                          │  │
│  │  - Monitoring workflows                                │  │
│  │  - Automation workflows                                │  │
│  └────────────────────────────────────────────────────────┘  │
│                           │                                  │
│  ┌────────────────────────┴──────────────────────────────┐  │
│  │  Your Application Stack                                │  │
│  │  - Supabase database                                   │  │
│  │  - Google Sheets                                       │  │
│  │  - Website                                             │  │
│  └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Option 1: Gemini CLI (Official Google)

### Installation

```bash
# Install Gemini CLI
npm install -g @google/generative-ai

# Or use npx (no installation)
npx @google/generative-ai
```

### Configuration for MCP

Create a configuration file for Gemini to use MCP tools:

```bash
# ~/.config/gemini-cli/config.json
{
  "model": "gemini-2.0-flash-exp",
  "mcp": {
    "servers": {
      "remote-mcp": {
        "command": "npx",
        "args": [
          "-y",
          "@modelcontextprotocol/mcp-remote",
          "https://mcp.yourdomain.com"
        ]
      }
    }
  }
}
```

### Usage Example

```bash
# Start Gemini with MCP tools
gemini-cli --config ~/.config/gemini-cli/config.json

# Example prompts:
> Check my Supabase database for errors in the logs table

> Look at the latest Google Sheets data and compare it to Supabase

> Use Playwright to check if my website is loading correctly

> Create an n8n workflow that monitors Supabase every 5 minutes
```

## Option 2: Claude Code CLI (Recommended)

Claude Code has better MCP integration and can be installed on the server itself!

### Installation on VPS

```bash
# On your Hostinger VPS via SSH
ssh user@your-vps-ip

# Install Node.js 18+ (if not already installed)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Claude Code CLI
npm install -g @anthropic/claude-code

# Or use npx
npx @anthropic/claude-code
```

### Configuration

```bash
# Create MCP config on the VPS
mkdir -p ~/.config/claude-code
cat > ~/.config/claude-code/mcp.json << 'EOF'
{
  "mcpServers": {
    "local-gateway": {
      "command": "docker",
      "args": [
        "exec",
        "-i",
        "mcp-gateway",
        "docker",
        "mcp",
        "gateway",
        "run"
      ]
    },
    "n8n-mcp": {
      "command": "node",
      "args": ["/path/to/mcp-remote-bridge.js"],
      "env": {
        "MCP_URL": "http://localhost:3000/mcp",
        "AUTH_TOKEN": "your-n8n-mcp-auth-token"
      }
    }
  }
}
EOF
```

### Usage on Server

```bash
# SSH into server
ssh user@your-vps

# Run Claude Code
claude-code

# Or use for specific tasks
claude-code "Check Docker container status and logs"
claude-code "Analyze n8n workflow execution for errors"
claude-code "Query Supabase for recent issues"
```

## Option 3: Aider (Code-focused CLI AI)

Aider is excellent for code generation and has MCP support:

```bash
# Install aider
pip install aider-chat

# Configure MCP
cat > ~/.aider/mcp.json << 'EOF'
{
  "mcpServers": {
    "remote-tools": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/mcp-remote",
        "https://mcp.yourdomain.com"
      ]
    }
  }
}
EOF

# Use aider with MCP tools
aider --mcp

# Example prompts:
> Use Supabase MCP to check the schema
> Generate a migration for the users table
> Create n8n workflow JSON for monitoring
```

## Option 4: Custom Script (Maximum Flexibility)

Create your own CLI tool that uses MCP:

```bash
# ~/scripts/mcp-cli.js
#!/usr/bin/env node

const { spawn } = require('child_process');
const readline = require('readline');

// MCP Remote connection
const mcpRemote = spawn('npx', [
  '-y',
  '@modelcontextprotocol/mcp-remote',
  'https://mcp.yourdomain.com'
], {
  stdio: ['pipe', 'pipe', 'pipe']
});

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  prompt: 'MCP> '
});

// Send MCP request
function sendMCPRequest(method, params = {}) {
  const request = {
    jsonrpc: '2.0',
    method: method,
    params: params,
    id: Date.now()
  };

  mcpRemote.stdin.write(JSON.stringify(request) + '\n');
}

// Handle responses
mcpRemote.stdout.on('data', (data) => {
  try {
    const response = JSON.parse(data.toString());
    console.log('Response:', JSON.stringify(response, null, 2));
  } catch (e) {
    console.log('Raw:', data.toString());
  }
  rl.prompt();
});

// Interactive CLI
rl.prompt();
rl.on('line', (line) => {
  const input = line.trim();

  if (input === 'list-tools') {
    sendMCPRequest('tools/list');
  } else if (input.startsWith('call ')) {
    const toolName = input.split(' ')[1];
    sendMCPRequest('tools/call', { name: toolName, arguments: {} });
  } else if (input === 'exit') {
    mcpRemote.kill();
    process.exit(0);
  } else {
    console.log('Commands: list-tools, call <tool-name>, exit');
    rl.prompt();
  }
});

console.log('MCP CLI Ready. Type "list-tools" to see available tools.');
```

```bash
# Make executable
chmod +x ~/scripts/mcp-cli.js

# Run
~/scripts/mcp-cli.js
```

## Monitoring Agent Architecture

### n8n Workflow: Website Monitor with AI Decision Making

```javascript
// n8n Workflow JSON (import this into n8n)
{
  "name": "AI-Powered Website Monitor",
  "nodes": [
    {
      "name": "Schedule Trigger",
      "type": "n8n-nodes-base.scheduleTrigger",
      "parameters": {
        "rule": {
          "interval": [{"field": "minutes", "minutesInterval": 5}]
        }
      }
    },
    {
      "name": "Check Website",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "https://your-website.com",
        "responseFormat": "json",
        "options": {
          "timeout": 10000
        }
      }
    },
    {
      "name": "Check Supabase",
      "type": "@n8n/n8n-nodes-langchain.mcpClientTool",
      "parameters": {
        "serverUrl": "http://n8n-mcp:3000/mcp",
        "authToken": "={{$env.N8N_MCP_AUTH_TOKEN}}",
        "toolName": "execute_sql",
        "arguments": {
          "query": "SELECT * FROM errors WHERE created_at > NOW() - INTERVAL '5 minutes'"
        }
      }
    },
    {
      "name": "Analyze with AI",
      "type": "@n8n/n8n-nodes-langchain.agent",
      "parameters": {
        "model": "gemini-2.0-flash",
        "prompt": `Analyze the website status and database errors.

Website Response: {{$json.response}}
Database Errors: {{$node["Check Supabase"].json}}

Determine if there's a problem that needs fixing.
If there is:
1. Describe the issue
2. Propose a solution
3. Generate the fix (SQL migration, workflow adjustment, etc.)
4. Ask for confirmation before executing
        `
      }
    },
    {
      "name": "Send Notification",
      "type": "n8n-nodes-base.sms",
      "parameters": {
        "message": "Issue detected: {{$node["Analyze with AI"].json.issue}}\n\nProposed fix: {{$node["Analyze with AI"].json.solution}}\n\nReply 'yes' to execute.",
        "to": "+1234567890"
      }
    },
    {
      "name": "Wait for Confirmation",
      "type": "n8n-nodes-base.wait",
      "parameters": {
        "resume": "webhook",
        "webhookPath": "confirm-fix"
      }
    },
    {
      "name": "Execute Fix",
      "type": "@n8n/n8n-nodes-langchain.mcpClientTool",
      "parameters": {
        "serverUrl": "http://n8n-mcp:3000/mcp",
        "toolName": "{{$node["Analyze with AI"].json.toolName}}",
        "arguments": "={{$node["Analyze with AI"].json.toolArgs}}"
      }
    }
  ],
  "connections": {
    "Schedule Trigger": {"main": [[{"node": "Check Website"}]]},
    "Check Website": {"main": [[{"node": "Check Supabase"}]]},
    "Check Supabase": {"main": [[{"node": "Analyze with AI"}]]},
    "Analyze with AI": {"main": [[{"node": "Send Notification"}]]},
    "Send Notification": {"main": [[{"node": "Wait for Confirmation"}]]},
    "Wait for Confirmation": {"main": [[{"node": "Execute Fix"}]]}
  }
}
```

### CLI Agent Script

```bash
#!/bin/bash
# ~/scripts/monitor-agent.sh

# Load environment
source ~/.bashrc

# Connect to MCP Gateway
export MCP_URL="https://mcp.yourdomain.com"

# Main monitoring loop
while true; do
    echo "=== Monitoring Check $(date) ==="

    # Use Claude Code to analyze
    response=$(claude-code << 'EOF'
You are a monitoring agent. Check:
1. Supabase database health (use supabase MCP tools)
2. Recent errors in logs table
3. Website response time (use playwright to load page)
4. n8n workflow execution status

Summarize findings and recommend actions.
EOF
    )

    echo "$response"

    # If issues found, alert
    if echo "$response" | grep -q "ISSUE"; then
        # Send SMS (using Twilio or similar)
        curl -X POST "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_SID/Messages.json" \
          --data-urlencode "From=$TWILIO_FROM" \
          --data-urlencode "To=$MY_PHONE" \
          --data-urlencode "Body=$response" \
          -u "$TWILIO_SID:$TWILIO_AUTH"
    fi

    # Sleep for 5 minutes
    sleep 300
done
```

## Best Practices

### 1. Authentication Management

```bash
# Store credentials securely
cat > ~/.mcp-credentials << 'EOF'
export MCP_GATEWAY_URL="https://mcp.yourdomain.com"
export N8N_MCP_URL="http://n8n-mcp:3000/mcp"
export N8N_MCP_AUTH_TOKEN="your-auth-token"
export SUPABASE_URL="your-supabase-url"
export SUPABASE_KEY="your-service-role-key"
EOF

chmod 600 ~/.mcp-credentials
source ~/.mcp-credentials
```

### 2. Error Handling

Always wrap MCP calls in try-catch or error handlers:

```javascript
try {
  const result = await mcpClient.callTool('supabase_execute_sql', {
    query: 'SELECT * FROM errors'
  });
  console.log('Success:', result);
} catch (error) {
  console.error('MCP call failed:', error);
  // Fallback or alert
}
```

### 3. Rate Limiting

Respect the MCP Gateway rate limits (configured in docker-compose):

```bash
# Check rate limit headers
curl -I https://mcp.yourdomain.com

# Headers show:
# RateLimit-Limit: 50
# RateLimit-Remaining: 48
# RateLimit-Reset: 1234567890
```

### 4. Logging

Log all MCP interactions for debugging:

```bash
# Enable logging
export MCP_DEBUG=1

# Log to file
claude-code 2>&1 | tee ~/logs/mcp-agent-$(date +%Y%m%d).log
```

## Example Use Cases

### Use Case 1: Automated Database Migration

```bash
claude-code << 'EOF'
1. Use Supabase MCP to analyze current schema
2. Generate migration for adding new 'user_preferences' column
3. Test migration on staging (use apply_migration with --dry-run)
4. If successful, ask for confirmation
5. Apply migration to production
6. Verify with get_advisors
EOF
```

### Use Case 2: Google Sheets Sync

```bash
# Coming soon - add Google Sheets MCP to catalog
claude-code << 'EOF'
1. Fetch latest data from Google Sheets (use sheets MCP)
2. Compare with Supabase data (use supabase MCP)
3. Identify discrepancies
4. Generate UPDATE queries to sync
5. Execute after confirmation
EOF
```

### Use Case 3: Workflow Health Check

```bash
claude-code << 'EOF'
1. Use n8n MCP to list all workflows
2. Check execution history for failures
3. For failed workflows:
   - Get workflow JSON
   - Analyze error logs
   - Propose fix
4. Create new workflow version with fixes
5. Test execution
EOF
```

## Troubleshooting

### Connection Issues

```bash
# Test MCP Gateway connectivity
curl -v https://mcp.yourdomain.com/health

# Test with mcp-remote directly
npx -y @modelcontextprotocol/mcp-remote test https://mcp.yourdomain.com
```

### Authentication Failures

```bash
# Verify auth token
echo $N8N_MCP_AUTH_TOKEN | wc -c  # Should be 64+ characters

# Test authentication
curl -X POST https://n8n-mcp.yourdomain.com/mcp \
  -H "Authorization: Bearer $N8N_MCP_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

### Tool Not Found

```bash
# List available tools
claude-code "List all available MCP tools and their descriptions"

# Refresh tool cache (if using custom bridge)
rm -rf ~/.cache/mcp-tools
```

## Next Steps

1. Choose your preferred CLI tool (Claude Code recommended)
2. Set up authentication
3. Test basic MCP calls
4. Create your first monitoring workflow in n8n
5. Build automation scripts
6. Set up alerting (SMS/email)

For advanced automation ideas, see AUTOMATION_WORKFLOWS.md
