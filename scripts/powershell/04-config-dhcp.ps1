#Requires -RunAsAdministrator
<#
.SYNOPSIS
    LogicFlow Solutions — Installation et configuration DHCP
.DESCRIPTION
    Étape 3 : Installation du rôle DHCP, autorisation dans AD,
    et création de l'étendue LAN_LogicFlow.
.NOTES
    BTS SIO SISR — Session 2026 | Soufiane ZOUGAGH
#>

$ScopeName      = "LAN_LogicFlow"
$ScopeID        = "192.168.10.0"
$StartIP        = "192.168.10.50"
$EndIP          = "192.168.10.200"
$SubnetMask     = "255.255.255.0"
$ExcludeStart   = "192.168.10.1"
$ExcludeEnd     = "192.168.10.49"
$Gateway        = "192.168.10.254"
$DNS            = "192.168.10.1"
$DomainName     = "logicflow.local"
$LeaseDays      = 8

Write-Host "`n=== LogicFlow Solutions — Configuration DHCP ===" -ForegroundColor Cyan

# ─────────────────────────────────────────────
# 1. Installation du rôle DHCP
# ─────────────────────────────────────────────
Write-Host "[1/3] Installation du rôle DHCP..." -ForegroundColor Yellow

$feature = Get-WindowsFeature -Name DHCP
if ($feature.Installed) {
    Write-Host "      Rôle DHCP déjà installé." -ForegroundColor Green
} else {
    Install-WindowsFeature -Name DHCP -IncludeManagementTools | Out-Null
    Write-Host "      Rôle DHCP installé." -ForegroundColor Green
}

# Autorisation du serveur DHCP dans AD
Add-DhcpServerInDC -DnsName "DC01.$DomainName" -IPAddress $DNS -ErrorAction SilentlyContinue
Write-Host "      Serveur DHCP autorisé dans Active Directory." -ForegroundColor Green

# Suppression des alertes post-déploiement
Set-ItemProperty `
    -Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 `
    -Name ConfigurationState `
    -Value 2 `
    -ErrorAction SilentlyContinue

# ─────────────────────────────────────────────
# 2. Création de l'étendue
# ─────────────────────────────────────────────
Write-Host "[2/3] Création de l'étendue $ScopeName..." -ForegroundColor Yellow

$scopeExists = Get-DhcpServerv4Scope -ScopeId $ScopeID -ErrorAction SilentlyContinue
if ($scopeExists) {
    Write-Host "      Étendue $ScopeName déjà existante." -ForegroundColor Green
} else {
    Add-DhcpServerv4Scope `
        -Name        $ScopeName `
        -Description "Réseau interne LogicFlow Solutions" `
        -StartRange  $StartIP `
        -EndRange    $EndIP `
        -SubnetMask  $SubnetMask `
        -State       Active `
        -LeaseDuration (New-TimeSpan -Days $LeaseDays)

    # Exclusions (plage serveurs / équipements réseau)
    Add-DhcpServerv4ExclusionRange `
        -ScopeId    $ScopeID `
        -StartRange $ExcludeStart `
        -EndRange   $ExcludeEnd

    Write-Host "      Étendue créée : $StartIP → $EndIP" -ForegroundColor Green
    Write-Host "      Exclusions    : $ExcludeStart → $ExcludeEnd" -ForegroundColor Green
}

# ─────────────────────────────────────────────
# 3. Options DHCP (003 / 006 / 015)
# ─────────────────────────────────────────────
Write-Host "[3/3] Configuration des options DHCP..." -ForegroundColor Yellow

Set-DhcpServerv4OptionValue `
    -ScopeId   $ScopeID `
    -Router    $Gateway `
    -DnsServer $DNS `
    -DnsDomain $DomainName

Write-Host "      Option 003 (Routeur) : $Gateway" -ForegroundColor Green
Write-Host "      Option 006 (DNS)     : $DNS" -ForegroundColor Green
Write-Host "      Option 015 (Domaine) : $DomainName" -ForegroundColor Green

# ─────────────────────────────────────────────
# Vérification
# ─────────────────────────────────────────────
Write-Host "`n=== Vérification de l'étendue ===" -ForegroundColor Cyan
Get-DhcpServerv4Scope | Format-Table Name, ScopeId, StartRange, EndRange, State -AutoSize

Write-Host "✅ Configuration DHCP terminée.`n" -ForegroundColor Green
