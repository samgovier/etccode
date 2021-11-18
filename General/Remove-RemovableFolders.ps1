$users = @(
)

Add-Type -AssemblyName Microsoft.VisualBasic

Get-ChildItem "C:\Users" -Directory | ForEach-Object -Process {
    try {
        if ($users -contains $PSItem.Name) {
            Remove-Item $PSItem.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    catch {}

    if ($users -contains $PSItem.Name) {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($PSItem.FullName,'OnlyErrorDialogs','SendToRecycleBin')
    }
}