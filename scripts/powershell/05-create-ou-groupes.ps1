#Requires -RunAsAdministrator
<#
.SYNOPSIS
    LogicFlow Solutions — Création des OU et groupes de sécurité
.DESCRIPTION
    Étape 4 : Création des 4 Unités Organisationnelles et des 5 groupes
    de sécurité globaux dans Active Directory.
.NOTES
    BTS SIO SISR — Session 2026 | Soufiane ZOUGAGH
#>

$DomainDN = "DC=logicflow,DC=local"

Write-Host "`n=== LogicFlow Solutions — Création OU et Groupes ===" -ForegroundColor Cyan

# ─────────────────────────────────────────────
# 1. Création des Unités Organisationnelles
# ─────────────────────────────────────────────
Write-Host "`n[1/2] Création des Unités Organisationnelles..." -ForegroundColor Yellow

$OUs = @(
    @{ Name = "Direction";    Description = "Pôle Direction — 4 utilisateurs" }
    @{ Name = "Informatique"; Description = "Service IT — 6 administrateurs" }
    @{ Name = "Comptabilite"; Description = "Pôle Comptabilité — 10 utilisateurs" }
    @{ Name = "Employes";     Description = "Pôle Opérationnel — 20 utilisateurs" }
)

foreach ($ou in $OUs) {
    $ouDN = "OU=$($ou.Name),$DomainDN"
    $exists = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDN'" -ErrorAction SilentlyContinue

    if ($exists) {
        Write-Host "      OU=$($ou.Name) déjà existante." -ForegroundColor Gray
    } else {
        New-ADOrganizationalUnit `
            -Name                            $ou.Name `
            -Path                            $DomainDN `
            -Description                     $ou.Description `
            -ProtectedFromAccidentalDeletion $true
        Write-Host "      OU=$($ou.Name) créée ✅" -ForegroundColor Green
    }
}

# ─────────────────────────────────────────────
# 2. Création des groupes de sécurité
# ─────────────────────────────────────────────
Write-Host "`n[2/2] Création des groupes de sécurité globaux..." -ForegroundColor Yellow

$Groups = @(
    @{ Name = "GRP_Direction";    OU = "Direction";    Description = "Membres de la Direction" }
    @{ Name = "GRP_Informatique"; OU = "Informatique"; Description = "Service IT / Administrateurs" }
    @{ Name = "GRP_Comptabilite"; OU = "Comptabilite"; Description = "Pôle Comptabilité" }
    @{ Name = "GRP_Employes";     OU = "Employes";     Description = "Pôle Opérationnel" }
    @{ Name = "GRP_Admins_SI";    OU = "Informatique"; Description = "Administrateurs globaux SI (IT + Direction)" }
)

foreach ($grp in $Groups) {
    $grpPath = "OU=$($grp.OU),$DomainDN"
    $exists  = Get-ADGroup -Filter "Name -eq '$($grp.Name)'" -ErrorAction SilentlyContinue

    if ($exists) {
        Write-Host "      $($grp.Name) déjà existant." -ForegroundColor Gray
    } else {
        New-ADGroup `
            -Name          $grp.Name `
            -GroupScope    Global `
            -GroupCategory Security `
            -Path          $grpPath `
            -Description   $grp.Description
        Write-Host "      $($grp.Name) créé dans OU=$($grp.OU) ✅" -ForegroundColor Green
    }
}

# ─────────────────────────────────────────────
# Vérification
# ─────────────────────────────────────────────
Write-Host "`n=== Récapitulatif ===" -ForegroundColor Cyan
Write-Host "OU créées :" -ForegroundColor Gray
Get-ADOrganizationalUnit -Filter * -SearchBase $DomainDN -SearchScope OneLevel |
    Select-Object Name, DistinguishedName | Format-Table -AutoSize

Write-Host "Groupes de sécurité :" -ForegroundColor Gray
Get-ADGroup -Filter "Name -like 'GRP_*'" |
    Select-Object Name, GroupScope, DistinguishedName | Format-Table -AutoSize

Write-Host "✅ OU et groupes créés. Exécutez 06-create-users.ps1`n" -ForegroundColor Green
