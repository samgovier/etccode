$PathToCopy = @(
    "C:\Users\Govier\Source",
    "C:\Users\Govier\.ssh\config"
)

Write-Host "Backup to Documents"
foreach ($copyPath in $PathToCopy) {
    Copy-Item -Path $copyPath -Destination "C:\Users\Govier\Documents\OneDriveBackup" -Recurse -Force
}