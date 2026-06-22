#Requires -RunAsAdministrator
<#
.SYNOPSIS
    LogicFlow Solutions — Partages réseau et droits NTFS
.DESCRIPTION
    Étape 6 : Création des dossiers partagés, configuration des droits NTFS
    (principe du moindre privilège) et activation de l'audit sur Comptabilite$.
.NOTES
    BTS SIO SISR — Session 2026 | Soufiane ZOUGAGH
#>

$SharesRoot = "C:\Shares"

Write-Host "`n=== LogicFlow Solutions — Partages NTFS ===" -ForegroundColor Cyan
Write-Host "Principe du moindre privilège | Héritage désactivé | Everyone supprimé`n" -ForegroundColor Gray

# ─────────────────────────────────────────────
# Définition des partages
# ─────────────────────────────────────────────
$Shares = @(
    @{
        Folder      = "Direction"
        ShareName   = "Direction$"
        Group       = "LOGICFLOW\GRP_Direction"
        NTFSRights  = "FullControl"
        AuditAccess = $false
    }
    @{
        Folder      = "Informatique"
        ShareName   = "Informatique$"
        Group       = "LOGICFLOW\GRP_Informatique"
        NTFSRights  = "FullControl"
        AuditAccess = $false
    }
    @{
        Folder      = "Comptabilite"
        ShareName   = "Comptabilite$"
        Group       = "LOGICFLOW\GRP_Comptabilite"
        NTFSRights  = "Modify"
        AuditAccess = $true
    }
    @{
        Folder      = "Partage_Commun"
        ShareName   = "Partage_Commun$"
        Group       = "LOGICFLOW\Domain Users"
        NTFSRights  = "ReadAndExecute"
        AuditAccess = $false
    }
)

# ─────────────────────────────────────────────
# 1. Création du dossier racine
# ─────────────────────────────────────────────
if (-not (Test-Path $SharesRoot)) {
    New-Item -ItemType Directory -Path $SharesRoot | Out-Null
    Write-Host "[OK] Dossier racine $SharesRoot créé." -ForegroundColor Green
}

# ─────────────────────────────────────────────
# 2. Création et configuration de chaque partage
# ─────────────────────────────────────────────
foreach ($s in $Shares) {
    $folderPath = "$SharesRoot\$($s.Folder)"

    Write-Host "`n--- $($s.ShareName) ---" -ForegroundColor Cyan

    # Créer le dossier
    if (-not (Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath | Out-Null
    }
    Write-Host "    Dossier : $folderPath" -ForegroundColor Gray

    # Partage SMB (masqué avec $)
    $existingShare = Get-SmbShare -Name $s.ShareName -ErrorAction SilentlyContinue
    if (-not $existingShare) {
        New-SmbShare -Name $s.ShareName -Path $folderPath -FullAccess "LOGICFLOW\Domain Admins" | Out-Null
    }

    # Permissions SMB : supprimer Everyone, ajouter le groupe métier
    Revoke-SmbShareAccess -Name $s.ShareName -AccountName "Everyone" -Force -ErrorAction SilentlyContinue
    Grant-SmbShareAccess  -Name $s.ShareName -AccountName $s.Group -AccessRight Change -Force | Out-Null
    Write-Host "    Partage SMB $($s.ShareName) configuré → $($s.Group)" -ForegroundColor Green

    # Droits NTFS : désactiver l'héritage et nettoyer
    $acl = Get-Acl $folderPath
    $acl.SetAccessRuleProtection($true, $false)   # Désactive l'héritage, supprime les règles héritées

    # Supprimer Everyone si présent
    $everyoneRule = $acl.Access | Where-Object { $_.IdentityReference -like "*Everyone*" -or $_.IdentityReference -like "*Tout le monde*" }
    foreach ($r in $everyoneRule) { $acl.RemoveAccessRule($r) | Out-Null }

    # Ajouter SYSTEM
    $acl.AddAccessRule(
        (New-Object System.Security.AccessControl.FileSystemAccessRule(
            "NT AUTHORITY\SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
        ))
    )
    # Ajouter Domain Admins
    $acl.AddAccessRule(
        (New-Object System.Security.AccessControl.FileSystemAccessRule(
            "LOGICFLOW\Domain Admins", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
        ))
    )
    # Ajouter le groupe métier
    $acl.AddAccessRule(
        (New-Object System.Security.AccessControl.FileSystemAccessRule(
            $s.Group, $s.NTFSRights, "ContainerInherit,ObjectInherit", "None", "Allow"
        ))
    )
    Set-Acl -Path $folderPath -AclObject $acl
    Write-Host "    Droits NTFS $($s.NTFSRights) → $($s.Group)" -ForegroundColor Green

    # Audit sur Comptabilite$
    if ($s.AuditAccess) {
        $auditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
            "Everyone",
            "ReadData,WriteData,Delete",
            "ContainerInherit,ObjectInherit",
            "None",
            "Success,Failure"
        )
        $acl = Get-Acl $folderPath
        $acl.AddAuditRule($auditRule)
        Set-Acl -Path $folderPath -AclObject $acl
        Write-Host "    Audit activé (Succès + Échec) — EventID 4663" -ForegroundColor Yellow
    }
}

# ─────────────────────────────────────────────
# Vérification
# ─────────────────────────────────────────────
Write-Host "`n=== Partages SMB actifs ===" -ForegroundColor Cyan
Get-SmbShare | Where-Object { $_.Name -like "*$" -and $_.Name -ne "ADMIN$" -and $_.Name -ne "C$" -and $_.Name -ne "IPC$" } |
    Select-Object Name, Path | Format-Table -AutoSize

Write-Host "✅ Partages NTFS configurés. Exécutez 08-diagnostic.ps1`n" -ForegroundColor Green
