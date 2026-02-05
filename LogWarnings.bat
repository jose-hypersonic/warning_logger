@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SLACK_WEBHOOK_URL="

if "%~1"=="" (
  echo Usage: extract_warnings_to_slack.bat ^<path_to_log^>
  exit /b 1
)

set "LOG=%~1"
if not exist "%LOG%" (
  echo Log not found: %LOG%
  exit /b 1
)

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "DATE=%%i"

set "NAME=%~n1"
set "DIR=%~dp1"
set "OUT=%DIR%%NAME%_warnings_%DATE%.log"

findstr /R /I /C:"Log.*: Warning" /C:"warning:" "%LOG%" > "%OUT%"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$webhook='%SLACK_WEBHOOK_URL%';" ^
  "$path='%OUT%';" ^
  "$log='%LOG%';" ^
  "$name=[IO.Path]::GetFileName($log);" ^
  "$lines=Get-Content -LiteralPath $path -ErrorAction SilentlyContinue;" ^
  "if(-not $lines){ $count=0 } else { $count=$lines.Count }" ^
  "$header=@{text=('*UE5 Warnings Report*  |  Log: `{0}`  |  Warnings: *{1}*' -f $name,$count)} | ConvertTo-Json -Compress;" ^
  "Invoke-RestMethod -Method Post -Uri $webhook -ContentType 'application/json' -Body $header | Out-Null;" ^
  "if($count -gt 0){" ^
    "$chunkLimit=2900;" ^
    "$buf='';" ^
    "foreach($l in $lines){" ^
      "$add=$l + \"`n\";" ^
      "if(($buf.Length + $add.Length) -gt $chunkLimit){" ^
        "$payload=@{text=('```' + \"`n\" + $buf.TrimEnd() + \"`n\" + '```')} | ConvertTo-Json -Compress;" ^
        "Invoke-RestMethod -Method Post -Uri $webhook -ContentType 'application/json' -Body $payload | Out-Null;" ^
        "$buf='';" ^
      "}" ^
      "$buf += $add;" ^
    "}" ^
    "if($buf.Length -gt 0){" ^
      "$payload=@{text=('```' + \"`n\" + $buf.TrimEnd() + \"`n\" + '```')} | ConvertTo-Json -Compress;" ^
      "Invoke-RestMethod -Method Post -Uri $webhook -ContentType 'application/json' -Body $payload | Out-Null;" ^
    "}" ^
  "}" ^
  "Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue;"

echo Sent to Slack. Deleted: %OUT%
