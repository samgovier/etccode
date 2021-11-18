# This script copies the remote EODTeam database to a local copy in Documents
Write-Host "Copying EODTeam.kdbx to local Documents"
Copy-Item -Destination "C:\Users\Govier\Documents" -Force