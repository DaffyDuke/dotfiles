# Agent: L'Autre Net - Architecture Logicielle

## Aperçu

Cet agent est spécialisé dans la documentation et le support de l'architecture logicielle de l'association L'Autre Net. Il fournit des informations détaillées sur :
- L'hébergement AlternC principal (serveur backend)
- Les serveurs de messagerie (IMAP/POP3/SMTP)
- Le webmail Roundcube
- Les systèmes de sauvegarde et de monitoring
- Les configurations réseau et les infrastructures

## Infrastructure Principale

### Serveur d'Hébergement AlternC (Backend)

**Rôle** : Serveur principal d'hébergement web et services alternatifs
**Fonctionnalités** :
- Gestion des comptes utilisateurs via AlternC
- Exécution des crons système et scripts d'administration
- Hébergement des applications web (PHP-FPM pools)
- Sauvegardes automatiques des bases de données MySQL
- Génération des configurations de pools PHP-FPM

**Scripts clés** :
- `/usr/lib/alternc/php7-fpm` (script unique, gère les pools `php56-fpm` à `php85-fpm`) : Génération et synchronisation des pools PHP-FPM via NFS vers les serveurs web frontaux
- `/usr/lib/alternc/sqlbackup.sh` : Sauvegarde automatique des bases de données MySQL (quotidienne et hebdomadaire)
- `/usr/lib/alternc/fixperms.sh` : Correction automatique des permissions des dossiers utilisateurs
- `/usr/lib/alternc/update_mailman.sh` : Gestion des listes Mailman

