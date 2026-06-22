# Fine-Grained Password Policy — PSO_Comptabilite

> Configuration via **Centre d'administration Active Directory (ADAC)** :  
> `dsac.exe` → `logicflow.local` → `System` → `Password Settings Container`  
> ou via PowerShell (méthode recommandée ci-dessous)

---

## Paramètres PSO

| Paramètre | Valeur |
|-----------|--------|
| Nom | `PSO_Comptabilite` |
| Priorité (Precedence) | **10** (inférieur = prioritaire sur Default Domain Policy) |
| Longueur minimale | **12 caractères** |
| Historique | 10 mots de passe mémorisés |
| Durée maximale | 60 jours |
| Durée minimale | 1 jour |
| Complexité | Activée |
| Seuil de verrouillage | 5 tentatives échouées |
| Durée d'observation | 30 minutes |
| Durée de verrouillage | 30 minutes (ou déverrouillage admin) |
| S'applique à | `GRP_Comptabilite` |

---

## Création via PowerShell

```powershell
New-ADFineGrainedPasswordPolicy `
    -Name                      "PSO_Comptabilite" `
    -Precedence                10 `
    -MinPasswordLength         12 `
    -PasswordHistoryCount      10 `
    -MaxPasswordAge            (New-TimeSpan -Days 60) `
    -MinPasswordAge            (New-TimeSpan -Days 1) `
    -ComplexityEnabled         $true `
    -ReversibleEncryptionEnabled $false `
    -LockoutThreshold          5 `
    -LockoutObservationWindow  (New-TimeSpan -Minutes 30) `
    -LockoutDuration           (New-TimeSpan -Minutes 30)

# Appliquer la PSO au groupe Comptabilité
Add-ADFineGrainedPasswordPolicySubject `
    -Identity "PSO_Comptabilite" `
    -Subjects "GRP_Comptabilite"
```

---

## Vérification

```powershell
# Lister les PSO
Get-ADFineGrainedPasswordPolicy -Filter * |
    Select-Object Name, Precedence, MinPasswordLength, LockoutThreshold

# Vérifier quelle PSO s'applique à un utilisateur
Get-ADUserResultantPasswordPolicy -Identity "m.dupont"

# Lister les sujets d'une PSO
Get-ADFineGrainedPasswordPolicySubject -Identity "PSO_Comptabilite"
```

---

## Comparatif Default Domain Policy vs PSO_Comptabilite

| Paramètre | Default Domain Policy | PSO_Comptabilite |
|-----------|----------------------|-----------------|
| Longueur min. | 8 caractères | **12 caractères** |
| Historique | 5 | **10** |
| Durée max. | 90 jours | **60 jours** |
| Verrouillage | — | **5 tentatives / 30 min** |
| Priorité | (défaut) | **10 (prioritaire)** |
