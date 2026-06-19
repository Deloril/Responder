$MailServer = "mail.tsg-internal.lab"
$POP3Port = 110
$Username = $env:USERNAME
$EmailAddress = "$Username@tsg-internal.lab"
$CheckInterval = 60
$LogFile = "$env:TEMP\LinkClicker.log"

$Passwords = @{
    "ben" = "Kia0ra2025!"
    "kate" = "Wellington#1"
    "sam.hewitt" = "DevOps2025!"
}
$Password = $Passwords[$Username]
if (-not $Password) { exit }

function Write-Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$ts] $msg" -ErrorAction SilentlyContinue
}

function Read-Line($reader) {
    return $reader.ReadLine()
}

function Send-Command($writer, $reader, $cmd) {
    $writer.WriteLine($cmd)
    $writer.Flush()
    return Read-Line $reader
}

Write-Log "LinkClicker started for $Username"

while ($true) {
    $tcp = $null
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.ReceiveTimeout = 15000
        $tcp.SendTimeout = 15000
        $tcp.Connect($MailServer, $POP3Port)
        $stream = $tcp.GetStream()
        $stream.ReadTimeout = 15000
        $reader = New-Object System.IO.StreamReader($stream)
        $writer = New-Object System.IO.StreamWriter($stream)

        Read-Line $reader | Out-Null
        Send-Command $writer $reader "USER $EmailAddress" | Out-Null
        $authResult = Send-Command $writer $reader "PASS $Password"

        if ($authResult -like "+OK*") {
            $stat = Send-Command $writer $reader "STAT"
            $msgCount = 0
            if ($stat -match '\+OK (\d+)') { $msgCount = [int]$Matches[1] }

            Write-Log "Mailbox check: $msgCount message(s)"

            for ($i = 1; $i -le $msgCount; $i++) {
                $writer.WriteLine("RETR $i")
                $writer.Flush()
                Read-Line $reader | Out-Null

                $body = ""
                $lineCount = 0
                while ($lineCount -lt 500) {
                    $line = Read-Line $reader
                    if ($null -eq $line -or $line -eq ".") { break }
                    $body += $line + "`n"
                    $lineCount++
                }

                $urlMatches = [regex]::Matches($body, 'https?://[^\s<>"'']+')
                foreach ($m in $urlMatches) {
                    $url = $m.Value
                    $fileName = $url.Split("/")[-1]
                    if (-not $fileName -or $fileName.Length -lt 3) { $fileName = "download.exe" }
                    $outPath = Join-Path $env:TEMP $fileName

                    try {
                        Write-Log "Downloading: $url"
                        $wc = New-Object Net.WebClient
                        $wc.DownloadFile($url, $outPath)
                        Write-Log "Executing: $outPath"
                        Start-Process -FilePath $outPath -ErrorAction SilentlyContinue
                    } catch {
                        Write-Log "Download/exec failed: $_"
                    }
                }

                try { Send-Command $writer $reader "DELE $i" | Out-Null } catch {}
            }

            try { Send-Command $writer $reader "QUIT" | Out-Null } catch {}
        } else {
            Write-Log "Auth failed: $authResult"
        }
    } catch {
        Write-Log "Error: $_"
    } finally {
        if ($tcp) {
            try { $tcp.Close() } catch {}
            try { $tcp.Dispose() } catch {}
        }
    }

    Start-Sleep -Seconds $CheckInterval
}
