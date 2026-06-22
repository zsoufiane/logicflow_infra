# Checklist de déploiement — LogicFlow Solutions AD DS

> Cocher chaque étape une fois complétée et validée avant de passer à la suivante.

## Prérequis VMware

- [ ] **V.1** — ISO Windows Server 2022 téléchargée (évaluation 180j)
- [ ] **V.2** — VM DC01 créée dans VMware Workstation (2 vCPU / 4 Go RAM / 80 Go disque)
- [ ] **V.3** — Réseau configuré en LAN Segment `LAN_LogicFlow`
- [ ] **V.4** — Windows Server 2022 **Desktop Experience** installé (pas Server Core)
- [ ] **V.5** — VMware Tools installés et opérationnels

## Configuration du serveur

- [ ] **Étape 0** — Serveur renommé `DC01` + IP fixe `192.168.10.1/24` configurée
  - Script : `.\scripts\powershell\01-config-initiale.ps1`

## Active Directory

- [ ] **Étape 1** — Rôle AD DS installé + Domaine `logicflow.local` créé
  - Script : `.\scripts\powershell\02-install-adds.ps1`
  - ⚠️ Redémarrage automatique — se reconnecter avec `LOGICFLOW\Administrateur`

## Services réseau

- [ ] **Étape 2** — DNS : zone directe + inverse + redirecteurs (8.8.8.8 / 1.1.1.1)
  - Script : `.\scripts\powershell\03-config-dns.ps1`
- [ ] **Étape 3** — DHCP : étendue `LAN_LogicFlow` active (plage .50 → .200)
  - Script : `.\scripts\powershell\04-config-dhcp.ps1`

## Structure AD

- [ ] **Étape 4** — 4 OU créées + 5 groupes de sécurité dans les bonnes OU
  - Script : `.\scripts\powershell\05-create-ou-groupes.ps1`
- [ ] **Étape 5** — 40 comptes utilisateurs créés + affectés aux groupes
  - Script : `.\scripts\powershell\06-create-users.ps1`

## Sécurité

- [ ] **Étape 6** — 4 partages réseau + droits NTFS + audit Comptabilité activé
  - Script : `.\scripts\powershell\07-ntfs-partages.ps1`
- [ ] **Étape 7** — 4 GPO créées, liées aux OU, paramètres appliqués
  - (Voir `scripts/gpo/gpo-settings-reference.md` — configuration via GPMC)
- [ ] **Étape 8** — Politique MDP domaine (Default Domain Policy) configurée
- [ ] **Étape 8b** — PSO `PSO_Comptabilite` (Fine-Grained Password Policy, priorité 10, 12 car.)

## Validation finale

- [ ] **Étape 9** — Tous les tests DC01 passés via `.\scripts\powershell\08-diagnostic.ps1`
- [ ] **Tests client** — VM PC-Client01 jointe au domaine, GPO vérifiée avec `gpresult /r`

---

## ✅ Déploiement validé

Si toutes les cases sont cochées et `08-diagnostic.ps1` affiche **tous les tests réussis**,
l'infrastructure Active Directory LogicFlow est opérationnelle et prête pour l'évaluation BTS SIO E5.
