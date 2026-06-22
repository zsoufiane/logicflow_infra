# 🖥️ LogicFlow Solutions — Infrastructure Active Directory Windows Server 2022

> **BTS SIO — Option SISR | Session 2026 | Épreuve E5**  
> Réalisation Professionnelle n°1 — Mise en œuvre d'une infrastructure réseau centralisée et sécurisée

---

## 📋 Présentation du projet

Déploiement complet d'une infrastructure **Active Directory Domain Services** sous **Windows Server 2022** pour LogicFlow Solutions, une PME de 40 collaborateurs spécialisée en transformation numérique.

Ce projet remplace un groupe de travail (Workgroup) non maîtrisé par un domaine AD centralisé, sécurisé et auditable.

---

## 🏗️ Architecture

| Composant | Valeur |
|-----------|--------|
| Domaine AD | `logicflow.local` |
| Contrôleur de domaine | `DC01` — `192.168.10.1/24` |
| Plage DHCP clients | `192.168.10.50` → `192.168.10.200` |
| Hyperviseur | VMware Workstation Pro 17 |
| OS Serveur | Windows Server 2022 Standard (Desktop Experience) |

```
192.168.10.0/24 — LAN_LogicFlow (VMware LAN Segment)
├── DC01          192.168.10.1    → AD DS + DNS + DHCP
├── [Réservé]     .2 → .49        → Serveurs / équipements réseau
├── [DHCP]        .50 → .200      → Postes clients
└── Passerelle    192.168.10.254  → Routeur / accès WAN
```

---

## 🗂️ Structure du dépôt

```
logicflow-ad-infra/
├── README.md
├── docs/
│   ├── 01-contexte-objectifs.md
│   ├── 02-environnement-technique.md
│   ├── 03-deploiement-adds.md
│   ├── 04-dns-dhcp.md
│   ├── 05-gpo.md
│   ├── 06-ntfs-partages.md
│   ├── 07-tests-validation.md
│   └── 08-bilan-competences.md
├── scripts/
│   ├── powershell/
│   │   ├── 01-config-initiale.ps1
│   │   ├── 02-install-adds.ps1
│   │   ├── 03-config-dns.ps1
│   │   ├── 04-config-dhcp.ps1
│   │   ├── 05-create-ou-groupes.ps1
│   │   ├── 06-create-users.ps1
│   │   ├── 07-ntfs-partages.ps1
│   │   └── 08-diagnostic.ps1
│   └── gpo/
│       └── gpo-settings-reference.md
├── configs/
│   ├── plan-adressage.md
│   ├── fgpp-comptabilite.md
│   └── checklist-deploiement.md
└── tests/
    └── tests-validation.md
```

---

## 🚀 Déploiement rapide

### Prérequis
- VMware Workstation Pro 17
- ISO Windows Server 2022 ([évaluation 180j](https://www.microsoft.com/fr-fr/evalcenter/evaluate-windows-server-2022))
- VM : 2 vCPU / 4 Go RAM / 80 Go disque / LAN Segment `LAN_LogicFlow`

### Ordre d'exécution

```powershell
# 1. Configuration initiale (IP fixe, renommage)
.\scripts\powershell\01-config-initiale.ps1

# 2. Installation et promotion AD DS
.\scripts\powershell\02-install-adds.ps1

# 3. Configuration DNS
.\scripts\powershell\03-config-dns.ps1

# 4. Configuration DHCP
.\scripts\powershell\04-config-dhcp.ps1

# 5. Création des OU et groupes
.\scripts\powershell\05-create-ou-groupes.ps1

# 6. Création des 40 comptes utilisateurs
.\scripts\powershell\06-create-users.ps1

# 7. Partages réseau et droits NTFS
.\scripts\powershell\07-ntfs-partages.ps1

# 8. Vérification globale
.\scripts\powershell\08-diagnostic.ps1
```

---

## 👥 Structure organisationnelle

| OU | Utilisateurs | Groupe | Droits partage |
|----|-------------|--------|----------------|
| Direction | 4 | `GRP_Direction` | `\\DC01\Direction$` — Contrôle total |
| Informatique | 6 | `GRP_Informatique` | `\\DC01\Informatique$` — Contrôle total |
| Comptabilite | 10 | `GRP_Comptabilite` | `\\DC01\Comptabilite$` — Lecture/Écriture |
| Employes | 20 | `GRP_Employes` | `\\DC01\Partage_Commun$` — Lecture seule |

---

## 🔒 Sécurité

- **Principe du moindre privilège** appliqué sur toutes les ACL NTFS
- **Héritage désactivé** sur les dossiers sensibles (Direction, Comptabilité)
- **Audit d'accès** activé sur `Comptabilite$` (EventID 4663)
- **Fine-Grained Password Policy** pour `GRP_Comptabilite` (12 car. min, PSO priorité 10)
- Groupe `Everyone` supprimé de toutes les ACL de partage

---

## ✅ Résultats des tests

| Test | Procédure | Statut |
|------|-----------|--------|
| Jonction domaine | Poste client → `logicflow.local` | ✅ OK |
| Authentification AD | Connexion avec compte de domaine | ✅ OK |
| Résolution DNS interne | `nslookup DC01.logicflow.local` | ✅ OK |
| Attribution DHCP | `ipconfig /all` sur client | ✅ OK |
| Application GPO | `gpresult /r` par pôle | ✅ OK |
| Accès partage autorisé | Connexion UNC par pôle | ✅ OK |
| Refus accès croisé | `Comptabilite$` depuis compte Employés | ✅ OK |
| Mise à jour GPO | `gpupdate /force` | ✅ OK |

**8/8 tests réussis ✅**

---

## 📚 Compétences BTS SIO SISR mobilisées

| Bloc | Compétence |
|------|-----------|
| B2 | Concevoir une solution d'infrastructure réseau |
| B2 | Installer, tester et déployer une solution réseau |
| B2 | Exploiter et superviser une infrastructure |
| B3 | Sécuriser les accès aux ressources |

---

## 👤 Auteur

**Soufiane ZOUGAGH** — N° candidat `0254152519`  
BTS SIO SISR — INGETIS Paris — Session 2026  
Entreprise support : LogicFlow Solutions (fictif)
