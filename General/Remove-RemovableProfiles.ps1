$users = @(
)

foreach ($user in $users) {
    $CimObjects = Get-CimInstance -Class Win32_UserProfile | Where-Object -Property LocalPath -match "Users.$user$"

    if ($CimObjects.Length -gt 1) {
        Write-Error -Message "$user : Found 2+ instances: script not specific enough. Please Modify."
    }
    elseif ($null -ne $CimObjects) {
        Remove-CimInstance $CimObjects
        Write-Host -Object "$user : Profile deleted."
    }
    else {
        Write-Warning -Message "$user : User Not Found."
    }
}