---
name: update-spip
description: >-
  Met à jour une instance SPIP sur l'infrastructure de L'Autre Net (AlternC, Debian, NFS, Apache/Nginx, spip-cli).
  Gère les sauvegardes préalables (SQL et fichiers), la détection/quarantaine de webshells et portes dérobées,
  le choix de la version PHP appropriée (php74-fpm / php85-fpm), la synchronisation propre du cœur SPIP,
  la mise à niveau du schéma de base de données, la purge des caches et la documentation sur Forgejo.
---

# Procédure de mise à jour SPIP — L'Autre Net

Cette compétence formalise la méthode standardisée et sécurisée pour mettre à jour une instance SPIP hébergée sur l'infrastructure AlternC de L'Autre Net.

## Déclencheurs

Active cette compétence lorsque :
- L'utilisateur demande de mettre à jour un SPIP ("met à jour le spip", "passe ce spip en 4.4", etc.).
- Un ticket Forgejo (sur `lautre.net/aide-generale`) demande une intervention de mise à jour SPIP à la suite d'un scan ou d'une alerte CVE (ex: CVE-2023-27372, CVE-2024-8517, CVE-2024-7954).
- Un site SPIP présente des signes d'infection ou de webshells nécessitant nettoyage et montée de version.

---

## 1. Contexte & Spécificités d'Infrastructure

| Composant | Comportement & Précautions |
|---|---|
| **Stockage web** | `/var/www/alternc/X/compte/www/site` monté en NFSv3 (`local_lock=none`). Ne pas utiliser d'appels `flock` bloquants exclusifs. |
| **CLI & PHP global** | `/usr/bin/php` pointe souvent par défaut vers PHP 5.6 (`update-alternatives` en mode manuel pour les scripts AlternC). |
| **PHP pour SPIP** | SPIP 4.x requiert PHP 7.4 minimum. Ne pas utiliser le PHP global 5.6. Utiliser explicitement `/usr/bin/php7.4` ou `/usr/bin/php8.2` / `/usr/bin/php8.5`. |
| **Vhost AlternC** | Vérifier dans `sub_domaines` (`type` : `php74-fpm` ou `php85-fpm`). Si en `vhost` (mod_php 5.6), basculer en `php74-fpm`. |
| **spip-cli** | Wrapper `/usr/local/bin/spip` ou invocation directe `/usr/bin/php7.4 /opt/spip-cli/bin/spip`. Éviter `spip dl` via Composer qui peut invoquer PHP 5.6 et échouer sur les dépendances. Préférer l'archive de distribution propre. |
| **Archives de référence** | Archives officielles pré-téléchargées sur les serveurs backend (ex: `/root/incident-spip-20261023/spip_archives/spip-v4.4.28.zip`). |

---

## 2. Déroulement étape par étape

### Étape 1 : Identification et Recensement

1. Identifier le compte AlternC, la racine web et le nom de la base de données :
   ```bash
   grep -ri "spip" /var/alternc/bind/named.client.*
   # ou lecture dans config/connect.php
   cat /var/www/alternc/<initiale>/<compte>/www/<site>/config/connect.php
   ```
2. Vérifier la configuration PHP du vhost dans MySQL AlternC (`alternc.sub_domaines`) :
   ```bash
   mysql -e "SELECT sub, domaine, type FROM sub_domaines WHERE sub='<sous-domaine>' AND domaine='<domaine>';" alternc
   ```
   Si le `type` est `vhost`, le basculer en `php74-fpm` via :
   ```bash
   mysql -e "UPDATE sub_domaines SET type='php74-fpm' WHERE sub='<sous-domaine>' AND domaine='<domaine>';" alternc
   /usr/lib/alternc/update_domains.sh
   ```

---

### Étape 2 : Sauvegardes obligatoires (Avant toute modification)

> [!IMPORTANT]
> Toujours générer une sauvegarde complète de la base MySQL et de l'arborescence web avant toute action.

```bash
DATE=$(date +%Y%m%d)
# Sauvegarde Base de Données
mysqldump --single-transaction --routines --triggers <base_spip> | gzip > /root/<compte>_<site>_pre_maj_${DATE}.sql.gz

# Sauvegarde Arborescence Web
tar czf /root/<compte>_<site>_pre_maj_${DATE}.tar.gz -C /var/www/alternc/<initiale>/<compte>/www <site>
```

---

### Étape 3 : Audit d'intégrité & Quarantaine (Sans suppression)

> [!CAUTION]
> Règle stricte de L'Autre Net : **Aucune suppression directe**. Tout fichier suspect (webshell, script tiers inconnu) doit être mis en quarantaine par **déplacement**, documenté avec ses empreintes MD5 et SHA256.

