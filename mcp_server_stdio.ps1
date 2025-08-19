# MCP Server using PowerShell - STDIO Version for Claude Desktop
# This version communicates via stdin/stdout using JSON-RPC protocol
# Save as: mcp_server_stdio.ps1

# Array of inspirational quotes
$quotes = @(
    "The only way to do great work is to love what you do. - Steve Jobs",
    "Innovation distinguishes between a leader and a follower. - Steve Jobs", 
    "Life is what happens to you while you're busy making other plans. - John Lennon",
    "The future belongs to those who believe in the beauty of their dreams. - Eleanor Roosevelt",
    "It is during our darkest moments that we must focus to see the light. - Aristotle"
)

# Logging function for debugging (writes to stderr so it doesn't interfere with JSON-RPC)
function Write-MCPLog {
    param([string]$Message)
    [Console]::Error.WriteLine("$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [MCP] $Message")
}

# Function to send JSON-RPC response
function Send-JSONResponse {
    param([object]$Response)
    
    $jsonResponse = $Response | ConvertTo-Json -Depth 10 -Compress
    Write-MCPLog "Sending response: $jsonResponse"
    [Console]::WriteLine($jsonResponse)
    [Console]::Out.Flush()
}

# Function to handle random number generation
function Invoke-RandomNumber {
    param([object]$Arguments, [string]$RequestId)
    
    try {
        # Validate required parameters
        if (-not $Arguments.min -or -not $Arguments.max) {
            Send-JSONResponse @{
                jsonrpc = "2.0"
                id = $RequestId
                error = @{
                    code = -32602
                    message = "Both 'min' and 'max' parameters are required"
                }
            }
            return
        }
        
        $min = [int]$Arguments.min
        $max = [int]$Arguments.max
        
        # Validate min <= max
        if ($min -gt $max) {
            Send-JSONResponse @{
                jsonrpc = "2.0"
                id = $RequestId
                error = @{
                    code = -32602
                    message = "Minimum value cannot be greater than maximum value"
                }
            }
            return
        }
        
        # Generate random number
        $randomNumber = Get-Random -Minimum $min -Maximum ($max + 1)
        
        Send-JSONResponse @{
            jsonrpc = "2.0"
            id = $RequestId
            result = @{
                content = @(
                    @{
                        type = "text"
                        text = "Generated random number: $randomNumber (between $min and $max)"
                    }
                )
            }
        }
    }
    catch {
        Write-MCPLog "Error in random number generation: $_"
        Send-JSONResponse @{
            jsonrpc = "2.0"
            id = $RequestId
            error = @{
                code = -32603
                message = "Internal error: $($_.Exception.Message)"
            }
        }
    }
}

# Function to handle random quote generation
function Invoke-RandomQuote {
    param([string]$RequestId)
    
    try {
        # Get random quote from the array
        $randomQuote = $quotes | Get-Random
        
        Send-JSONResponse @{
            jsonrpc = "2.0"
            id = $RequestId
            result = @{
                content = @(
                    @{
                        type = "text"
                        text = $randomQuote
                    }
                )
            }
        }
    }
    catch {
        Write-MCPLog "Error in random quote generation: $_"
        Send-JSONResponse @{
            jsonrpc = "2.0"
            id = $RequestId
            error = @{
                code = -32603
                message = "Internal error: $($_.Exception.Message)"
            }
        }
    }
}

# Function to handle initialize request
function Handle-Initialize {
    param([object]$Params, [string]$RequestId)
    
    # Use the protocol version requested by client, or fall back to default
    $protocolVersion = if ($Params.protocolVersion) { $Params.protocolVersion } else { "2024-11-05" }
    
    Send-JSONResponse @{
        jsonrpc = "2.0"
        id = $RequestId
        result = @{
            protocolVersion = $protocolVersion
            capabilities = @{
                tools = @{
                    listChanged = $true
                }
                logging = @{}
                prompts = @{}
                resources = @{}
            }
            serverInfo = @{
                name = "PowerShell MCP Server"
                version = "1.0.0"
            }
        }
    }
}

# Function to handle tools/list request
function Handle-ToolsList {
    param([string]$RequestId)
    
    Send-JSONResponse @{
        jsonrpc = "2.0"
        id = $RequestId
        result = @{
            tools = @(
                @{
                    name = "random_number"
                    description = "Generate a random number between two values"
                    inputSchema = @{
                        type = "object"
                        properties = @{
                            min = @{
                                type = "integer"
                                description = "Minimum value (inclusive)"
                            }
                            max = @{
                                type = "integer"
                                description = "Maximum value (inclusive)"
                            }
                        }
                        required = @("min", "max")
                    }
                }
                @{
                    name = "random_quote"
                    description = "Get a random inspirational quote"
                    inputSchema = @{
                        type = "object"
                        properties = @{}
                    }
                }
            )
        }
    }
}

# Function to handle tools/call request
function Handle-ToolsCall {
    param([object]$Params, [string]$RequestId)
    
    $toolName = $Params.name
    $arguments = $Params.arguments
    
    switch ($toolName) {
        "random_number" {
            Invoke-RandomNumber -Arguments $arguments -RequestId $RequestId
        }
        "random_quote" {
            Invoke-RandomQuote -RequestId $RequestId
        }
        default {
            Send-JSONResponse @{
                jsonrpc = "2.0"
                id = $RequestId
                error = @{
                    code = -32601
                    message = "Tool '$toolName' not found"
                }
            }
        }
    }
}

# Main message processing loop
Write-MCPLog "PowerShell MCP Server starting..."
Write-MCPLog "Available tools: random_number, random_quote"
Write-MCPLog "Waiting for JSON-RPC messages on stdin..."

try {
    while ($true) {
        # Read line from stdin
        $line = [Console]::ReadLine()
        
        if ($null -eq $line) {
            Write-MCPLog "EOF received, shutting down"
            break
        }
        
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        
        Write-MCPLog "Received: $line"
        
        try {
            # Parse JSON-RPC request
            $request = $line | ConvertFrom-Json
            $method = $request.method
            $params = $request.params
            $id = $request.id
            
            Write-MCPLog "Processing method: $method (id: $id)"
            
            # Handle different RPC methods
            switch ($method) {
                "initialize" {
                    Write-MCPLog "Handling initialize request"
                    Handle-Initialize -Params $params -RequestId $id
                }
                "initialized" {
                    Write-MCPLog "Received initialized notification"
                    # Notification - no response needed
                }
                "notifications/initialized" {
                    Write-MCPLog "Received initialized notification (full path)"
                    # Notification - no response needed
                }
                "tools/list" {
                    Write-MCPLog "Handling tools/list request"
                    Handle-ToolsList -RequestId $id
                }
                "tools/call" {
                    Write-MCPLog "Handling tools/call request for tool: $($params.name)"
                    Handle-ToolsCall -Params $params -RequestId $id
                }
                default {
                    Write-MCPLog "Unknown method: $method"
                    if ($id) {
                        Send-JSONResponse @{
                            jsonrpc = "2.0"
                            id = $id
                            error = @{
                                code = -32601
                                message = "Method not found: $method"
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-MCPLog "Error parsing request: $_"
            Send-JSONResponse @{
                jsonrpc = "2.0"
                id = $null
                error = @{
                    code = -32700
                    message = "Parse error: $($_.Exception.Message)"
                }
            }
        }
    }
}
catch {
    Write-MCPLog "Fatal error: $_"
}
finally {
    Write-MCPLog "MCP Server shutting down"
}