#Requires -RunAsAdministrator
<#
.SYNOPSIS
    LogicFlow Solutions — Diagnostic et validation complète
.DESCRIPTION
    Étape 8 : Tests de validation de l'ensemble de l'infrastructure AD.
    Reproduit les 10 tests de la documentation E5.
.NOTES
    BTS SIO SISR — Session 2026 | Soufiane ZOUGAGH
#>

$Domain   = "logicflow.local"
$DomainDN = "DC=logicflow,DC=local"
$Pass = 0
$Fail = 0

function Test-Item {
    param([string]$Label, [scriptblock]$Check)
    try {
        $result = & $Check
        if ($result) {
            Write-Host "  ✅ $Label" -ForegroundColor Green
            $script:Pass++
        } else {
            Write-Host "  ❌ $Label" -ForegroundColor Red
            $script:Fail++
        }
    } catch {
        Write-Host "  ❌ $Label — ERREUR : $_" -ForegroundColor Red
        $script:Fail++
    }
}

Write-Host "`n════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  LogicFlow Solutions — Diagnostic Infrastructure AD" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# ─────────────────────────────────────────────
# DNS
# ─────────────────────────────────────────────
Write-Host "[ DNS ]" -ForegroundColor Yellow
Test-Item "Zone directe logicflow.local présente" {
    Get-DnsServerZone -Name $Domain -ErrorAction SilentlyContinue
}
Test-Item "Enregistrement A DC01 → 192.168.10.1" {
    $r = Resolve-DnsName -Name "DC01.$Domain" -Server 127.0.0.1 -ErrorAction SilentlyContinue
    $r.IPAddress -contains "192.168.10.1"
}
Test-Item "Zone inverse 10.168.192.in-addr.arpa présente" {
    Get-DnsServerZone -Name "10.168.192.in-addr.arpa" -ErrorAction SilentlyContinue
}
Test-Item "Redirecteurs DNS configurés (8.8.8.8 / 1.1.1.1)" {
    $fwd = Get-DnsServerForwarder
    $fwd.IPAddress -contains "8.8.8.8" -and $fwd.IPAddress -contains "1.1.1.1"
}

# ─────────────────────────────────────────────
# DHCP
# ─────────────────────────────────────────────
Write-Host "`n[ DHCP ]" -ForegroundColor Yellow
Test-Item "Étendue LAN_LogicFlow active" {
    $scope = Get-DhcpServerv4Scope -ScopeId "192.168.10.0" -ErrorAction SilentlyContinue
    $scope -and $scope.State -eq "Active"
}
Test-Item "Plage DHCP : 192.168.10.50 → .200" {
    $scope = Get-DhcpServerv4Scope -ScopeId "192.168.10.0" -ErrorAction SilentlyContinue
    $scope.StartRange -eq "192.168.10.50" -and $scope.EndRange -eq "192.168.10.200"
}

# ─────────────────────────────────────────────
# Active Directory
# ─────────────────────────────────────────────
Write-Host "`n[ Active Directory ]" -ForegroundColor Yellow
Test-Item "Domaine logicflow.local opérationnel" {
    Get-ADDomain -ErrorAction SilentlyContinue
}
Test-Item "4 OU créées (Direction / Informatique / Comptabilite / Employes)" {
    $ous = Get-ADOrganizationalUnit -Filter * -SearchBase $DomainDN -SearchScope OneLevel
    $ous.Count -ge 4
}
Test-Item "5 groupes GRP_ créés" {
    (Get-ADGroup -Filter "Name -like 'GRP_*'").Count -ge 5
}
Test-Item "40 comptes utilisateurs (hors built-in)" {
    $users = Get-ADUser -Filter * | Where-Object {
        $_.SamAccountName -notin @("Administrateur","Administrator","Invité","Guest")
    }
    $users.Count -ge 40
}
Test-Item "FSMO : DC01 est PDC Emulator" {
    (Get-ADDomain).PDCEmulator -like "DC01*"
}

# ─────────────────────────────────────────────
# Partages NTFS
# ─────────────────────────────────────────────
Write-Host "`n[ Partages réseau ]" -ForegroundColor Yellow
$expectedShares = @("Direction$", "Informatique$", "Comptabilite$", "Partage_Commun$")
foreach ($share in $expectedShares) {
    Test-Item "Partage $share présent" {
        Get-SmbShare -Name $share -ErrorAction SilentlyContinue
    }
}

# ─────────────────────────────────────────────
# GPO
# ─────────────────────────────────────────────
Write-Host "`n[ Stratégies de groupe ]" -ForegroundColor Yellow
$expectedGPOs = @("GPO_Informatique", "GPO_Direction", "GPO_Comptabilite", "GPO_Employes")
foreach ($gpo in $expectedGPOs) {
    Test-Item "GPO $gpo créée" {
        Get-GPO -Name $gpo -ErrorAction SilentlyContinue
    }
}

# ─────────────────────────────────────────────
# Résultat global
# ─────────────────────────────────────────────
$total = $Pass + $Fail
Write-Host "`n════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Résultat : $Pass/$total tests réussis" -ForegroundColor $(if ($Fail -eq 0) { "Green" } else { "Yellow" })
if ($Fail -gt 0) {
    Write-Host "  $Fail test(s) en échec — vérifiez les étapes concernées." -ForegroundColor Red
} else {
    Write-Host "  ✅ Infrastructure LogicFlow validée — prête pour l'évaluation E5 !" -ForegroundColor Green
}
Write-Host "════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Commandes de diagnostic complémentaires
Write-Host "Diagnostic dcdiag (résumé) :" -ForegroundColor Yellow
dcdiag /test:dns /test:netlogons /test:sysvol 2>&1 | Select-String -Pattern "passed|failed|FAIL|PASS" | Select-Object -First 10