1. **Recherche de webshells connus** :
   ```bash
   DIR="/var/www/alternc/<initiale>/<compte>/www/<site>"
   find "$DIR" -maxdepth 2 -name "x*.php" -o -name "old_spip_loader*.php" -o -name ".*.php"
   ```
2. **Création du répertoire de quarantaine** :
   ```bash
   QDIR="/root/incident-spip-20261023/<compte>-quarantaine-${DATE}"
   mkdir -p "$QDIR"
   ```
3. **Calcul des empreintes et déplacement** :
   ```bash
   for f in "$DIR"/x*.php "$DIR"/old_spip_loader*.php; do
       if [ -f "$f" ]; then
           sha256sum "$f" >> "$QDIR/empreintes-sha256.txt"
           md5sum "$f" >> "$QDIR/empreintes-md5.txt"
           mv -v "$f" "$QDIR/"
       fi
   done
   ```

---

### Étape 4 : Déploiement du cœur propre SPIP

1. **Extraction de l'archive officielle** :
   ```bash
   ARCHIVE="/root/incident-spip-20261023/spip_archives/spip-v4.4.28.zip"
   TMP_EXTRACT="/tmp/spip-update-dist"
   rm -rf "$TMP_EXTRACT" && mkdir -p "$TMP_EXTRACT"
   unzip -q "$ARCHIVE" -d "$TMP_EXTRACT"
   ```
2. **Synchronisation rsync (Préservation des données)** :
   Ne JAMAIS écraser `IMG/`, `squelettes/`, `config/connect.php` ou `plugins/auto`.
   ```bash
   SRC="$TMP_EXTRACT/spip"  # ou racine selon structure du zip
   DEST="/var/www/alternc/<initiale>/<compte>/www/<site>"

   rsync -av "$SRC/ecrire/" "$DEST/ecrire/"
   rsync -av "$SRC/prive/" "$DEST/prive/"
   rsync -av --delete "$SRC/plugins-dist/" "$DEST/plugins-dist/"
   rsync -av --delete "$SRC/squelettes-dist/" "$DEST/squelettes-dist/"
   if [ -d "$SRC/vendor" ]; then
       rsync -av --delete "$SRC/vendor/" "$DEST/vendor/"
   fi
   cp -f "$SRC/config/ecran_securite.php" "$DEST/config/ecran_securite.php"
   cp -f "$SRC"/spip.php "$SRC"/index.php "$SRC"/.htaccess "$DEST/"
   ```
3. **Rétablissement des permissions AlternC** :
   ```bash
   /usr/lib/alternc/fixperms.sh -d "$DEST"
   ```

---

### Étape 5 : Mise à niveau de la BDD et Sécurisation

1. **Migration du schéma SPIP via spip-cli** :
   ```bash
   cd "$DEST"
   /usr/bin/php7.4 /opt/spip-cli/bin/spip core:maj:bdd
   ```
2. **Rotation des aléas de sécurité (invalidation des sessions antérieures)** :
   ```bash
   ALEA1=$(openssl rand -hex 16)
   ALEA2=$(openssl rand -hex 16)
   mysql -e "UPDATE spip_meta SET valeur='$ALEA1' WHERE nom='alea_ephemere';" <base_spip>
   mysql -e "UPDATE spip_meta SET valeur='$ALEA2' WHERE nom='alea_ephemere_ancien';" <base_spip>
   ```
3. **Purge des sessions et caches** :
   ```bash
   rm -f "$DEST"/tmp/meta_cache.php
   rm -rf "$DEST"/tmp/sessions/*
   rm -rf "$DEST"/tmp/cache/*
   ```

---

### Étape 6 : Tests de Recette & Vérification

1. **Vérification HTTP Frontal** :
   ```bash
   curl -sI -k https://<domaine> | grep -iE "(HTTP/|composed-by)"
   ```
   Attendu : `HTTP/2 200` et `Composed-By: SPIP 4.4.28`.
2. **Vérification Espace Privé** :
   ```bash
   curl -sI -k https://<domaine>/ecrire/ | grep -iE "(HTTP/|location|composed-by)"
   ```
   Attendu : `HTTP/2 302` vers `spip.php?page=login&url=%2Fecrire%2F`.

---

### Étape 7 : Documentation & Clôture de Ticket (Forgejo)

Si l'intervention est liée à une issue Forgejo :
1. Ajouter un commentaire récapitulant :
   - Les sauvegardes effectuées (noms des archives et tailles).
   - Les éventuels artefacts malveillants déplacés en quarantaine (noms, empreintes SHA256).
   - La version cible installée et la version PHP utilisée.
   - Les statuts de validation HTTP.
2. Clôturer le ticket (`set_issue_state(state="closed")`).
3. Nettoyer les répertoires temporaires créés dans `/tmp`.
