  $random =@()
For ($i=0; $i -le 20; $i++){
    $random = $random + [System.IO.Path]::GetRandomFileName().split(".")[0]
}

$exe = 'C:\Tools\random.exe'
$tempPath = "C:\Users\Administrator\AppData\Local\Temp\CSRTR"
$regPath = "HKLM\SOFTWARE\Classes\rtr\flag"
$regValue = "CSRTR{aXQncyBhIGZsYWch}"

New-Item -ItemType Directory -Path $tempPath -Force
$i = 0
ForEach ($str in $random){
    $path = Join-Path $tempPath -ChildPath ($str + ".exe")
    Write-Output $path
    Copy-Item $exe -Destination $path 
    New-Service -Name ('GatSystemService'+$i) -BinaryPathName $path -startupType Automatic
    reg add $regPath /v $str /d $regValue
    $i = $i + 1
}

#create a clean up schedule so we dont kill the box with processes
# find any processes with the given name that are older than 1410 minutes (23.5 hours)
$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-Command "Get-Process 2981732f7ee9fccd13797b2a8f91aa21ff08ff7d3982390882910d9a4992d4a | Where { $_.StartTime -lt (Get-Date).AddMinutes(-1410) } | stop-process"'
$Trigger= New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(10) -RepetitionInterval (New-TimeSpan -Minutes 30)
$Settings= New-ScheduledTaskSettingsSet
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Task= New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $principal
Register-ScheduledTask -TaskName 'Clean up - Ethan says plz dont kill me!' -InputObject $Task

#create scheduled task
New-Item -ItemType Directory -Path C:\Users\Administrator\AppData\Roaming\extvisual\ -Force
Copy-Item $exe -Destination 'C:\Users\Administrator\AppData\Roaming\extvisual\2981732f7ee9fccd13797b2a8f91aa21ff08ff7d3982390882910d9a4992d4a.exe' -Force
for ($i=0; $i -le 20; $i++){
    $Action= New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-Command "Start-Process -FilePath C:\Users\Administrator\AppData\Roaming\extvisual\2981732f7ee9fccd13797b2a8f91aa21ff08ff7d3982390882910d9a4992d4a.exe -WindowStyle Hidden"'
    $Trigger= New-ScheduledTaskTrigger -Daily -At (Get-Date).AddMinutes(3)
    $Settings= New-ScheduledTaskSettingsSet
    $principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $Task= New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $principal
    Register-ScheduledTask -TaskName ('System Network Extensions'+$i) -InputObject $Task
}


  
$Action= New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-Command "Get-ChildItem C:\Users\Administrator\AppData\Local\Temp\CSRTR\ -Filter *.exe | Foreach-Object { if((get-process $_.BaseName -ErrorAction SilentlyContinue) -eq $Null) { Start-Process -FilePath $_.FullName -WindowStyle Hidden}}"'
$Trigger= New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(10) -RepetitionInterval (New-TimeSpan -Minutes 30)
$Settings= New-ScheduledTaskSettingsSet
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Task= New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $principal
Register-ScheduledTask -TaskName ('CSRTR Management Service (dont kill - not part of CTF)') -InputObject $Task

#create service
# for ($i=0; $i -le 20; $i++){
# New-Service -Name ('GatSystemService'+$i) -BinaryPathName "C:\Users\Administrator\AppData\Roaming\extvisual\2981732f7ee9fccd13797b2a8f91aa21ff08ff7d3982390882910d9a4992d4a.exe" -startupType Automatic
# }

#powershell.exe -NOP -EP bypass -Command 'Get-ChildItem C:\Users\Administrator\AppData\Local\Temp\CSRTR\ -Filter *.exe | Foreach-Object {Start-Process -FilePath $_.FullName -WindowStyle Hidden}'

# $EventFilterName = "These aren't the droids you're looking for..."
# $StagerPayload = 'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -NOP -EP bypass -Command "Get-ChildItem C:\\Users\\Administrator\\AppData\\Local\\Temp\\CSRTR\\ -Filter *.exe | Foreach-Object {Start-Process -FilePath $_.FullName -WindowStyle Hidden}"'
# # Create event filter
# $EventFilterArgs = @{
#     EventNamespace = 'root/cimv2'
#     Name = $EventFilterName
#     Query = @" 
#         Select * from __InstanceCreationEvent within 10
#         where targetInstance isa 'Cim_DirectoryContainsFile'
#         and targetInstance.GroupComponent = 'Win32_Directory.Name="C:\\\\Data"'
# "@
#     QueryLanguage = 'WQL'
# }

# $Filter = Set-WmiInstance -Namespace root/subscription -Class __EventFilter -Arguments $EventFilterArgs
# # Create CommandLineEventConsumer
# $CommandLineConsumerArgs = @{
#     Name = $EventConsumerName
#     CommandLineTemplate = $StagerPayload
# }
# $Consumer = Set-WmiInstance -Namespace root/subscription -Class CommandLineEventConsumer -Arguments $CommandLineConsumerArgs
# # Create FilterToConsumerBinding
# $FilterToConsumerArgs = @{
#     Filter = $Filter
#     Consumer = $Consumer
# }
# $FilterToConsumerBinding = Set-WmiInstance -Namespace root/subscription -Class __FilterToConsumerBinding -Arguments $FilterToConsumerArgs 

 
