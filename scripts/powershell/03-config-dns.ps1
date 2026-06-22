#Requires -RunAsAdministrator
<#
.SYNOPSIS
    LogicFlow Solutions — Configuration DNS
.DESCRIPTION
    Étape 2 : Vérification de la zone directe, création de la zone inverse
    et configuration des redirecteurs DNS externes.
.NOTES
    BTS SIO SISR — Session 2026 | Soufiane ZOUGAGH
#>

$ZoneName      = "logicflow.local"
$ReverseZone   = "10.168.192.in-addr.arpa"
$DC01_IP       = "192.168.10.1"
$Forwarder1    = "8.8.8.8"
$Forwarder2    = "1.1.1.1"

Write-Host "`n=== LogicFlow Solutions — Configuration DNS ===" -ForegroundColor Cyan

# ─────────────────────────────────────────────
# 1. Vérification de la zone directe
# ─────────────────────────────────────────────
Write-Host "[1/3] Vérification de la zone directe $ZoneName..." -ForegroundColor Yellow

$directZone = Get-DnsServerZone -Name $ZoneName -ErrorAction SilentlyContinue
if ($directZone) {
    Write-Host "      Zone directe $ZoneName : OK" -ForegroundColor Green
} else {
    Write-Host "      ERREUR : Zone $ZoneName introuvable. AD DS est-il bien installé ?" -ForegroundColor Red
    exit 1
}

# Vérification de l'enregistrement A de DC01
$dc01Record = Get-DnsServerResourceRecord -ZoneName $ZoneName -Name "DC01" -RRType A -ErrorAction SilentlyContinue
if ($dc01Record) {
    Write-Host "      Enregistrement A DC01 → $DC01_IP : OK" -ForegroundColor Green
} else {
    Write-Host "      Enregistrement A DC01 manquant, création..." -ForegroundColor Yellow
    Add-DnsServerResourceRecordA -ZoneName $ZoneName -Name "DC01" -IPv4Address $DC01_IP
    Write-Host "      Enregistrement A DC01 créé." -ForegroundColor Green
}

# ─────────────────────────────────────────────
# 2. Création de la zone de recherche inverse
# ─────────────────────────────────────────────
Write-Host "[2/3] Création de la zone de recherche inverse..." -ForegroundColor Yellow

$reverseExists = Get-DnsServerZone -Name $ReverseZone -ErrorAction SilentlyContinue
if ($reverseExists) {
    Write-Host "      Zone inverse $ReverseZone déjà existante." -ForegroundColor Green
} else {
    Add-DnsServerPrimaryZone `
        -NetworkID "192.168.10.0/24" `
        -ReplicationScope "Forest" `
        -DynamicUpdate "Secure"
    Write-Host "      Zone inverse $ReverseZone créée." -ForegroundColor Green
}

# Enregistrement PTR pour DC01
$ptrExists = Get-DnsServerResourceRecord -ZoneName $ReverseZone -Name "1" -RRType PTR -ErrorAction SilentlyContinue
if (-not $ptrExists) {
    Add-DnsServerResourceRecordPtr `
        -ZoneName $ReverseZone `
        -Name "1" `
        -PtrDomainName "DC01.$ZoneName."
    Write-Host "      Enregistrement PTR DC01 créé." -ForegroundColor Green
} else {
    Write-Host "      Enregistrement PTR DC01 déjà présent." -ForegroundColor Green
}

# ─────────────────────────────────────────────
# 3. Configuration des redirecteurs DNS
# ─────────────────────────────────────────────
Write-Host "[3/3] Configuration des redirecteurs DNS..." -ForegroundColor Yellow

Set-DnsServerForwarder -IPAddress $Forwarder1, $Forwarder2 -PassThru | Out-Null
Write-Host "      Redirecteurs configurés : $Forwarder1 / $Forwarder2" -ForegroundColor Green

# ─────────────────────────────────────────────
# Vérification finale
# ─────────────────────────────────────────────
Write-Host "`n=== Tests de validation DNS ===" -ForegroundColor Cyan
nslookup DC01.$ZoneName 127.0.0.1
Write-Host ""
Write-Host "✅ Configuration DNS terminée." -ForegroundColor Green
