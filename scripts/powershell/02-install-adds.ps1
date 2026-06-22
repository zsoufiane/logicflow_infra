#Requires -RunAsAdministrator
<#
.SYNOPSIS
    LogicFlow Solutions — Installation et promotion AD DS
.DESCRIPTION
    Étape 1 : Installation du rôle AD DS et promotion du serveur
    en contrôleur de domaine pour logicflow.local.
    ATTENTION : Le serveur redémarre automatiquement à la fin.
.NOTES
    BTS SIO SISR — Session 2026 | Soufiane ZOUGAGH
#>

# ─────────────────────────────────────────────
# Variables de configuration
# ─────────────────────────────────────────────
$DomainName        = "logicflow.local"
$DomainNetBIOS     = "LOGICFLOW"
$ForestMode        = "WinThreshold"   # Windows Server 2016+
$DomainMode        = "WinThreshold"
$DSRMPassword      = "P@ssword_DSRM2026!"
$NTDSPath          = "C:\Windows\NTDS"
$SYSVOLPath        = "C:\Windows\SYSVOL"

Write-Host "`n=== LogicFlow Solutions — Installation AD DS ===" -ForegroundColor Cyan
Write-Host "Domaine : $DomainName | NetBIOS : $DomainNetBIOS`n" -ForegroundColor Gray

# ─────────────────────────────────────────────
# 1. Installation du rôle AD DS
# ─────────────────────────────────────────────
Write-Host "[1/2] Installation du rôle AD DS..." -ForegroundColor Yellow

$feature = Get-WindowsFeature -Name AD-Domain-Services
if ($feature.Installed) {
    Write-Host "      Rôle AD DS déjà installé." -ForegroundColor Green
} else {
    Install-WindowsFeature `
        -Name AD-Domain-Services `
        -IncludeManagementTools `
        -IncludeAllSubFeature | Out-Null
    Write-Host "      Rôle AD DS installé avec succès." -ForegroundColor Green
}

# ─────────────────────────────────────────────
# 2. Promotion en contrôleur de domaine
# ─────────────────────────────────────────────
Write-Host "[2/2] Promotion du serveur en contrôleur de domaine..." -ForegroundColor Yellow
Write-Host "      Domaine : $DomainName" -ForegroundColor Gray
Write-Host "      ATTENTION : Le serveur va redémarrer automatiquement." -ForegroundColor Red

$SecureDSRM = ConvertTo-SecureString $DSRMPassword -AsPlainText -Force

Import-Module ADDSDeployment

Install-ADDSForest `
    -DomainName            $DomainName `
    -DomainNetbiosName     $DomainNetBIOS `
    -ForestMode            $ForestMode `
    -DomainMode            $DomainMode `
    -InstallDns            $true `
    -CreateDnsDelegation   $false `
    -DatabasePath          $NTDSPath `
    -SysvolPath            $SYSVOLPath `
    -SafeModeAdministratorPassword $SecureDSRM `
    -Force                 $true `
    -NoRebootOnCompletion  $false

# Le serveur redémarre ici automatiquement.
# Après redémarrage, se connecter avec LOGICFLOW\Administrateur
