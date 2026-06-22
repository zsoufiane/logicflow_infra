#Requires -RunAsAdministrator
<#
.SYNOPSIS
    LogicFlow Solutions — Création des 40 comptes utilisateurs AD
.DESCRIPTION
    Étape 5 : Création de l'ensemble des comptes utilisateurs dans les OU,
    affectation aux groupes de sécurité.
    Convention : initiale prénom + point + nom (ex. m.dupont)
    UPN : identifiant@logicflow.local
.NOTES
    BTS SIO SISR — Session 2026 | Soufiane ZOUGAGH
#>

$Domain      = "logicflow.local"
$DomainDN    = "DC=logicflow,DC=local"
$DefaultPass = ConvertTo-SecureString "Logicflow@2026!" -AsPlainText -Force

Write-Host "`n=== LogicFlow Solutions — Création des 40 comptes utilisateurs ===" -ForegroundColor Cyan

# ─────────────────────────────────────────────
# Définition des utilisateurs
# ─────────────────────────────────────────────
$Users = @(
    # Direction (4 comptes)
    @{ First="Pierre";     Last="MARTIN";    Sam="p.martin";   OU="Direction";    Group="GRP_Direction" }
    @{ First="Sophie";     Last="BERNARD";   Sam="s.bernard";  OU="Direction";    Group="GRP_Direction" }
    @{ First="Laurent";    Last="THOMAS";    Sam="l.thomas";   OU="Direction";    Group="GRP_Direction" }
    @{ First="Claire";     Last="RICHARD";   Sam="c.richard";  OU="Direction";    Group="GRP_Direction" }

    # Informatique (6 comptes)
    @{ First="Antoine";    Last="DUPONT";    Sam="a.dupont";   OU="Informatique"; Group="GRP_Informatique" }
    @{ First="Thomas";     Last="LEBLANC";   Sam="t.leblanc";  OU="Informatique"; Group="GRP_Informatique" }
    @{ First="Nicolas";    Last="MOREAU";    Sam="n.moreau";   OU="Informatique"; Group="GRP_Informatique" }
    @{ First="Julie";      Last="SIMON";     Sam="j.simon";    OU="Informatique"; Group="GRP_Informatique" }
    @{ First="Romain";     Last="LAURENT";   Sam="r.laurent";  OU="Informatique"; Group="GRP_Informatique" }
    @{ First="Marie";      Last="GARCIA";    Sam="m.garcia";   OU="Informatique"; Group="GRP_Informatique" }

    # Comptabilite (10 comptes)
    @{ First="Marie";      Last="DUPONT";    Sam="m.dupont";   OU="Comptabilite"; Group="GRP_Comptabilite" }
    @{ First="Jean";       Last="DURAND";    Sam="j.durand";   OU="Comptabilite"; Group="GRP_Comptabilite" }
    @{ First="Isabelle";   Last="LEROY";     Sam="i.leroy";    OU="Comptabilite"; Group="GRP_Comptabilite" }
    @{ First="Francois";   Last="ROUSSEAU";  Sam="f.rousseau"; OU="Comptabilite"; Group="GRP_Comptabilite" }
    @{ First="Nathalie";   Last="BLANC";     Sam="n.blanc";    OU="Comptabilite"; Group="GRP_Comptabilite" }
    @{ First="Marc";       Last="GUERIN";    Sam="m.guerin";   OU="Comptabilite"; Group="GRP_Comptabilite" }
    @{ First="Sylvie";     Last="FAURE";     Sam="s.faure";    OU="Comptabilite"; Group="GRP_Comptabilite" }
    @{ First="Patrick";    Last="GIRARD";    Sam="p.girard";   OU="Comptabilite"; Group="GRP_Comptabilite" }
    @{ First="Veronique";  Last="ANDRE";     Sam="v.andre";    OU="Comptabilite"; Group="GRP_Comptabilite" }
    @{ First="Denis";      Last="LEFEBVRE";  Sam="d.lefebvre"; OU="Comptabilite"; Group="GRP_Comptabilite" }

    # Employes (20 comptes)
    @{ First="Christophe"; Last="THOMAS";    Sam="c.thomas";   OU="Employes";     Group="GRP_Employes" }
    @{ First="Noemie";     Last="PETIT";     Sam="n.petit";    OU="Employes";     Group="GRP_Employes" }
    @{ First="Kevin";      Last="ROBERT";    Sam="k.robert";   OU="Employes";     Group="GRP_Employes" }
    @{ First="Laura";      Last="RICHARD";   Sam="l.richard";  OU="Employes";     Group="GRP_Employes" }
    @{ First="Julien";     Last="DAVID";     Sam="j.david";    OU="Employes";     Group="GRP_Employes" }
    @{ First="Emma";       Last="BERNARD";   Sam="e.bernard";  OU="Employes";     Group="GRP_Employes" }
    @{ First="Maxime";     Last="ROUX";      Sam="m.roux";     OU="Employes";     Group="GRP_Employes" }
    @{ First="Celine";     Last="VINCENT";   Sam="c.vincent";  OU="Employes";     Group="GRP_Employes" }
    @{ First="Alexandre";  Last="MULLER";    Sam="a.muller";   OU="Employes";     Group="GRP_Employes" }
    @{ First="Lucie";      Last="LECOMTE";   Sam="l.lecomte";  OU="Employes";     Group="GRP_Employes" }
    @{ First="Quentin";    Last="BONNET";    Sam="q.bonnet";   OU="Employes";     Group="GRP_Employes" }
    @{ First="Aurelie";    Last="FRANCOIS";  Sam="a.francois"; OU="Employes";     Group="GRP_Employes" }
    @{ First="Damien";     Last="MARTINEZ";  Sam="d.martinez"; OU="Employes";     Group="GRP_Employes" }
    @{ First="Stephanie";  Last="LEGRAND";   Sam="s.legrand";  OU="Employes";     Group="GRP_Employes" }
    @{ First="Cedric";     Last="GARNIER";   Sam="c.garnier";  OU="Employes";     Group="GRP_Employes" }
    @{ First="Manon";      Last="CHEVALIER"; Sam="m.chevalier";OU="Employes";     Group="GRP_Employes" }
    @{ First="Sebastien";  Last="MORIN";     Sam="s.morin";    OU="Employes";     Group="GRP_Employes" }
    @{ First="Camille";    Last="RENARD";    Sam="c.renard";   OU="Employes";     Group="GRP_Employes" }
    @{ First="Gregory";    Last="CLEMENT";   Sam="g.clement";  OU="Employes";     Group="GRP_Employes" }
    @{ First="Pauline";    Last="MERCIER";   Sam="p.mercier";  OU="Employes";     Group="GRP_Employes" }
)

