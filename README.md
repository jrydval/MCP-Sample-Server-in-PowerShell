# Proof of Concept MCP Server in PowerShell

A Model Context Protocol (MCP) server implementation in PowerShell that provides random number generation and inspirational quotes for Claude Desktop.

## Features

- 🎲 **Random Number Generator** - Generate random numbers between specified ranges
- 💭 **Random Quote Generator** - Get inspirational quotes from famous personalities
- 🔌 **STDIO Implementation** - Local MCP server for Claude Desktop
- 🛠️ **Easy Setup** - Simple configuration for Claude Desktop
- 📋 **Detailed Logging** - Debug logs for troubleshooting

## Available Tools

### `random_number`
Generates a random number between specified minimum and maximum values.

**Parameters:**
- `min` (integer, required) - Minimum value (inclusive)
- `max` (integer, required) - Maximum value (inclusive)

**Example:**
```json
{
  "name": "random_number",
  "arguments": {
    "min": 1,
    "max": 100
  }
}
```

### `random_quote`
Returns a random inspirational quote from a curated collection.

**Parameters:** None

**Example:**
```json
{
  "name": "random_quote",
  "arguments": {}
}
```

## Quick Start

1. **Download the server:**
   ```bash
   curl -O https://raw.githubusercontent.com/jrydval/MCP-Sample-Server-in-PowerShell/refs/heads/main/mcp_test_client.ps1
   ```

2. **Configure Claude Desktop:**
   Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:
   ```json
   {
     "mcpServers": {
       "powershell-mcp": {
         "command": "pwsh",
         "args": ["-File", "/path/to/mcp_server_stdio.ps1"],
         "env": {}
       }
     }
   }
   ```

3. **Restart Claude Desktop** and enable the tools!

## Files

- `mcp_server_stdio.ps1` - Main MCP server implementation
- `claude_desktop_config.json.sample` - Example Claude Desktop configuration

## Requirements

- **PowerShell** 7.0+ (`pwsh`)
- **Claude Desktop** with MCP support

## Testing

### Test the Server
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{}}}' | pwsh -File mcp_server_stdio.ps1
```

### Test Tools List
```bash
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' | pwsh -File mcp_server_stdio.ps1
```

### Test Random Number Tool
```bash
echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"random_number","arguments":{"min":1,"max":100}}}' | pwsh -File mcp_server_stdio.ps1
```

### Test Random Quote Tool
```bash
echo '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"random_quote","arguments":{}}}' | pwsh -File mcp_server_stdio.ps1
```

## Debugging

### Claude Desktop Logs
```bash
# On macOS
tail -f ~/Library/Logs/Claude/mcp-server-powershell-mcp.log
```

### Troubleshooting

1. **Server not connecting:**
   - Verify PowerShell path: `which pwsh`
   - Check file permissions: `chmod +x mcp_server_stdio.ps1`
   - Test server manually using commands above

2. **Tools not appearing:**
   - Restart Claude Desktop completely (Quit + restart)
   - Check Claude Desktop logs for errors
   - Verify JSON syntax in config file

3. **Permission errors:**
   - Ensure PowerShell execution policy allows scripts
   - Check file paths in configuration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built for [Claude Desktop](https://claude.ai/desktop) by Anthropic
- Uses the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)
- Inspired by the MCP community examples

## Support

If you encounter issues:

1. Check Claude Desktop logs: `~/Library/Logs/Claude/mcp-server-powershell-mcp.log` and `~/Library/Logs/Claude/main.log`
2. Verify PowerShell version: `pwsh --version`
3. Test the server manually using the testing commands above
4. Open an issue in this repository
