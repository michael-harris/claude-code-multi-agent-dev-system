# MCP Server Configurations

Model Context Protocol (MCP) servers extend Claude Code with additional capabilities.

## Configuration Files

| File | Purpose |
|------|---------|
| `required.json` | Core MCPs for DevTeam (GitHub, Memory) |
| `recommended.json` | Enhanced functionality (Sequential Thinking) |
| `lsp-servers.json` | Language Server Protocol integration |
| `optional.json` | Deployment platforms (Vercel, Railway, etc.) |

## Quick Start

### 1. Required MCPs (Minimum Setup)

Add to your `~/.claude.json` or project `.claude/settings.json`:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token-here"
      }
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

### 2. Set Environment Variables

```bash
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
```

### 3. Restart Claude Code

MCPs are loaded at startup.

## LSP Servers (Semantic Code Intelligence)

LSP integration provides:
- Go to definition
- Find references
- Real-time diagnostics
- Hover information
- Rename refactoring

### Prerequisites

1. Install the MCP-LSP bridge:
```bash
go install github.com/isaacphi/mcp-language-server@latest
```

2. Install language servers for your project:

| Language | Install Command |
|----------|-----------------|
| TypeScript | `npm i -g typescript-language-server typescript` |
| Python | `npm i -g pyright` |
| Go | `go install golang.org/x/tools/gopls@latest` |
| Rust | `rustup component add rust-analyzer` |
| Ruby | `gem install ruby-lsp` |
| PHP | `composer global require phpactor/phpactor` |

### Auto-Detection

DevTeam automatically detects project languages and suggests appropriate LSP servers.

## Context Window Management

> ⚠️ **Warning**: Each MCP consumes context window tokens.

| MCP Type | Approximate Cost |
|----------|------------------|
| GitHub | ~8k tokens |
| Memory | ~5k tokens |
| LSP (per language) | ~5-10k tokens |
| Sequential Thinking | ~5k tokens |

**Recommendations:**
- Maximum 10 MCPs active per project
- Only enable LSPs for languages you're using
- Disable unused MCPs via `disabledMcpServers` in settings

## Troubleshooting

### MCP not loading
1. Check if command exists: `npx -y @modelcontextprotocol/server-github --help`
2. Verify environment variables are set
3. Restart Claude Code

### LSP not working
1. Verify language server is installed: `which typescript-language-server`
2. Check mcp-language-server is installed: `which mcp-language-server`
3. Ensure workspace path is correct

### Context window issues
1. Check which MCPs are enabled
2. Disable unused MCPs
3. Consider using fewer LSP servers
