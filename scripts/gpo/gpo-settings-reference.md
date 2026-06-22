# GPO — Référence des paramètres LogicFlow Solutions

> Configuration via `gpmc.msc` → Gestionnaire de stratégies de groupe  
> Toutes les GPO sont créées sous : `Objets de stratégie de groupe` → liées à leur OU respective

---

## GPO_Informatique → `OU=Informatique`

| Chemin dans l'éditeur | Paramètre | Valeur |
|----------------------|-----------|--------|
| Config. ordi → Paramètres Windows → Sécurité → Pare-feu | Pare-feu local | **Désactivé** |
| Config. ordi → Modèles admin → Composants Windows → Bureau à distance | Connexions RDP | **Autorisées** |
| Config. utilisateur → Modèles admin → Système → Économiseur d'écran | Délai verrouillage | **1800 sec (30 min)** |

**Accès supplémentaires :**
- RSAT et outils d'administration accessibles
- Installation de logiciels sans restriction
- RDP activé pour l'administration distante

---

## GPO_Direction → `OU=Direction`

| Chemin dans l'éditeur | Paramètre | Valeur |
|----------------------|-----------|--------|
| Config. utilisateur → Modèles admin → Bureau → Bureau | Fond d'écran | `\\DC01\NETLOGON\logicflow_bg.jpg` |
| Config. utilisateur → Modèles admin → Panneau de configuration | Accès panneau config | **Désactivé** |
| Config. utilisateur → Modèles admin → Système → Économiseur d'écran | Délai verrouillage | **900 sec (15 min)** |

**Accès supplémentaires :**
- Partage confidentiel `\\DC01\Direction$` (Contrôle total)
- BitLocker recommandé sur les postes mobiles

---

## GPO_Comptabilite → `OU=Comptabilite`

| Chemin dans l'éditeur | Paramètre | Valeur |
|----------------------|-----------|--------|
| Config. ordi → Paramètres Windows → Sécurité → Stratégies locales → Audit | Audit connexion | **Succès + Échec** |
| Config. ordi → Modèles admin → Système → Accès stockage amovible | Écriture USB | **Refusée** |
| Config. ordi → Paramètres Windows → Bureau à distance | RDP | **Désactivé** |
| Config. utilisateur → Modèles admin → Système → Économiseur d'écran | Délai verrouillage | **600 sec (10 min)** |

**Politique de mot de passe (PSO distincte) :** 12 caractères minimum — voir `fgpp-comptabilite.md`

---

## GPO_Employes → `OU=Employes`

| Chemin dans l'éditeur | Paramètre | Valeur |
|----------------------|-----------|--------|
| Config. utilisateur → Modèles admin → Panneau de configuration | Accès panneau config | **Désactivé** |
| Config. utilisateur → Modèles admin → Système → Installation logiciels | Installation MSI | **Désactivée** |
| Config. ordi → Paramètres Windows → Bureau à distance | RDP | **Désactivé** |
| Config. utilisateur → Modèles admin → Système → Économiseur d'écran | Délai verrouillage | **600 sec (10 min)** |

---

## Validation des GPO

```powershell
# Forcer l'application immédiate
gpupdate /force

# Vérifier les GPO appliquées (depuis un poste client du domaine)
gpresult /r

# Rapport HTML complet
gpresult /h C:\Scripts\gpresult_rapport.html
Start-Process C:\Scripts\gpresult_rapport.html

# Vérifier l'héritage GPO d'une OU
Get-GPInheritance -Target "OU=Comptabilite,DC=logicflow,DC=local"

# Lister toutes les GPO du domaine
Get-GPO -All | Select-Object DisplayName, GpoStatus | Format-Table -AutoSize
```