**Variables système critiques** (configurables via l'interface AlternC) :
- `hosting_tld` : Le TLD d'hébergement (ex: `lautre.net`)
- `mail_human_imaps` : Serveur IMAPS (ex: `imaps.lautre.net`)
- `mail_human_imap` : Serveur IMAP (ex: `imap.lautre.net`)
- `mail_human_pop3` : Serveur POP3 (ex: `pop.lautre.net`)
- `mail_human_pop3s` : Serveur POP3S (ex: `pops.lautre.net`)
- `mail_human_smtp` : Serveur SMTP (ex: `smtp.lautre.net`)
- `mail_human_smtps` : Serveur SMTPS (ex: `smtps.lautre.net`)
- `mailname_bounce` : Serveur de rebond (ex: `listes.lautre.net`)
- `mail_human_submission` : Serveur de submission (ex: `submission.lautre.net`)

**Configuration par défaut** :
- Type de PHP par défaut : `php85-fpm` — migration PHP 8.5 du 2026-10-21 (auparavant `php82-fpm`, qui remplaçait lui-même l'ancien `VHOST`/`mod_php`). Appliqué aux nouveaux domaines via la table `default_subdomains` (entrée `www`/`MAIN`)
- Types PHP restreints (table `domaines_type`, colonne `enable`) : `php81-fpm` et `php82-fpm` sont en `ADMIN` (réservés au staff), `php85-fpm` et `php74-fpm` en `ALL`. Un type dont `enable != 'ALL'` n'est ni proposé aux comptes non-admin (`admin/dom_edit.inc.php`) ni éditable par eux (`admin/dom_subedit.php`, message « This page is restricted to authorized staff »)
- ⚠️ Depuis le 2026-10-22, les types `php70-fpm`, `php72-fpm`, `php73-fpm`, `php81-fpm` et `php82-fpm` **ne correspondent plus à aucun paquet installé** sur les frontaux : ils ont été passés en `enable='NONE'` pour empêcher toute sélection (staff inclus) d'un type cassé (cf. « Nettoyage des versions PHP obsolètes »)
- Création automatique des répertoires racine des sites et dossiers temporaires
- Gestion du TLD via variable système pour éviter les collisions de fichiers

### Serveurs de Messagerie (IMAP/POP3/SMTP)

**Architecture** :
- Serveurs IMAP/POP3 : Deux serveurs en haute disponibilité (HA)
- Serveurs SMTP : Configuration via variables système
- Stockage des boîtes mail : NFS partagé entre les serveurs IMAP

**Fonctionnalités** :
- Gestion des comptes IMAP/POP3 via Dovecot
- Stockage des courriels sur NFS
- Support des protocoles IMAP, POP3, SMTP, SMTPS
- Configuration centralisée via variables AlternC

**Points importants** :
- Les contacts Roundcube ne sont **PAS** stockés dans Dovecot, mais dans une base de données MySQL séparée
- Le changement de hostname dans Roundcube nécessite une migration en base de données (colonne `mail_host` dans la table `users`)
- Roundcube et Dovecot sont découplés : Roundcube gère les contacts/préférences, Dovecot gère uniquement les boîtes mail

### Serveur Webmail (Roundcube)

**Architecture** :
- Code source partagé via NFS entre les serveurs webmail
- Base de données MySQL commune pour les comptes utilisateurs et contacts
- Configuration centralisée

**Fonctionnalités** :
- Webmail avec interface Roundcube
- Gestion des contacts et signatures
- Support IMAP/POP3/SMTP
- Interface d'administration

**Points critiques** :
- Le profil utilisateur est identifié par le couple `(username, mail_host)`
- Un changement de `$config['imap_host']` crée un nouveau profil vide en base si les comptes existants ne sont pas migrés
- Les contacts sont stockés dans la table `contacts` liée à la table `users`

### Serveurs Web Frontaux (Nginx + PHP-FPM)

**Rôle** : Front de bout pour les sites web
**Fonctionnalités** :
- Serveur web Nginx
- Pools PHP-FPM gérés par le script AlternC
- NFS pour le partage du code source

**Gestion des pools PHP-FPM** :
- Le script AlternC `/usr/lib/alternc/php7-fpm` (cron `alternc-php-fpm`, toutes les 5 min sur `elisa`) génère les fichiers `/etc/php/*/fpm/pool.d/<user>.alternc.conf` depuis `sub_domaines.type`, puis synchronise via `rsync /etc/php /etc/alternc/sharedconf/ -a --delete` (montage NFS `10.0.0.30:/var/alternc/sharedconf/override_php`)
- Les frontaux récupèrent les pools via `/usr/local/sbin/reload-fpm.sh` (cron `alternc-lautrenet`, toutes les 15 min) : `rsync /etc/alternc/sharedconf/php/ /etc/php/ -a --delete`, puis `restart` des services `phpX.Y-fpm` disposant de pools
- Les vhosts Apache sont régénérés sur le backend par `/usr/lib/alternc/update_domains.sh` (cron `alternc`, toutes les 5 min, pour `web_action != 'OK'`) puis propagés aux frontaux par `/usr/local/sbin/reload-apache.sh` (cron `alternc-lautrenet`, toutes les minutes) qui copie `/etc/alternc/sharedconf/vhosts_all.conf` vers `/var/lib/alternc/apache-vhost/vhosts_all.conf`
- Un fichier vhost individuel est stocké dans `/var/lib/alternc/apache-vhost/<dernier chiffre de l'UID>/<UID>/<fqdn>.conf` (`host_conffile` dans `functions_hosting.sh`)
- **Versions PHP actives** : `5.6` (mod_php — sert les types `vhost`, **1 484 sous-domaines**, et `php53`, 7), `7.4` (`php74-fpm`), `8.5` (`php85-fpm`, **257 sous-domaines / 96 comptes**). Les versions 7.0/7.1/7.2/7.3/8.1/8.2 ont été retirées des frontaux (voir « Nettoyage des versions PHP obsolètes »). `7.4` reste utilisé par **373 sous-domaines / 140 comptes** : migration vers 8.5 planifiée (voir « Migration des domaines restant en PHP 7.4 »)

### Nettoyage des versions PHP obsolètes (2026-10-22)

Après la migration PHP 8.5, les paquets des versions obsolètes ont été désinstallés **sur les frontaux uniquement** (`emma`, `web2`) : versions 7.0, 7.1, 7.2, 7.3, 8.1 et 8.2, soit **148 paquets par hôte** (purge complète de `phpX.Y-*` + métapaquet `php8.2`). Aucun paquet non-PHP n'a été supprimé et aucune réinstallation n'a été induite (le métapaquet `php8.2` a été retiré pour éviter l'installation automatique de `libapache2-mod-php8.2`).

**Sur `elisa` : aucun paquet retiré.** `alternc-php-fpm` (3.3.1, seule version disponible) dépend de `php7.0-fpm`, `php7.1-fpm`, `php7.2-fpm` et `php7.3-fpm` : les retirer supprimerait le script `/usr/lib/alternc/php7-fpm` et le cron `alternc-php-fpm` (donc la génération des pools). `php8.1-fpm`/`php8.2-fpm` n'y sont pas installés.

**Pools manuels** : `/etc/php/7.1/fpm/pool.d/www.manual.conf` et `/etc/php/8.1/fpm/pool.d/www.manual.conf` (pools de statut `pm.status_path`) ont été retirés de la source (`elisa`) et de `/etc/alternc/sharedconf/` afin que les frontaux ne les recréent pas (sinon `reload-fpm.sh` tentait un `restart` de services inexistants toutes les 15 min).

**Migration d'un compte vers une autre version** : modifier `sub_domaines.type` puis passer `web_action='UPDATE'`, exécuter `/usr/lib/alternc/update_domains.sh` (vhosts) et `/usr/lib/alternc/php7-fpm` (pools), puis propager aux frontaux (`reload-fpm.sh`, `reload-apache.sh`). Les pools étant nommés par utilisateur (`phpX.Y-<login>.sock`), le pool de l'ancienne version est supprimé et recréé dans la nouvelle version.

**Points d'attention** :
- Les types `php70-fpm`, `php72-fpm`, `php73-fpm`, `php81-fpm` et `php82-fpm` ont été passés en `enable='NONE'` dans `domaines_type` (sauvegarde `/root/domaines_type-avant-NONE-*.sql` sur `elisa`) ; `php74-fpm` et `php85-fpm` restent en `ALL`, `php56-fpm` en `NONE`.
- Les scripts gérés par Ansible `/usr/local/sbin/reload-fpm.sh` et `check_php_fpm` listent encore les versions 7.0/7.2/7.3/8.1/8.2 : inoffensif (répertoires `pool.d` vides → versions ignorées).
- `check_php_fpm` renvoie `rc=1` de façon **bénigne** lorsqu'aucun pool n'est en échec (c'est le `rm` d'un fichier de cache absent) ; un pool réellement DOWN est tracé via `logger -t check_php_fpm` et un échec répété déclenche un `restart` de la version.
- `update_domains.sh` régénère `vhosts_all.conf` en concaténant les fichiers individuels : un sous-domaine supprimé via le panel (`dom - del_sub_domain`) disparaît du vhost et retombe sur le vhost par défaut (301 vers `www.lautre.net`). Vérifier `/var/log/alternc/bureau.log` (actions `dom - del_sub_domain`) avant de conclure à une régression.

### Mise à jour de sécurité des paquets PHP 5.6 (2026-10-22)

Mise à jour des paquets **PHP 5.6** sur les **deux frontaux uniquement** (`emma`, `web2`) — `elisa` n'a **rien** reçu (Debian 8 jessie : dépôt Sury **commenté**, `archive.debian.org` aux clés GPG expirées → **0 paquet upgradable** ; PHP y est figé à `5.6.40-27` / `7.4.5`, avril 2020). Suivi Forgejo : **#175** (commentaire 2137, faille et preuves) et **#180** (commentaire 2135, chiffres + paquets).

- **23 paquets par hôte** : `php5.6-*` (22) + `libapache2-mod-php5.6`, de `5.6.40-104+0~20261021.134+debian12~1.gbp7401dd` → **`5.6.40-105+0~20261022.135+debian12~1.gbp37a17e`**. Sur `web2` uniquement, `libgd3` a aussi été mis à jour (`2.3.3-9+0~20230207.13+debian10` → `2.3.3-14+0~20260731.21+debian12`).
- **Méthode** : liste explicite de paquets + `apt-get install --only-upgrade` avec `-o Dpkg::Options::="--force-confold"` → **0 suppression** (`Remv = 0`), **aucun paquet `alternc*`** concerné (il n'y en a aucun sur `emma`/`web2`). `php7.4` (`1:7.4.33-31`) et `php8.5` (`8.5.12`) étaient **déjà à jour**.
- **Correctif apporté** : changelog Debian du paquet — `Backported from 8.0.28` + `[CVE-2023-0662]: DOS vulnerability when parsing multipart request body`. C'est le hunk `max_multipart_body_parts` qui **manquait** sur la branche 5.6 (cf. `oerdnj/deb.sury.org#146`).
- **Preuve avant/après** (modules extraits des `.deb` conservés dans `/var/cache/apt/archives/` sur les deux frontaux) : `libphp5.6.so` en `5.6.40-104` → **0 occurrence** de `max_multipart_body_parts` ; en `5.6.40-105` → **2 occurrences** + la chaîne de garde `Multipart body parts limit exceeded %d. To increase the limit change max_multipart_body_parts in php.ini.` (md5 différents, 11 chaînes en plus, taille identique).
- **Correctif réellement actif** : le module chargé en mémoire par Apache (`/proc/<pid>/maps`) est celui présent sur disque (inode identique, aucun `(deleted)`) sur les deux frontaux — `apache2ctl graceful` ré-exécute le parent Apache et recharge donc le DSO. `ini_get('max_multipart_body_parts') = '-1'` → repli sur `max_input_vars` (`1000`).
- **Périmètre** : `5.6` sert les types `vhost` (1 484 sous-domaines) et `php53` (7), soit ~1 490 sous-domaines en `mod_php`.
- **Snapshots / rollback** : `/root/php-maj/{emma,web2}-avant-<horodatage>.txt` ; retour possible via `5.6.40-104+0~20261021.134+debian12~1.gbp7401dd` (conservé dans le cache APT des deux hôtes) puis `apache2ctl graceful`.
- **Points d'attention** : `unattended-upgrades` est actif sur les frontaux mais limité aux origines **Debian** → les paquets Sury (dont `php*`) ne sont **jamais** mis à jour automatiquement ; `elisa` reste non patchable **par les paquets** (contourné depuis le 2026-10-23 par un module recompilé localement — voir « Module Apache PHP 5.6 durci sur `elisa` ») ; PHP 5.6 est **EOL** (backports Sury « au mieux »).
- **Incident mineur d'exécution** : sur `web2`, la transaction a été longue (`ucf` réécrit un `ini` par paquet, ~5 s/paquet) et la session SSH a expiré pendant le `dpkg --configure --pending` ; la transaction a poursuivi jusqu'au bout (~175 s de plus), **sans impact** (tous les paquets en `ii`).

### Module Apache PHP 5.6 durci sur `elisa` (CVE-2023-0662, 2026-10-23)

`elisa` (Debian 8 jessie) ne peut pas recevoir les paquets Sury `5.6.40-105` qui corrigent CVE-2023-0662 : dépôt Sury commenté, `archive.debian.org` aux clés GPG expirées, et le pool Sury ne conserve **aucun** artefact `debian8`. Le SAPI Apache y a donc été **recompilé localement** depuis la source Debian jessie (`5.6.40+dfsg-0+deb8u12`) avec le backport du correctif. Suivi Forgejo : **#182** (commentaires 2142, 2146, 2147).

**Principe — module parallèle, sans remplacement** : le `.so` fourni par `libapache2-mod-php5.6` (Sury) n'est **pas** écrasé. Le module durci est installé sous un nom distinct et activé par `a2enmod`, ce qui rend le retour arrière réversible en une commande. **Aucun paquet n'est supprimé ni remplacé.**

**Paquet** : `libapache2-mod-php5.6-lautre`, version `5.6.40+dfsg-0+deb8u12+lautre1` (amd64, ~2,2 Mo, md5 `6cf86628e8a5706c7855329752e2df8e`), conservé dans `~/php5-cve-2023-0662/artifacts/` sur le poste de build. Contenu :

- `/usr/lib/apache2/modules/libphp5.6-lautre.so` — strippé (9 926 664 octets), exporte `php5_module`, même `ZEND_MODULE_API_NO` (`20131226`) que Sury, donc les extensions Sury restent chargeables ;
- `/etc/apache2/mods-available/php5.6-lautre.load` — `# Conflicts: php5 php5.6` (**séparateur espace**, pas virgule) + `# Depends: mpm_prefork` ;
- `/etc/apache2/mods-available/php5.6-lautre.conf` — `SetHandler application/x-httpd-php` (réplique du `.conf` Sury, refus des `.phps` inclus) ;
- `postinst` : `a2dismod php5.6` puis `a2enmod php5.6-lautre`, puis `apache2ctl -t` ; en cas d'échec **rollback automatique** (`a2dismod php5.6-lautre` + `a2enmod php5.6`) et sortie en erreur. **Aucun rechargement automatique** d'Apache ;
- `prerm` : `a2dismod php5.6-lautre` puis `a2enmod php5.6`.

**Paramètres de compilation alignés sur Sury** (seul le bloc `configure-apache2-stamp` de `debian/rules` diffère, les autres SAPIs ne sont pas reconstruits) :

- `--with-config-file-path=/etc/php/5.6/apache2`
- `--with-config-file-scan-dir=/etc/php/5.6/apache2/conf.d`
- `EXTENSION_DIR=/usr/lib/php/20131226`

`extension_dir` **doit** être aligné : les `.ini` de `conf.d` référencent les extensions en chemin **relatif** (`extension=mysql.so`) et `/etc/php/5.6/apache2/php.ini` ne définit pas `extension_dir`. Sans cet alignement, le module ne charge **aucune** extension.

**Piège de recompilation** : `dpkg-source --after-build` (appelé en fin de `dpkg-buildpackage`) **retire les patches** de l'arbre source. Toute recompilation ultérieure repart donc d'un source **non patché**. Toujours exécuter `dpkg-source --before-build .` avant de relancer le build, puis contrôler le correctif : `strings <module> | grep -c max_multipart_body_parts` doit renvoyer **2**, plus le message de garde `Multipart body parts limit exceeded`.

**Mise en service (testée le 2026-10-23)** :

```bash
dpkg -i libapache2-mod-php5.6-lautre_5.6.40+dfsg-0+deb8u12+lautre1_amd64.deb
apache2ctl -t
service apache2 reload        # rechargement gracieux, sans coupure
```

État constaté : modules actifs `php5.6-lautre.load` + `php5.6-lautre.conf` (`php5.6` désactivé), `Syntax OK`, panneau HTTP 200 en 10–112 ms, HTML servi, `X-Powered-By` absent. Le module lit bien `/etc/php/5.6/apache2/php.ini` (`extension_dir=/usr/lib/php/20131226`), **65 extensions** actives (`mysql`, `mysqli`, `gd`, `imap`, `curl`, `mbstring`, `xml`, `zip`, `pdo_mysql`, `json`), `Zend OPcache` **actif**. Garde-fou vérifié avec `php_value max_multipart_body_parts 10` : 3 parties → 3 champs ; **25 parties → 10 champs** + `PHP Warning: Multipart body parts limit exceeded 10`.

**Retour arrière** :

```bash
a2dismod php5.6-lautre
a2enmod php5.6
apache2ctl -t && service apache2 reload
dpkg -r libapache2-mod-php5.6-lautre   # facultatif
```

⚠️ **Ne jamais utiliser `a2enmod php5`** pour revenir en arrière : cela active le module **Debian** (`libphp5.so`, chemins `/etc/php5/apache2`), pas le module Sury.

**Pièges rencontrés** :

- `apache2 -t` échoue sur `elisa` (`Invalid Mutex directory ... ${APACHE_LOCK_DIR}`) : utiliser **`apache2ctl -t`**, qui charge `/etc/apache2/envvars`.
- `a2enmod` Debian **ne désactive pas** les modules en conflit : il exige une désactivation préalable (`a2dismod php5.6` avant `a2enmod php5.6-lautre`).
- Un paquet fournissant le `.load` **sans** le `.conf` fait servir le PHP **en clair** (aucun `SetHandler`) : vérifier systématiquement que le panneau renvoie du HTML et non du code source.
- `extension_loaded('opcache')` renvoie `false` : OPcache est une **Zend extension**, à tester via `get_loaded_extensions(true)` ou `opcache_get_status()`.
- Avertissements cosmétiques au démarrage : `xmlreader`, `xmlwriter` et `zip` sont compilées **en statique** dans la source Debian (Sury les fournit en partagé) → `Module '...' already loaded` ; la version statique (même `5.6.40`) est conservée, sans impact fonctionnel. Les supprimer exigerait de recompiler ces trois extensions en `shared`.

**Périmètre** : ce correctif ne traite **que** CVE-2023-0662 ; PHP 5.6 reste **EOL** (dernière version 5.6.40, décembre 2018) et Sury backporte « au mieux ». Ne concerne que le panneau AlternC d'`elisa` — les frontaux `emma`/`web2` ont reçu les paquets Sury `5.6.40-105` (voir la section précédente).

### Migration des domaines restant en PHP 7.4 (planifiée — état 2026-10-22)

La migration PHP 8.5 n'a pas couvert les domaines encore en 7.4 : **373 sous-domaines** sur **140 comptes** (204 domaines distincts) restent en `php74-fpm` — 29 de ces comptes ont aussi des sites en `php85-fpm`, 111 sont exclusivement en 7.4. *Chiffres relevés le 2026-10-22 après la mise à jour des paquets ; ils décroissent au fil des migrations faites par les membres depuis le panel (395 sous-domaines / 145 comptes le matin même).* Suivi Forgejo : **#180** (ticket dédié, liste des comptes telle qu'établie à sa création), #175 (rapport d'analyse + plan détaillé), #178 (correctifs post-migration), #149 (inventaire CMS/SPIP).

**État de la CVE-2026-109618/109619 en PHP 7.4 : corrigée.** Les paquets `php7.4-*` sont en `1:7.4.33-31+0~20261021.121+debian12~1.gbpe9c428` sur `emma` **et** `web2`, le binaire réellement en service est `PHP 7.4.33 (built: Oct 21 2026)` et le changelog Debian mentionne `Backported from 8.2.35` + `[CVE-2026-109618, CVE-2026-109619]: Avoid state corruption via bailout`. **Points d'attention** : il s'agit d'une **mitigation minimale** propre aux branches EOL (elle **désactive complètement `session.upload_progress`**) ; elle introduit `memory_hard_limit_percent` (un worker peut sortir en **code 137**) ; Sury backporte « au mieux », sans garantie pour la prochaine faille ; `php5.6` (encore installé en `mod_php` sur les frontaux) a **reçu** le hunk `max_multipart_body_parts` le **2026-10-22** (paquets `5.6.40-105` — voir « Mise à jour de sécurité des paquets PHP 5.6 »).

**Recensement des applications** (racines en 7.4) : SPIP 4.4.x (34, compatible 8.5 via `_PHP_MAX 8.5.99`), SPIP 4.0–4.3 (8), **SPIP 3.x (5, incompatibles)**, WordPress 6.x/7.x (45), WordPress 5.6–5.9 (7, non testés en 8.5), **WordPress < 5.6 (6, incompatibles)**, **ownCloud 10.x / Nextcloud 16 et 25 (5, incompatibles — NC 25 = max PHP 8.1)**, **MediaWiki 1.28.3 (1)**, **Galette 0.8.3.3 / 0.9.4.2 (5)**, DokuWiki (2 récents compatibles, **5 anciens incompatibles**), LimeSurvey (6.16.9 compatible, **3.13.2 non**), Dotclear (2.23.1 compatible, **2.18 ×2 non**), Piwigo 11.3.0 (1, PHP 8.0 seulement), YOURLS 1.9.2 (1) et **~171 racines sans CMS identifiable** (statique, redirections, PHP maison) à tester au cas par cas. Le patch du plugin SPIP `majplugins` déjà appliqué (voir #178) confirme que **les plugins SPIP nécessitent une mise à jour** pour PHP 8.

**Plan de migration** (détail dans #180) : par lots de ~20 comptes — A sauvegardes, B pilote sur un compte déjà mixte, C bascule des CMS compatibles, D mise à jour des applications incompatibles, E test au cas par cas des racines inconnues, F décommissionnement de 7.4 (quand plus aucun `sub_domaines.type='php74-fpm'`). `php74-fpm` reste en `enable='ALL'` : un membre peut rebasculer lui-même un site en 7.4 depuis le panel en cas de régression. Aucun palier intermédiaire (8.0/8.1/8.2) n'est disponible, ces versions ayant été désinstallées.

**Point de sécurité annexe** : la racine du compte `ffii` contient de nombreux fichiers PHP à nom aléatoire (`nKtcGHtJ.php`, `orang.php`, `nox-universal_v3.php`, `poc-admin.php`, …) — traces d'exploits (famille Nox) à auditer/nettoyer avant bascule de ce compte.

### Système de Sauvegarde

**Scripts de sauvegarde** :
- `/usr/lib/alternc/sqlbackup.sh` : Sauvegarde MySQL (quotidienne/hebdomadaire)
- `/usr/bin/rsync` : Sauvegarde des dossiers via SSH
- `/usr/lib/alternc/update_mailman.sh` : Sauvegarde des archives Mailman

**Configuration** :
- Modes daily et weekly
- Gestion des permissions ACL automatique
- Protection contre les échecs en cascade (un dossier orphelin ne bloque pas les autres sauvegardes)

### Système de Monitoring (Nagios)

**Scripts** :
- `/usr/bin/nacup` : Plugin de monitoring Nagios
- `/usr/bin/nacup-cron` : Vérification des mises à jour disponibles

**Fonctionnalités** :
- Surveillance des services et packages
- Détection des mises à jour critiques
- Gestion des proxies et connexions HTTP

### Système de Gestion des Comptes

**Processus de suppression** :
- Script principal : `/var/www/alternc/r/root/lautrenet/compta/cron/delete-alternc-account.php`
- Cron système : `/etc/cron.d/alternc-lautrenet` (exécution quotidienne à 04h00)
- Script intermédiaire : `cron.daily.deleteaccount.php`

**États des comptes** :
- Statut 12 : Compte prêt pour suppression
- Statut 13 : Compte supprimé

**Nettoyage complet** :
1. Archivage complet (tar, dumps, configs)
2. Suppression des listes Mailman (détectées et confirmées)
3. Suppression des bases MySQL (avec protection des bases contenant "test")
4. Nettoyage AlternC standard (domaines, vhosts, FTP, quotas)

### Système de Détection des Ressources Orphelines

**Script** : `/root/list_orphans.sh`

**Fonctionnalités** :
- Détection des listes Mailman dont le propriétaire n'existe plus
- Détection des bases MySQL orphelines
- Détection des utilisateurs MySQL orphelines
- Génération de rapports détaillés

**Commandes** :
- `/root/list_orphans.sh` : Générer le rapport
- `/root/clean_orphans.sh --dry-run` : Simulation du nettoyage
- `/root/clean_orphans.sh --execute` : Nettoyage interactif
- `/root/clean_orphans.sh --force` : Nettoyage non-interactif

### Système de Gestion des Variables AlternC

**Problèmes connus et solutions** :
- **Problème** : Les variables étaient écrasées par les valeurs par défaut lors de chaque chargement de page
- **Cause** : `variable_get()` appelait `variable_set()` avec des valeurs par défaut si la variable n'était pas en cache mémoire
- **Solution** : Séparation de `variable_default_register()` (insert uniquement) et `variable_get()` (lecture sécurisée)
- **Résultat** : Les variables personnalisées sont maintenant préservées même si le cache mémoire est vide

### Interface de Gestion Git (Forgejo)

**Utilisation** :
- Gestion des issues et suivi des corrections
- Versioning du code AlternC personnalisé
- Suivi des modifications par dépôt

**Accès** : Via l'interface web de gestion Git

## Fichiers de Configuration Clés

### `/usr/share/alternc/panel/class/variables.php`
Gestion des variables système AlternC

### `/usr/share/alternc/panel/class/m_admin.php`
Gestion des administrateurs et comptes

### `/usr/share/alternc/panel/class/m_dom.php`
Gestion des domaines et sous-domaines

### `/usr/share/alternc/panel/class/m_mail.php`
Gestion de la messagerie (postmaster, MX, SPF, DMARC)

### `/var/alternc/html/r/rc/rc.lautre.net/config/config.inc.php`
Configuration Roundcube

### `/etc/cron.d/alternc-lautrenet`
Cron système pour les tâches de maintenance

### `/etc/cron.d/backup-mail`
Cron pour les sauvegardes de messagerie

### `/etc/cron.d/nacup`
Cron pour le monitoring Nagios

## Bonnes Pratiques

### Gestion des Permissions
- Les dossiers utilisateurs doivent avoir le masque ACL `rwx` (`mask::rwx`)
- Le script `fixperms.sh` corrige automatiquement les permissions incorrectes
- Vérifier les permissions avant les opérations de sauvegarde

### Configuration des Variables
- Utiliser des variables système pour les hostnames plutôt que des valeurs en dur
- Configurer `hosting_tld` pour éviter les collisions de fichiers
- Sauvegarder les variables personnalisées avant toute mise à jour du code

### Migration de Hostname
- Toujours migrer les comptes en base avant de changer `$config['imap_host']` en Roundcube
- Utiliser une sauvegarde MySQL avant toute migration
- Mettre à jour la colonne `mail_host` dans la table `users`

### Nettoyage de Comptes
- Toujours vérifier les ressources orphelines avant suppression
- Utiliser le mode `--dry-run` pour tester le script de nettoyage
- Protéger les bases de test et les données sensibles
- Documenter avant toute suppression massive

## Sécurité

### Clés SSH
- Utiliser des clés dédiées pour les sauvegardes (`backup_dsa`)
- Ne jamais exposer les clés dans les scripts
- Utiliser l'authentification par clé plutôt que par mot de passe

### Permissions
- Les scripts d'administration doivent respecter le principe du moindre privilège
- Utiliser les comptes système appropriés (alterncpanel, root selon le besoin)
- Vérifier les permissions des dossiers sensibles

### Sauvegardes
- Sauvegarder avant toute modification
- Tester régulièrement les restaurations
- Stocker les sauvegardes hors du système principal

## Commandes Utiles

### Vérification des variables AlternC
```bash
mysql -h sql.lautre.net -u alternc -p -e "SELECT * FROM variable WHERE name IN ('mail_human_imaps', 'hosting_tld')"
```

### Vérification des comptes Roundcube
```bash
mysql -h sql.lautre.net -u rc_roundcubemail -p -e "SELECT username, mail_host FROM users WHERE mail_host = 'imaps.lautre.net'"
```

### Liste des ressources orphelines
```bash
/root/list_orphans.sh
```

### Simulation du nettoyage
```bash
/root/clean_orphans.sh --dry-run
```

### Exécution d'un script de sauvegarde
```bash
su - alterncpanel -c '/usr/lib/alternc/sqlbackup.sh -t daily'
```

### Test de connexion SSH avec clé
```bash
ssh -i /root/.ssh/backup_dsa root@10.0.0.86
```

### Vérification des types de domaines
```bash
mysql -h sql.lautre.net -u alternc -p -e "SELECT * FROM default_subdomains"
```

## Résolution de Problèmes Courants

### Spam de mails de cron
- Vérifier les logs dans `/var/log/alternc/bureau.log`
- Rediriger les sorties vers syslog : `2>&1 | logger -t alternc-php-fpm`
- Renommer les fichiers de configuration en collision dans le HOME

### Erreurs PHP-FPM
- Vérifier que le script AlternC génère bien les pools
- S'assurer que les permissions NFS sont correctes
- Vérifier que le service PHP-FPM est bien démarré

### Contacts Roundcube perdus
- Vérifier la colonne `mail_host` dans la table `users`
- Migrer les comptes en base avant de changer la configuration
- Utiliser un hostname stable (`imaps.lautre.net` plutôt qu'une IP)

### Variables écrasées
- Vérifier que `hosting_tld` est configuré
- Utiliser `variable_default_register()` pour les valeurs par défaut
- Éviter d'appeler `variable_set()` avec des valeurs par défaut

### Permissions de sauvegarde
- Vérifier le masque ACL des dossiers utilisateurs
- Exécuter `fixperms.sh` si nécessaire
- Créer les dossiers de sauvegarde avec les droits appropriés

## Ressources Additionnelles

### Logs systématiques
- `/var/log/alternc/bureau.log` : Logs d'administration AlternC
- `/var/log/auth.log` : Logs d'authentification SSH
- `/var/log/apache2/` : Logs Apache (si présent)
- `/var/log/nginx/` : Logs Nginx

### Fichiers de configuration
- `/etc/cron.d/` : Cron jobs système
- `/etc/php/*/fpm/pool.d/` : Configurations PHP-FPM
- `/var/alternc/html/` : Code source webmail et applications
- `/etc/alternc/sharedconf/` : Configurations partagées

## Notes Importantes

1. **PHP Versions** : Le code AlternC peut être compatible PHP 5.3/5.6/7.x, mais l'environnement CLI peut être sur une version différente
2. **Base de données** : Le serveur MySQL principal est distant (`sql.lautre.net`), les connexions peuvent être affectées par des problèmes réseau
3. **NFS** : De nombreuses configurations sont synchronisées via NFS, les problèmes de réseau NFS peuvent impacter les services
4. **HA** : Certains services sont en haute disponibilité, les changements doivent être coordonnés entre les nœuds
5. **Variables système** : Certaines valeurs sont stockées dans la base de données et peuvent être réinitialisées par le code par défaut