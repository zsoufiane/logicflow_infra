#Requires -RunAsAdministrator
<#
.SYNOPSIS
    LogicFlow Solutions — Configuration initiale du serveur DC01
.DESCRIPTION
    Étape 0 : Renommage du serveur et configuration de l'adresse IP fixe.
    À exécuter AVANT l'installation d'AD DS.
.NOTES
    BTS SIO SISR — Session 2026 | Soufiane ZOUGAGH
#>

# ─────────────────────────────────────────────
# Variables de configuration
# ─────────────────────────────────────────────
$ServerName     = "DC01"
$IPAddress      = "192.168.10.1"
$PrefixLength   = 24
$DefaultGateway = "192.168.10.254"
$DNSPrimary     = "127.0.0.1"
$DNSSecondary   = "8.8.8.8"
$ScriptsPath    = "C:\Scripts"

Write-Host "`n=== LogicFlow Solutions — Configuration initiale ===" -ForegroundColor Cyan
Write-Host "DC01 | 192.168.10.1/24 | logicflow.local`n" -ForegroundColor Gray

# ─────────────────────────────────────────────
# 1. Renommage du serveur
# ─────────────────────────────────────────────
Write-Host "[1/4] Renommage du serveur en $ServerName..." -ForegroundColor Yellow
$currentName = $env:COMPUTERNAME
if ($currentName -ne $ServerName) {
    Rename-Computer -NewName $ServerName -Force
    Write-Host "      Serveur renommé en $ServerName (redémarrage requis)." -ForegroundColor Green
} else {
    Write-Host "      Serveur déjà nommé $ServerName." -ForegroundColor Green
}

# ─────────────────────────────────────────────
# 2. Configuration de l'adresse IP fixe
# ─────────────────────────────────────────────
Write-Host "[2/4] Configuration de l'adresse IP fixe..." -ForegroundColor Yellow

$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
if (-not $adapter) {
    Write-Host "      ERREUR : Aucun adaptateur réseau actif trouvé." -ForegroundColor Red
    exit 1
}

# Supprimer l'IP existante si elle existe
$existingIP = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
if ($existingIP) {
    Remove-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
}

New-NetIPAddress `
    -InterfaceIndex $adapter.InterfaceIndex `
    -IPAddress $IPAddress `
    -PrefixLength $PrefixLength `
    -DefaultGateway $DefaultGateway | Out-Null

Set-DnsClientServerAddress `
    -InterfaceIndex $adapter.InterfaceIndex `
    -ServerAddresses ($DNSPrimary, $DNSSecondary)

Write-Host "      IP fixe configurée : $IPAddress/$PrefixLength" -ForegroundColor Green
Write-Host "      Passerelle         : $DefaultGateway" -ForegroundColor Green
Write-Host "      DNS primaire       : $DNSPrimary" -ForegroundColor Green

# ─────────────────────────────────────────────
# 3. Autorisation d'exécution PowerShell
# ─────────────────────────────────────────────
Write-Host "[3/4] Configuration de la politique d'exécution PowerShell..." -ForegroundColor Yellow
Set-ExecutionPolicy RemoteSigned -Force
Write-Host "      ExecutionPolicy : RemoteSigned" -ForegroundColor Green

# ─────────────────────────────────────────────
# 4. Création du dossier de scripts
# ─────────────────────────────────────────────
Write-Host "[4/4] Création du dossier $ScriptsPath..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $ScriptsPath -Force | Out-Null
Write-Host "      Dossier $ScriptsPath créé." -ForegroundColor Green

# ─────────────────────────────────────────────
# Vérification
# ─────────────────────────────────────────────
Write-Host "`n=== Vérification ===" -ForegroundColor Cyan
ipconfig /all | Select-String -Pattern "Adresse IPv4|Serveur DNS|Passerelle"

Write-Host "`n✅ Configuration initiale terminée." -ForegroundColor Green
Write-Host "   Redémarrez le serveur pour appliquer le renommage, puis exécutez 02-install-adds.ps1`n" -ForegroundColor Yellow
