# MasterUpdate.ps1
# Aktualisiert alle Tueftel-Projekte auf dem Desktop und richtet Policy/Unblock ein

$Desktop = Join-Path $env:USERPROFILE 'Desktop'

Write-Host "==============================="
Write-Host "  Master-Update Tueftel-Skripte"
Write-Host "==============================="
Write-Host ""

# 0) ExecutionPolicy anpassen (soweit moeglich)
try {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop
    Write-Host "[*] ExecutionPolicy (CurrentUser) auf RemoteSigned gesetzt."
} catch {
    Write-Host "[!] Konnte ExecutionPolicy nicht aendern (evtl. per Richtlinie gesperrt)."
}

# 0b) Alle PS-Skripte auf dem Desktop entblocken
try {
    Get-ChildItem -Path $Desktop -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue |
        Unblock-File -ErrorAction SilentlyContinue
    Write-Host "[*] Alle PS1-Dateien auf dem Desktop (soweit moeglich) entblockt."
} catch {
    Write-Host "[!] Konnte Dateien nicht entblocken (ist unkritisch, wenn schon frei gegeben)."
}

# 1) Arduino IDE und Explorer einmal schliessen
Write-Host ""
Write-Host "[*] Schliesse Arduino IDE..."
Get-Process -Name "Arduino IDE","arduino" -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "[*] Schliesse Explorer-Fenster..."
Get-Process -Name "explorer" -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue

# Hilfsfunktion fuer ein einzelnes Projekt
function Update-Project {
    param(
        [string]$Name,
        [string]$ZipUrl,
        [string]$UnzipFolderName
    )

    $TargetPath = Join-Path $Desktop $Name
    $ZipPath    = Join-Path $Desktop ($Name + '.zip')

    Write-Host ""
    Write-Host "=== $Name aktualisieren ==="

    # Alten Ordner loeschen (max. 3 Versuche)
    if (Test-Path $TargetPath) {
        Write-Host "[*] Loesche alten Ordner '$Name'..."
        $deleted = $false

        for ($tries = 1; $tries -le 3; $tries++) {
            Remove-Item $TargetPath -Recurse -Force -ErrorAction SilentlyContinue

            if (-not (Test-Path $TargetPath)) {
                Write-Host "    [+] Ordner geloescht."
                $deleted = $true
                break
            } else {
                Write-Host "    [!] Versuch $tries : Ordner blockiert, versuche erneut..."
                Start-Sleep -Milliseconds 700
            }
        }

        if (-not $deleted) {
            Write-Host "    [!] Konnte Ordner '$Name' nicht loeschen. Ueberspringe dieses Projekt."
            return
        }
    }

    # Alte ZIP loeschen
    Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue

    # ZIP laden
    Write-Host "[*] Lade ZIP von GitHub..."
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -UseBasicParsing

    # ZIP entpacken
    Write-Host "[*] Entpacke ZIP..."
    Expand-Archive $ZipPath -DestinationPath $Desktop -Force

    # Entpackten Ordner umbenennen
    $UnzipPath = Join-Path $Desktop $UnzipFolderName
    if (Test-Path $UnzipPath) {
        Rename-Item $UnzipPath $Name -Force
    } else {
        Write-Host "    [!] Entpackter Ordner '$UnzipFolderName' nicht gefunden."
    }

    # ZIP entfernen
    Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue

    Write-Host "[+] $Name fertig."
}

# Liste aller Projekte
$projects = @(
    @{
        Name            = 'ArduinoEinfuehrung'
        ZipUrl          = 'https://github.com/tueftelPark/ArduinoEinfuehrung/archive/refs/heads/SensorKit.zip'
        UnzipFolderName = 'ArduinoEinfuehrung-SensorKit'
    },
    @{
        Name            = 'BrennstoffzellePlus'
        ZipUrl          = 'https://github.com/tueftelPark/BrennstoffzellePlus/archive/refs/heads/main.zip'
        UnzipFolderName = 'BrennstoffzellePlus-main'
    },
    @{
        Name            = 'Sortieranlage'
        ZipUrl          = 'https://github.com/tueftelPark/Sortieranlage/archive/refs/heads/main.zip'
        UnzipFolderName = 'Sortieranlage-main'
    },
    @{
        Name            = 'AutonomesFahrzeug'
        ZipUrl          = 'https://github.com/tueftelPark/AutonomesFahrzeug/archive/refs/heads/main.zip'
        UnzipFolderName = 'AutonomesFahrzeug-main'
    },
    @{
        Name            = 'LEDmatrix'
        ZipUrl          = 'https://github.com/tueftelPark/LEDmatrix/archive/refs/heads/main.zip'
        UnzipFolderName = 'LEDmatrix-main'
    }
)

# Alle Projekte durchgehen
foreach ($p in $projects) {
    Update-Project -Name $p.Name -ZipUrl $p.ZipUrl -UnzipFolderName $p.UnzipFolderName
}

# Am Ende Explorer mit dem Desktop wieder starten (optional)
Start-Process explorer.exe $Desktop

Write-Host ""
Write-Host "[+] Master-Update abgeschlossen."
