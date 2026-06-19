Get-ChildItem -Path "C:\Windows\Temp\*" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

Get-ChildItem -Path "C:\shares\super_secret_files\*.tmp" -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

Write-Output "Maintenance completed at $(Get-Date)" |
    Out-File -Append -FilePath "C:\Maintenance\Logs\maintenance.log" -ErrorAction SilentlyContinue
