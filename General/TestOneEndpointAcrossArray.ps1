$computers = @(
)

Invoke-Command -ComputerName $computers -ScriptBlock {
    test-netconnection example.com -port 443 -InformationLevel Quiet
    Write-Host "~ $env:computername"
}

# OR

Invoke-Command -ComputerName $computers -ScriptBlock {
    try {
        Invoke-WebRequest -Uri "https://example.com"
    }
    catch {
        if ($PSItem.Exception.ToString().Contains("SSL/TLS secure channel")) {
            Write-Host $true
        }
        else {
            Write-Host $false
        }
    }

    Write-Host "~ $env:computername"
}