# ─────────────────────────────────────────────
# Création des comptes
# ─────────────────────────────────────────────
$created = 0
$skipped = 0

foreach ($u in $Users) {
    $ouPath     = "OU=$($u.OU),$DomainDN"
    $displayName = "$($u.First) $($u.Last)"
    $upn         = "$($u.Sam)@$Domain"

    $exists = Get-ADUser -Filter "SamAccountName -eq '$($u.Sam)'" -ErrorAction SilentlyContinue
    if ($exists) {
        Write-Host "      [SKIP] $($u.Sam) déjà existant." -ForegroundColor Gray
        $skipped++
        continue
    }

    New-ADUser `
        -Name                 $displayName `
        -GivenName            $u.First `
        -Surname              $u.Last `
        -SamAccountName       $u.Sam `
        -UserPrincipalName    $upn `
        -Path                 $ouPath `
        -AccountPassword      $DefaultPass `
        -ChangePasswordAtLogon $true `
        -Enabled              $true `
        -DisplayName          $displayName

    Add-ADGroupMember -Identity $u.Group -Members $u.Sam

    Write-Host "      [OK] $($u.Sam) créé dans OU=$($u.OU) → $($u.Group)" -ForegroundColor Green
    $created++
}

# Ajouter les IT dans GRP_Admins_SI
$itMembers = Get-ADGroupMember -Identity "GRP_Informatique" | Select-Object -ExpandProperty SamAccountName
foreach ($m in $itMembers) {
    Add-ADGroupMember -Identity "GRP_Admins_SI" -Members $m -ErrorAction SilentlyContinue
}
Write-Host "      Membres IT ajoutés à GRP_Admins_SI." -ForegroundColor Green

# ─────────────────────────────────────────────
# Récapitulatif
# ─────────────────────────────────────────────
Write-Host "`n=== Récapitulatif ===" -ForegroundColor Cyan
Write-Host "Comptes créés : $created | Ignorés (déjà existants) : $skipped" -ForegroundColor Gray

$total = (Get-ADUser -Filter * | Where-Object { $_.SamAccountName -ne "Administrateur" -and $_.SamAccountName -ne "Invité" }).Count
Write-Host "Total comptes dans le domaine (hors built-in) : $total" -ForegroundColor Gray

Write-Host "`n✅ Comptes utilisateurs créés. Exécutez 07-ntfs-partages.ps1`n" -ForegroundColor Green
