# MCP Server Test Client for HTTPS
# Run this script to test your HTTPS MCP server

$serverUrl = "https://localhost:8443"

Write-Host "🧪 Testing HTTPS MCP Server at $serverUrl" -ForegroundColor Cyan
Write-Host "=" * 50

# Skip SSL certificate validation for self-signed certificates
if ($PSVersionTable.PSVersion.Major -ge 6) {
    # PowerShell Core/7+
    $PSDefaultParameterValues['Invoke-RestMethod:SkipCertificateCheck'] = $true
} else {
    # Windows PowerShell 5.1
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
}

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Path,
        [object]$Body = $null
    )
    
    Write-Host "`n🔍 Testing: $Name" -ForegroundColor Yellow
    Write-Host "   $Method $Path"
    
    try {
        $uri = "$serverUrl$Path"
        
        if ($Body) {
            $jsonBody = $Body | ConvertTo-Json -Depth 10
            Write-Host "   Body: $jsonBody" -ForegroundColor Gray
            $response = Invoke-RestMethod -Uri $uri -Method $Method -Body $jsonBody -ContentType "application/json"
        } else {
            $response = Invoke-RestMethod -Uri $uri -Method $Method
        }
        
        Write-Host "   ✅ SUCCESS" -ForegroundColor Green
        Write-Host "   Response:" -ForegroundColor White
        $response | ConvertTo-Json -Depth 10 | Write-Host
        
        return $true
    }
    catch {
        Write-Host "   ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Test 1: Server Info
Test-Endpoint -Name "Server Information" -Method "GET" -Path "/"

# Test 2: Health Check
Test-Endpoint -Name "Health Check" -Method "GET" -Path "/health"

# Test 3: List Tools
Test-Endpoint -Name "List Tools" -Method "GET" -Path "/tools"

# Test 4: Random Number (valid range)
$randomNumberBody = @{
    name = "random_number"
    arguments = @{
        min = 1
        max = 100
    }
}
Test-Endpoint -Name "Random Number (1-100)" -Method "POST" -Path "/tools/call" -Body $randomNumberBody

# Test 5: Random Number (different range)
$randomNumberBody2 = @{
    name = "random_number"
    arguments = @{
        min = 50
        max = 150
    }
}
Test-Endpoint -Name "Random Number (50-150)" -Method "POST" -Path "/tools/call" -Body $randomNumberBody2

# Test 6: Random Quote
$randomQuoteBody = @{
    name = "random_quote"
    arguments = @{}
}
Test-Endpoint -Name "Random Quote" -Method "POST" -Path "/tools/call" -Body $randomQuoteBody

# Test 7: Invalid tool name
$invalidToolBody = @{
    name = "invalid_tool"
    arguments = @{}
}
Test-Endpoint -Name "Invalid Tool (should fail)" -Method "POST" -Path "/tools/call" -Body $invalidToolBody

# Test 8: Invalid parameters for random_number
$invalidParamsBody = @{
    name = "random_number"
    arguments = @{
        min = 100
        max = 50  # max < min should fail
    }
}
Test-Endpoint -Name "Invalid Range (should fail)" -Method "POST" -Path "/tools/call" -Body $invalidParamsBody

# Test 9: Missing parameters
$missingParamsBody = @{
    name = "random_number"
    arguments = @{}  # missing min and max
}
Test-Endpoint -Name "Missing Parameters (should fail)" -Method "POST" -Path "/tools/call" -Body $missingParamsBody

Write-Host "`n" + "=" * 50
Write-Host "🏁 Testing Complete!" -ForegroundColor Cyan
Write-Host "`nTo run individual tests manually:" -ForegroundColor Yellow
Write-Host "curl -k $serverUrl/health" -ForegroundColor Gray
Write-Host "curl -k -X POST $serverUrl/tools/call -H 'Content-Type: application/json' -d '{\"name\":\"random_quote\",\"arguments\":{}}'" -ForegroundColor Gray
Write-Host "`n⚠️  Note: Use -k flag with curl to ignore self-signed certificate warnings" -ForegroundColor Red