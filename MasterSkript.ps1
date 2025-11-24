# Skripte.ps1
# Holt alle .ps1 Dateien aus dem GitHub-Repo "Skripte"
# und legt sie direkt auf den Desktop – ohne zusätzlichen Ordner.

$Desktop = Join-Path $env:USERPROFILE 'Desktop'
$TempPath = Join-Path $Desktop 'SkripteTemp'
$ZipPath = Join-Path $Desktop 'Skripte.zip'
$ZipUrl = 'https://github.com/tueftelPark/Skripte/archive/refs/heads/main.zip'

Write-Host "==============================="
Write-Host "  Skripte aktualisieren"
Write-Host "==============================="

# 1) ExecutionPolicy setzen (falls erlaubt)
try {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop
    Write-Host "[*] ExecutionPolicy = RemoteSigned"
} catch {
    Write-Host "[!] Konnte ExecutionPolicy nicht aendern."
}

# 2) Alte Datei-Reste entfernen
Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue
Remove-Item $TempPath -Recurse -Force -ErrorAction SilentlyContinue

# 3) ZIP herunterladen
Write-Host "[*] Lade Skripte-Repo..."
Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -UseBasicParsing

# 4) ZIP entpacken
Write-Host "[*] Entpacke ZIP..."
Expand-Archive $ZipPath -DestinationPath $Desktop -Force

# 5) Entpackten Ordner finden (heisst immer Skripte-main)
$UnzipFolder = Join-Path $Desktop 'Skripte-main'

if (-not (Test-Path $UnzipFolder)) {
    Write-Host "[!] Entpackter Ordner nicht gefunden. Abbruch."
    exit
}

# 6) Alle .ps1 Dateien direkt auf Desktop verschieben
Write-Host "[*] Verschiebe Skripte auf den Desktop..."
Get-ChildItem -Path $UnzipFolder -Filter '*.ps1' -Recurse |
    ForEach-Object {
        Move-Item $_.FullName -Destination $Desktop -Force
    }

# 7) Alle Skripte entblocken
Write-Host "[*] Entblocke .ps1 Dateien..."
Get-ChildItem -Path $Desktop -Filter '*.ps1' |
    Unblock-File -ErrorAction SilentlyContinue

# 8) Aufraeumen — ZIP + entpackten Ordner löschen
Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue
Remove-Item $UnzipFolder -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[+] Fertig ✅ Alle Skripte liegen jetzt direkt auf dem Desktop."
Start-Process explorer.exe $Desktop
