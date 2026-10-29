# Agent: L'Autre Net - Architecture Logicielle

## Aperçu

Cet agent est spécialisé dans la documentation et le support de l'architecture logicielle de l'association L'Autre Net. Il fournit des informations détaillées sur :
- L'hébergement AlternC principal (serveur backend)
- Les serveurs de messagerie (IMAP/POP3/SMTP) et l'authentification du courrier (DKIM, SPF, DMARC)
- Le webmail Roundcube
- Les systèmes de sauvegarde et de supervision (Nagios 4, Uptime Kuma, page de statut publique)
- Les configurations réseau et les infrastructures

## Règles de Communication et Style

- **Tutoiement systématique** : Utiliser impérativement le tutoiement dans tous les échanges avec l'utilisateur et lors des réponses/commentaires sur les tickets de support (Forgejo).
- **Concision par défaut** : Privilégier des réponses courtes, directes et synthétiques. Aller droit aux faits (commandes, diagnostic, actions réalisées), sans verbiage superflu.

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

### Fermeture et désactivation d'un site (file AlternC)

**Table concernée** : `sub_domaines` (`id`, `compte`, `domaine`, `sub`, `valeur`, `type`, `web_action`, `web_result`, `enable`).
Le champ `enable` est un `enum('ENABLED','ENABLE','DISABLED','DISABLE')` mais **il n'est pas exploité par la file de traitement** : passer une ligne en `enable='DISABLED'` (ou `DISABLE`) **ne ferme pas** le site.

**Ce que traite réellement `/usr/lib/alternc/update_domains.sh`** :
- `web_action='UPDATE'` → `host_enable`, puis passage de la ligne à `enable='ENABLED'` ;
- `web_action='DELETE'` → `host_delete`, puis **`DELETE FROM sub_domaines`** : la ligne est **supprimée** de la base.

**Fermer un site de façon réversible** (constaté le 2026-10-24 sur un site compromis exposant un listing de répertoire) :
- ne pas passer par `enable='DISABLED'` (sans effet) ni par `web_action='DELETE'` (destructif pour la ligne) ;
- poser une **protection `.htaccess`** à la racine du site :
  ```apache
  Options -Indexes
  <IfModule mod_authz_core.c>
    Require all denied
  </IfModule>
  <IfModule !mod_authz_core.c>
    Order allow,deny
    Deny from all
  </IfModule>
  ```
  Effet immédiat (Apache relit le `.htaccess` à chaque requête, sans rechargement), réversible en retirant le fichier. Sauvegarder au préalable tout `.htaccess` préexistant et consigner la mesure dans un manifeste.

**Couper l'accès d'un compte entier** (pratique employée lors du triage de l'incident du 2026-10-23) : `membres.enabled=0`, vhosts marqués `web_action='DELETE'`, file AlternC traitée, puis `ftpusers.enabled=0`. La **messagerie du compte est conservée** et les racines des sites restent en place (aucune suppression de fichiers).

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

### Listes de diffusion (Mailman)

- **Interface web** : `https://listes.lautre.net/cgi-bin/mailman/listinfo` — servie par **`elisa`** (`listes.lautre.net` partage son adresse avec `panel.lautre.net`). La racine `/` y sert l'**AlternC Desktop**, pas les listes ; `/mailman/` et `/mailman/listinfo` renvoient 404 et `/cgi-bin/mailman/` seul renvoie 403 : seuls les chemins `/cgi-bin/mailman/…` existent.
- **Gestion et sauvegarde** : `/usr/lib/alternc/update_mailman.sh` (voir « Système de Sauvegarde ») ; les listes orphelines sont détectées et nettoyées par `list_orphans.sh` / `clean_orphans.sh`.
- **Supervision** : sonde Nagios `check_mailman` (`check_http -H listes.lautre.net -S -u /cgi-bin/mailman/listinfo -t 20 -w 10 -c 20`), publiée sur la page de statut sous le nom `Mailman`. L'interface est lente au premier appel (~2 s) : conserver des seuils larges.

### Authentification du courrier : DKIM, SPF et DMARC (#168)

**Contournement Spamhaus DBL pour les domaines `*.fr.eu.org` (#179)** :
- La zone parente `fr.eu.org` (sous-domaines gratuits de l'opérateur eu.org) est listée par Spamhaus DBL (`127.0.1.6`), ce qui causait le rejet au `RCPT TO` (554 5.7.1) des courriels émis depuis des adresses sous `*.fr.eu.org` vers des serveurs filtrants.
- **Solution en place** : Réécriture d'enveloppe Postfix sur les serveurs MX (`edna` et `erza`) via `/etc/postfix/sender_canonical_freuorg` :
  ```pcre
  /^(.*)@coincoin\.fr\.eu\.org$/ ${1}@<compte>.lautre.net
  ```
  Avec `sender_canonical_classes = envelope_sender` et `sender_canonical_maps = regexp:/etc/postfix/sender_canonical_freuorg`.
- **Garanties** :
  - **Ciblé** : Restreint spécifiquement au domaine concerné (`<domaine>.fr.eu.org`) réécrit vers le sous-domaine de compte valide (`<compte>.lautre.net`) pour éviter tout effet de bord sur d'autres membres hébergés et acheminer correctement les éventuels messages de rebond (NDR/bounces).
  - L'adresse `From:` visible pour le destinataire reste **strictement inchangée** (`<compte>@<domaine>.fr.eu.org`), la signature DKIM originale est préservée, tandis que le `Return-Path` / `MAIL FROM` passe sous `@<compte>.lautre.net` (validé par SPF et non listé au DBL).
- Configuration versionnée dans le dépôt Ansible `lautre.net/ansible` (`roles/mail/files/sender_canonical_freuorg`, `templates/main.cf.j2`, `tasks/main.yml`).

**Périmètre** : les domaines hébergés, `gesdns=1 AND gesmx=1` (742 domaines). Les 11 domaines à messagerie externe (`gesmx=0`) ne sont pas touchés. Les domaines de compte `<login>.lautre.net` (359, `gesdns=0`) sont traités à part.

**DKIM** :
- Sélecteur **`alternc`** (défaut d'AlternC), clés **1024 bits** : `sub_domaines.valeur` est un `VARCHAR(255)` et une clé 2048 bits (~419 caractères) y serait tronquée, ce qui ferait échouer la vérification. Passer à 2048 exigerait d'élargir la colonne (migration de schéma AlternC).
- Domaine hébergé : TXT `alternc._domainkey.<domaine>` publié par sa zone, clé privée dans `/etc/opendkim/keys/<domaine>/alternc.private`, entrées dans `KeyTable` et `SigningTable` (`/etc/opendkim`, partagé en NFS entre le panneau et les MX).
- Domaine de compte `<login>.lautre.net` : **aucun** TXT à ce nom, signature en `d=lautre.net` / `s=alternc` (clé partagée `alternc._domainkey.lautre.net`), une ligne de `SigningTable` par compte. **Ne jamais publier de nom sous `<login>.lautre.net`** : le nom existerait et le joker `*.lautre.net` cesserait de s'appliquer (RFC 4592) — mesuré en production le 24/10/2026, les 359 comptes perdaient d'un coup A, MX, SPF et DMARC.
- OpenDKIM ne relit ses tables qu'au démarrage : le rechargement est assuré par `/etc/cron.d/opendkim` (comparaison du pid avec `TrustedHosts`), présent sur `edna`, `erza`, `mail1` et `elisa`.
- Scripts : `/usr/local/sbin/check_dkim.sh` (audit, MX) et `/usr/local/sbin/alternc-dkim-accounts.sh` (comptes, timer quotidien sur `elisa`).

**SPF / DMARC** :
- Valeurs attendues = variables de panel `default_spf_value` (`v=spf1 mx include:spf.lautre.net -all`) et `default_dmarc_value` (`v=DMARC1;p=quarantine;pct=100;rua=mailto:dmarc@lautre.net;aspf=r;adkim=r`), que les membres peuvent remplacer domaine par domaine.
- `/usr/local/sbin/alternc-spf-dmarc.sh` (sur `elisa`, ~35 s pour 742 domaines) compare les deux en base et valide chaque zone avec `named-checkzone`. Statuts : `OK`, `ABSENT`, `DOUBLON` (PermError, RFC 7208), `ANCIEN` (ancien défaut d'AlternC), `PERSO`, `MANUEL` (posé dans la zone, hors base), `VERROU` (`;; LOCKED:YES`), `EXCLU`.
- `--apply` ne répare que `ABSENT` et `DOUBLON`. Les valeurs des membres, les enregistrements manuels, les zones verrouillées et les domaines exclus ne sont **jamais** touchés ; les anciens défauts ne sont alignés que sur `--normalize-legacy`, les valeurs personnalisées que sur `--force`.
- Il n'écrit que dans `sub_domaines` et `domaines.dns_action='UPDATE'` : la publication reste le fait de `/usr/lib/alternc/update_domains.sh` (cron toutes les 5 min). Il ne faut **jamais** patcher le code d'AlternC pour cela.
- Exclusions dans `/root/spf_exclude.txt` (domaine, `*.suffixe`, login ou uid ; même fichier que la campagne SPF de #12). Le script tourne en root (`sudo`) pour lire les zones (`bind:bind 0640`) et ce fichier.
- Correction quotidienne : `alternc-spf-dmarc.timer` → `alternc-spf-dmarc.service` (`--apply`, rapport `/var/log/alternc/spf-dmarc.log`) ; le contrôle NRPE écrit `/var/log/alternc/spf-dmarc-check.log`.

**Supervision** :
- `check_dkim` sur `edna` (NRPE, horaire, 2 à 4 min) : `command_timeout=600` sur le MX, `-t 600`, `service_check_timeout=600` dans `nagios.cfg`.
- `check_spf_dmarc` sur `elisa` (NRPE, horaire, ~35 s) : `command_timeout=120`, `-t 120`. Le plugin tourne en root **via sudo** (`/etc/sudoers.d/20_check_spf_dmarc`, arguments figés sur `--check`) : sans cela, `nagios` ne voit ni les zones ni les exclusions et rend de **faux CRITICAL**.
- `CRITICAL` = SPF/DMARC attendu absent ou en doublon, ou zone qui ne se charge plus (BIND sert alors la dernière version valide gardée en mémoire) ; `WARNING` = domaine resté sur un ancien défaut (voir #12).

**État au 25/10/2026** : DKIM 742/742 conformes, plus 359 comptes signés ; SPF 737 OK / 1 personnalisé ; DMARC 734 OK / 3 personnalisés / 1 manuel ; 0 absent, 0 doublon, 0 ancien défaut, 0 zone invalide.

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

**Point de sécurité annexe** : la racine du compte `<compte>` contient de nombreux fichiers PHP à nom aléatoire (`nKtcGHtJ.php`, `orang.php`, `nox-universal_v3.php`, `poc-admin.php`, …) — traces d'exploits (famille Nox) à auditer/nettoyer avant bascule de ce compte.

**Angle mort — une application peut n'avoir aucune version PHP disponible.** Après le retrait des 8.0/8.1/8.2 (2026-10-22), le parc ne propose plus que **7.4** et **8.5** : une application exigeant **8.1 à 8.4** n'a **aucune cible**, et la rebascule réflexe en `php74-fpm` ne fonctionne pas — **vérifier le minimum exigé par l'application avant de la promettre** (cas relevé en octobre 2026 : Galette 1.1.6.1, `define('GALETTE_PHP_MIN', '8.1')` dans `includes/sys_config/versions.inc.php`). En PHP 8.5, une **dépréciation** devient **fatale** dès que l'application installe son propre `set_error_handler` levant une exception sur tout ce que couvre `error_reporting()` : ici les casts non canoniques `(double)`/`(integer)`/`(boolean)`/`(binary)` (RFC `deprecations_php_8_5`) — page blanche 500, sans indice côté visiteur. **Diagnostic** : chercher `PHP Fatal error: Uncaught ErrorException: …` dans le journal du **frontal** (le PHP s'exécute là, pas sur le backend). **Contournement minimal et réversible** : passer `error_reporting(E_ALL)` à `error_reporting(E_ALL & ~E_DEPRECATED & ~E_USER_DEPRECATED)` — masque les dépréciations sans toucher à la logique (écrire **dans le même fichier**, pour préserver propriétaire et inode) ; **correction pérenne** : mise à jour de l'application (ici Galette ≥ 1.2.1, qui apporte la compatibilité PHP 8.5 **et** corrige les avis de sécurité de la branche 1.1.x, dont CVE-2025-53922). Corriger les casts un par un est illusoire : plusieurs centaines d'occurrences dans le code de l'application, perdues à la prochaine mise à jour.

### Système de Sauvegarde

**Scripts de sauvegarde** :
- `/usr/lib/alternc/sqlbackup.sh` : Sauvegarde MySQL (quotidienne/hebdomadaire)
- `/usr/bin/rsync` : Sauvegarde des dossiers via SSH
- `/usr/lib/alternc/update_mailman.sh` : Sauvegarde des archives Mailman

**Configuration** :
- Modes daily et weekly
- Gestion des permissions ACL automatique
- Protection contre les échecs en cascade (un dossier orphelin ne bloque pas les autres sauvegardes)

### Système de Supervision (Nagios 4 + Uptime Kuma + Ntfy sur `monit`)

**Hôte** : `monit` (Debian 13 trixie, noyau 6.12 ; accès `ssh monit` via le rebond `elma`) porte Nagios 4, Uptime Kuma, l'instance de push mobile `ntfy`, le relais Postfix authentifié et la page de statut publique.

**Pare-feu local (`/usr/local/sbin/news-201-firewall.sh`)** :
- La règle loopback `iptables -I INPUT 1 -i lo -j ACCEPT` est obligatoire : sans elle, le trafic interne sur le port 3001 (reverse proxy Nginx vers Uptime Kuma) et les agrégations Nagios (`kuma-aggregate`) sont rejetés (provoquait des erreurs HTTP 504 sur `status.lautre.org`).

**Scripts historiques** :
- `/usr/bin/nacup` : Plugin de monitoring Nagios
- `/usr/bin/nacup-cron` : Vérification des mises à jour disponibles (cron `/etc/cron.d/nacup`)

**Nagios 4** — configuration dans `/etc/nagios4/conf.d/` (commandes Debian dans `/etc/nagios-plugins/config/`, inclus par `cfg_dir`), état dans `/var/lib/nagios4/status.dat` :
- `hosts.cfg` déclare le backend, les frontaux, le proxy, la messagerie, les hyperviseurs, les routeurs et les filtres de fichiers ; groupes : `main`, `db`, `mail`, `mailq`, `web`, `proxy`, `hyperviseur`, `equipement`, `nfs`, `backup` (`mysql2` et `switch-2` sont commentés).
- Sondes Nagios : `check_imap`/`check_simap`/`check_pop`/`check_spop`/`check_smtp`/`check_ssmtp`/`check_clamav` sur le groupe `mail` (`edna`, `erza`) ; `check_https_public` et `check_ssl_lautre` (`check_ssl_cert -H lautre.net`, **non publié** sur la page de statut) sur le groupe `proxy` (`monit`, `nginx`) ; `check_mailman` sur `elisa` (voir « Listes de diffusion (Mailman) »).
- **Notifications Nagios actives (#217)** : Les contacts du template `normal` dans `/etc/nagios4/conf.d/00-templates.cfg` sont configurés sur les périodes `service_notification_period 24x7` et `host_notification_period 24x7` (auparavant `never`).
  - **Filtre de sévérité (#217)** : Les options du template `normal` sont restreintes à `service_notification_options c,r` (CRITICAL et RECOVERY uniquement) et `host_notification_options d,u,r` afin d'éliminer le spam nocturne lié aux simples avertissements transitoires (`WARNING`).
  - **Contacts & destinataires** : Le contactgroup `root` (`/etc/nagios4/conf.d/10-contacts.cfg`) contient `<admin1>,<admin2>`. Le contact `<contact>` a ses périodes de notification configurées sur `never` à sa demande pour ne plus recevoir les alertes mail de supervision.
- **Script de notification par courriel** : `/usr/local/lib/nagios/notify-by-email.sh`, invoqué par les commandes `notify-service-by-email` / `notify-host-by-email` de `/etc/nagios4/conf.d/40-commands.cfg`. Il met en forme l'alerte au format Uptime Kuma (badges `DOWN` / `WARN` / `UP` / `UNKNOWN`) et **est déployé par le rôle Ansible `nagios`** (voir « Versionnage » plus bas).
  - ⚠️ **L'en-tête `Subject` doit rester en ASCII pur** : un en-tête non ASCII (emoji, accent) force Postfix à négocier **SMTPUTF8**, que les MX de certains destinataires (`no-log.org`, `sonntag.fr`…) ne proposent pas → rejet `dsn=5.6.7 SMTPUTF8 is required, but was not offered by host …` et **perte de l'alerte**. Le script translittère donc l'objet par `iconv -f UTF-8 -t ASCII//TRANSLIT` en garde-fou (protection contre une future description de service accentuée). Le **corps** peut rester en UTF-8 (8BITMIME accepté, vérifié). Le premier bond `monit` → `smtp.lautre.net` étant en `status=sent`, seul le journal du MX (`edna`/`erza`) révèle le rebond ; l'avis de non-remise repart vers `alertes@lautre.net`, jamais vers les administrateurs. Incident : **#235**.
- **Rappel périodique** : `notification_interval 60` (minutes) dans le template `generic-service` (`/etc/nagios4/conf.d/00-templates.cfg`, ligne 33) — un service durablement en état non-OK est **re-notifié une fois par heure** (ajouté le 2026-10-27, #235 ; auparavant `0`, soit une seule alerte au changement d'état). Le filtre contact `normal` restant `c,r`, seuls CRITICAL et RECOVERY génèrent un mail vers le groupe `root` ; le contact `uptimekuma` reçoit en plus les WARNING/UNKNOWN (poussées Kuma). ⚠️ `notification_interval` **n'apparaît pas** dans `status.dat` : vérifier `next_notification = last_notification + 3600`.

**Relais Messagerie Postfix (`monit`)** :
- Boîte dédiée d'émission : `alertes@lautre.net` créée sur le backend `elisa` (tables `address` et `mailbox` avec `delivery='dovecot'`).
- **Whitelist anti-spam MX** : Les comptes `alertes@lautre.net` (alertes système, Nagios et Uptime Kuma) et `git@admin.lautre.net` (notifications Forgejo) sont whitelistés dans `/usr/local/sbin/policy-check.php` sur les serveurs MX (`erza` et `edna`). L'entrée du tableau `in_array($res["sasl_username"], array(...))` déclenche `unset($res["sasl_username"])`, ce qui court-circuite **à la fois** le plafond horaire (3 IP / 30 messages / 700 destinataires) et le contrôle de bannissement `root.pf_ban` (24 h) : un compte whitelisté passe même si une ligne de bannissement subsiste. Sans cette entrée, le compte Forgejo dépassait les 30 messages/heure et rebouclait sur son propre bannissement (`Sorry, user banned for …`). Le fichier est `-rwsr-sr-x root:staff` (setuid/setgid) sur `edna` : le réécrire **en place** pour préserver l'inode, jamais avec `sed -i`/`perl -i` (intervention et vérifications : #223).
- Postfix sur `monit` relaie vers `[smtp.lautre.net]:587` avec authentification SASL et TLS chiffré (`/etc/postfix/sasl_passwd` chmod 600, exclu de etckeeper).
- Permet l'envoi fiable des alertes système, Nagios et Uptime Kuma vers les administrateurs (`root@lautre.net`).

**Serveur de Notifications Push Mobiles (`ntfy`)** :
- Déployé sur `monit` (`ntfy 2.11.0`, binaire Debian natif, service systemd `ntfy.service`).
- Configuration : `/etc/ntfy/server.yml` (`base-url: "https://ntfy.lautre.net"`, `listen-http: "127.0.0.1:2586"`, `behind-proxy: true`, `auth-default-access: "deny-all"`).
- Vhost Nginx : `/etc/nginx/sites-available/ntfy.lautre.net.conf` (reverse proxy vers `127.0.0.1:2586`), certifié par le certificat wildcard `/etc/ssl/lautre.net/fullchain.pem` et `privkey.pem`.
- Enregistrement DNS : `ntfy.lautre.net` déclaré dans la table AlternC `sub_domaines` sur `elisa` (A `80.67.160.91`, AAAA `2001:910:2000::91`).
- Accès restreint : utilisateur admin `nagios` avec token d'authentification Bearer ; topic d'alertes : `alertes-lautre-net`. L'application Android officielle ntfy permet aux administrateurs de souscrire au topic en saisissant le serveur `https://ntfy.lautre.net` et leurs identifiants/token.

**Uptime Kuma** (`/usr/lib/uptime-kuma`, installation git, `pm2` sous `root`, `pm2-root.service`, HTTP sur `0.0.0.0:3001`, version 2.5.7) :
- **Aucune API REST de création de moniteur** : création et suppression se font en SQLite direct, **Kuma arrêté** (`pm2 stop uptime-kuma`) et **après sauvegarde** (`sqlite3 data/kuma.db ".backup <fichier>"`).
- Modèle : **un moniteur `push` par service public** (le moniteur agrégé « L'Autre Net » a été supprimé). Moniteurs actuels du groupe « Services » : IMAP (id 2), IMAPS (3), POP (4), POPS (5), SMTP (6), SMTPS (7), HTTPS (8), Mailman (10).
- Paramètres communs : `type='push'`, `interval=600`, `retry_interval=300`, `maxretries=2`, `description='Service Nagios : <service>'`, jeton `push_token` de 32 caractères hexadécimaux ; rattachement au groupe dans `monitor_group` (`monitor_id`, `group_id`, `weight`).
- **Canaux de notification (#217)** rattachés aux 8 moniteurs de services (`monitor_notification`) :
  - ID 1 : **ntfy** (`https://ntfy.lautre.net`, topic `alertes-lautre-net`, token Bearer, priorité Urgent/Haute).
  - ID 2 : **Email SMTP** (serveur `smtp.lautre.net:587`, expéditeur `alertes@lautre.net`, destinataire `root@lautre.net`).
- Tables à nettoyer avec un moniteur : `heartbeat`, `stat_minutely`, `stat_hourly`, `stat_daily`, `monitor_group` (plus `monitor_notification`, `monitor_tag`, `monitor_tls_info`, `monitor_maintenance`).
- Les heartbeats sont enregistrés en **UTC** (décalage de +2 h en heure d'été avec l'heure locale) : un écart d'horodatage n'est pas un arrêt des poussées.

**Chaîne d'agrégation Nagios → Kuma** :
- `/etc/nagios4/kuma-monitors.tsv` (mode `600 nagios:nagios`) : une ligne par service publié, `<service_description Nagios><TAB><jeton push>`. **Retirer une ligne dépublie le service sans toucher à la sonde Nagios** (utile pour retirer un service de la page publique tout en conservant ses alertes mail).
- `/usr/local/lib/nagios/kuma-aggregate` (Python) lit `/var/lib/nagios4/status.dat` et ce mapping, puis pousse `up`/`down` sur `http://127.0.0.1:3001/api/push/<jeton>`.
- **Logique d'état** : `down` dès qu'**au moins une** instance du service a `current_state != 0` et `scheduled_downtime_depth == 0` — un **WARNING compte donc comme `down`** sur la page publique (ne pas ajouter de seuil de péremption de certificat sans en tenir compte).
- Deux déclencheurs : le cron `/etc/cron.d/kuma-aggregate` (`*/15 * * * *`, cadencé à 15 min pour couvrir 24h sur la frise de ~90 barres d'Uptime Kuma) et la notification Nagios `notify-service-kuma` → `kuma-aggregate "$SERVICEDESC$"` (poussée immédiate sans délai sur changement d'état).

**Page de statut** :
- `status.lautre.org` est **publique** (slug `lautrenet`, sans authentification) ; `mon.lautre.org` est l'interface d'administration authentifiée.
- Logo hébergé localement (`data/upload/logo1.png`, référencé par `status_page.icon` = `/upload/logo1.png?t=…`) ; une URL externe est aussi acceptée — la bascule se fait en changeant `icon`.
- API publique : `/api/status-page/lautrenet` (composition) et `/api/status-page/heartbeat/lautrenet` (états).

**PHP sur `monit`** : **8.5 uniquement** — `php8.5-cli`, `php8.5-common`, `php8.5-fpm`, `php8.5-readline` et `libapache2-mod-php8.5` (`php -v` → 8.5.12, alternative `php-fpm.sock` → `/run/php/php8.5-fpm.sock`) ; le dépôt Sury est conservé mais **bridé par apt pinning** (`Package: *` → 1, `Package: php8.5*` → 900). Les vhosts `mon`, `net`, `status`, `prom`, `graph` sont servis en PHP 8.5 (`php8.5-fpm.sock` ou module Apache) — plus aucun ancien socket.
- ⚠️ **Piège majeur** : `nagios4-cgi` dépend de `libapache2-mod-php` (ou d'une alternative incluant `libapache2-mod-php8.5`) ; un `apt remove` naïf des paquets PHP **purge `nagios4` et `nagios4-cgi`**, donc `/etc/nagios4`. Toujours valider par `apt-get -s` avant de retirer du PHP sur un hôte Nagios.
- `php-common` et les bibliothèques `php-*` (composer/symfony) sont conservés ; `php8.5-opcache` n'existe pas (OPcache est intégré à `php8.5-common`).

**Retiré le 2026-10-25 (résiduel du moniteur témoin)** : service `UptimeKuma-Heartbeat`, commande `kuma-heartbeat`, scripts `/usr/local/lib/nagios/heartbeat-kuma` et `notify-kuma`, jeton `/etc/nagios4/kuma-push.token`. La commande `notify-host-kuma` subsiste — la directive `host_notification_commands` est **obligatoire** pour un contact Nagios (son absence casse la configuration) — mais elle est neutralisée (`/bin/true`) : ce chemin poussait vers le moniteur témoin supprimé (réponse 404) et aucun hôte n'utilise le groupe de contacts `uptimekuma`. Sauvegardes : `/root/kuma-2026-10-24/` et `/root/nagios-2026-10-24/`. Suivi Forgejo : **#187** (commentaires 2450 et 2451).

**Versionnage et déploiement de la configuration Nagios** :
- Le **rôle Ansible `nagios`** (`lautre.net/ansible`, `roles/nagios/`, cible le groupe `monitoring` = `monit` seul) déploie quatre fichiers :
  - `files/notify-by-email.sh` → `/usr/local/lib/nagios/notify-by-email.sh` (mode `0755`) ;
  - `files/00-templates.cfg` → `/etc/nagios4/conf.d/00-templates.cfg` (mode `0644`, validé par `nagios4 -v`) ;
  - `files/40-commands.cfg` → `/etc/nagios4/conf.d/40-commands.cfg` (mode `0644`, validé par `nagios4 -v`) ;
  - `files/check_postfix_conf_command.cfg` → `/etc/nagios/nrpe.d/check_postfix_conf_command.cfg` (mode `0644`).
  Les trois premiers déclenchent le handler `reload nagios4`, le dernier `restart nagios-nrpe-server`. Toute correction doit être reportée **dans le dépôt** (sinon elle est écrasée au prochain passage du rôle) ; le fichier du dépôt doit rester **byte-identique** à celui de `monit`.
- Le reste de la configuration Nagios (autres `conf.d/*.cfg`, `nrpe.cfg`, sondes) **n'est pas géré par Ansible** : modifications directes, versionnées par **etckeeper** (`/etc` est un dépôt git → `etckeeper commit -m …` après chaque changement).
- Puppet est **inactif** sur `monit` ; `/root/t/` (`nrpe.d`, `plugins`, `sudoers.d`) est un **vestige** de cette époque, à ne pas redéployer.

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

### Système de Détection et Nettoyage des Ressources Orphelines

**Dépôt de référence** : [`lautre.net/alternc-maintenance-tools`](https://git.lautre.net/lautre.net/alternc-maintenance-tools) (dépôt privé Forgejo).
Tous les scripts sont assainis (aucun secret ni mot de passe en dur, utilisation des configurations `/etc/alternc/my.cnf` et `~/.my.cnf`).

**Scripts clés** :
- `/root/orphans.sh` : Script unifié d'audit et de nettoyage des bases MySQL, utilisateurs MySQL, listes Mailman et enregistrements DNS orphelins (remplace les anciens `list_orphans.sh` et `clean_orphans.sh`).
- `/root/mailman_check_activity.py` : Analyse de l'historique et des messages récents dans les archives Mailman (`--active-days`).
- `/root/orphans_dns_notify.sh` / `orphans_dns_reminder.sh` : Notifications et relances préventives par courriel aux membres concernés avant purge DNS.
- `/root/orphans_dns_clean.sh` : Wrapper non-interactif de nettoyage automatique DNS avec rapport envoyé à `root@lautre.net`.
- `/root/bounce_orphans.sh` : Audit et conversion des adresses système / boîtes orphelines de la table `address` (issue #113).
- `/root/mailman-smtp-repair.sh` : Vérification et réparation de la chaîne de transport Postfix / Mailman.

**Commandes usuelles** :
- `/root/orphans.sh --check` : Rapport complet en lecture seule (génère `/root/rapport_orphans.txt`).
- `/root/orphans.sh --mysql --clean --dry-run` : Simulation de suppression des bases et utilisateurs MySQL.
- `/root/orphans.sh --mysql --clean --execute` : Nettoyage interactif avec confirmation et sauvegarde préalable.
- `/root/bounce_orphans.sh --check` : Liste des adresses système orphelines.
- `/root/bounce_orphans.sh --update` : Rétablissement en alias standard administrables par les membres.

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

### `/etc/opendkim/{KeyTable,SigningTable,TrustedHosts}`
Tables de signature DKIM, partagées en NFS entre le panneau et les MX ; rechargées par `/etc/cron.d/opendkim`

### `/etc/sudoers.d/20_check_spf_dmarc`
Autorise `nagios` à lancer l'audit SPF/DMARC en root, arguments figés sur `--check` (`--apply` injoignable par NRPE)

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

### Traitement d'un site compromis (incident)
- **Mettre en quarantaine, jamais supprimer** : déplacer les fichiers suspects hors du site et tenir un **manifeste** (source, compte, taille, date, empreinte, motif) ; conserver une copie comme pièce et prévoir le retour en arrière.
- **Borner les inventaires** : un `find` par racine, jamais de parcours récursif non borné sur le montage NFS `/var/www/alternc` ; traiter compte par compte (un balayage non borné sature le stockage partagé et fausse les mesures).
- **Informer le membre** : `From: root@lautre.net`, `To:` son adresse de contact, `Cc: contact@lautre.net` (le Cc se développe sur l'équipe de contact, soit plusieurs destinataires) ; **faire valider le texte avant envoi**, journaliser les remises et vérifier leur statut. Ne jamais demander de mot de passe par courriel.
- **Documenter** chaque opération dans le ticket Forgejo correspondant (dépôt `lautre.net/aide-generale`) : constat, mesure prise, réversibilité.

### Empreintes d'un site compromis (retours de l'incident d'octobre 2026)
- **Les md5 des charges utiles sont polymorphes** : deux fichiers de même taille peuvent porter des md5 différents, y compris d'un compte à l'autre. Un md5 ne vaut que pour un exemplaire identifié — **jamais comme critère de recherche**. Les marqueurs fiables sont la signature `Monarx, Inc.`, le `.htaccess` du portail (265 octets, md5 `c5512e483236affe2ee1840ab7817f50`) et les `.htaccess` citant les noms du portail.
- **Critères de recherche utilisables**, du plus au moins sûr : `HTP` = `.htaccess` de 265 o au md5 du portail ; `HT2` = `.htaccess` citant `wp-l0gin`/`wp-the1me`/`wp-scr1pts`/`lock360` ; `HT3` = `.htaccess` **rouvrant l'accès** : `Allow from all` (signature de l'attaquant). ⚠️ La **liste d'extensions** interdites seule (`.py|.exe|.phtml|…`) n'est **pas** un indice : c'est le `.htaccess` que **SPIP** génère dans chacun de ses répertoires (575 exemplaires légitimes sur un seul site en octobre 2026) — le critère qui les signalait produisait des centaines de faux positifs ; `CON` = constantes connues ; `P32` = motif `$p = "<32 hex>"` ; `EB` = motif `(gzinflate|gzuncompress|str_rot13)\(base64_decode` ou `eval(<identifiant>(` — **jamais** `eval($variable(` seul ; `SEO` = `$_REQUEST["0kb"]` ou `$_SESSION['secretyt']` ; `PAY` = fichier `.php` ou sans extension, de plus de 20 Ko, dont les 2 000 premiers octets portent un bloc base64 d'au moins 800 caractères ; `GT` = fichier `.php` dont l'ouverture est un `goto <étiquette>;` ; `HEX` = au moins 10 séquences `\xNN` dans les 200 premiers octets ; `SHELL` = `isset($_REQUEST[$password])` (coquille à mot de passe) ; `DIST` = `file_get_contents(` **et** `eval(` dans un fichier de moins de 1 Kio (chargeur distant) ; `BIG` = en-tête `#!` et plus de 1 Mio (script auto-extractible) ; `MED` = **magasin du kit** (faux média dont le contenu commence par `<32 hex>|{-.-!!!}|`) ; `IDX` = fichier portant `# appel SPIP` mais de plus de 200 octets (index.php de SPIP détourné — l'original en fait 42) ; `GLOB` = au moins une affectation `$GLOBALS["<nom>"]="(base64_decode|gzinflate|str_rot13|error_reporting)"` (charge utile à indirection, invisible aux motifs `eval(base64_decode…)` littéraux) ; `WPUP` = présence de la chaîne `wpuploader` (téléverseur) ; `PSW` = `$correctPassword` ou `$auth_pass` (coquille protégée par un mot de passe écrit en clair) ; `NOMF` = noms forts (`lock360.php`, `wp-l0gin.php`, `wp-the1me.php`, `wp-scr1pts.php`, `she11.php`, `anonfox.php`, `2index.php`, `filefuns.php`) ; `NOMV` = noms génériques (`radio.php`, `content.php`, `about.php`, `index.php`) **vérifiés par le contenu** ; `EVV` = motif `eval[[:space:]]*\([[:space:]]*base64_decode` — **à appliquer aux squelettes `.html`** (les `.php` sont déjà couverts par `EB`) ; le jeton du `$_POST` varie selon la campagne (`evv`, ou 32 hexadécimaux suivis d'un `die`).
- **Un détecteur doit être au moins aussi large que le nettoyeur** : en octobre 2026, l'audit cherchait `eval($variable(` quand la famille dominante écrivait `eval(nomDeFonction(` — quatre fichiers vus là où il y en avait cinquante-neuf, et **une famille entière (SEO) dépourvue de tout critère**. Les critères de l'audit et ceux de la quarantaine doivent provenir de la même définition ; tout élargissement se reporte des deux côtés. Conséquence à retenir : **tout comptage antérieur à la correction d'un motif est un minimum, pas un inventaire**.
- **Ne jamais plafonner la taille pour un critère de contenu** : un plafond de 300 Ko a laissé passer un chargeur de 1,15 Mo (base64 dans ses 2 000 premiers octets). Ne plafonner que les critères de nom, où la taille n'est qu'un indice.
- **Un nom ne suffit pas, un contenu tranche** : les portes dérobées se déguisent en fichiers d'application (`cache.php` de 5,6 Ko, `footer.php` de thème, `2index.php`) et se glissent dans des répertoires légitimes du cœur (`wp-includes/blocks/…`, `js/dist/`, `vendor/…`). Un critère de nom sans vérification produit des faux positifs (bibliothèques `Zebra_Database`, `shaarli`, `blogotext`).
- **Familles rencontrées** : charges signées `Monarx` déposées par un composant tiers ; famille `eval(<fonction>())` avec `gzinflate(base64_decode(...))` et décalage d'un caractère, jeton `$_REQUEST['d_time']` (présente dès 2021) ; kit dit « AnonymousFox » (`1.php`, `cmd.php`, `anonymousfox.php`, fichiers de 150 à 293 Ko, noms aléatoires) ; **famille SEO** (des `index.php` de 1 758 à 1 910 octets, marqués par `$_REQUEST["0kb"]` et `$_SESSION['secretyt']`, disséminés dans des sous-répertoires aux noms imitant WordPress : `statics`, `photos`, `upgrades`, `i18ns`, `galleries`, `cssjs`, `query-content`, `search-api`, `list-grid`, `nextjs`, `post-catalog`, `audits`, `requests`, `jquery3`, `comment-editor`) ; **famille `goto`** (`edit.php`, `filefuns.php`, `index.php` : ouverture sur un `goto` et chaînes concaténées en `\xNN`) ; **plateforme de diffusion** : `.htaccess` de camouflage (`HT3`), chargeurs `cache.php`, faux médias (`.mp4`, `.wma`, `.swf`, `.mov`, `.bmp`, `.m3u8`…) et archives `.zip` nommées `<média>_<12 hex>.zip`, imbriqués sur 8 à 11 niveaux dans des répertoires à suffixe aléatoire.
- **Familles de la seconde vague (octobre 2026)** : **coquille à mot de passe** — fichier de **125 octets** au nom imitant le cœur du CMS (`users.php`, `plugins.php`, `<hex>index.php`), qui teste un mot de passe en variable dans `$_REQUEST` puis exécute par `eval()` la commande reçue ; **chaque exemplaire a son propre mot de passe** et les dépôts s'étalent sur des semaines (44 exemplaires sur un seul compte, du 2026-09-04 au 2026-10-07) ; **chargeur distant** — fichier de **93 octets** qui lit une adresse distante et l'exécute (`gbbdns.php`) ; **magasin du kit** — faux média dont le contenu commence par `<32 hex>|{-.-!!!}|` (même marqueur que la famille relevée sur `<site-compromis>`) ; **déployeur d'accès distant** — script auto-extractible de plusieurs mégaoctets se terminant par `GS_USELOCAL=1 ./deploy.sh` (projet **gsocket** : le processus installe une connexion **sortante** vers un poste de contrôle) ; **installeur Windows** (`.msi`, 32 Mo) déposé à la racine d'un site ; **panneaux d'exécution du kit** : `…/LEVIATHAN/haxorcgiapi/{bash,perl,py}.haxor` et `…/ERENUSE/Erencgiapi/{bash,perl,py}.Eren` (accompagnés d'un `.htaccess`), plantés dans les bibliothèques du cœur (`plugins/auto/…/vendor/`, `plugins-dist/…`) et **de mêmes empreintes** d'un emplacement à l'autre ; **fausse arborescence WordPress** (`wp-load.php`, `wp-blog-header.php`) à la racine d'un site qui n'est pas un WordPress ; **loaders `include`/`require base64_decode(…)`** (et non seulement `include_once`) ; **`base64_decode` nu** (sans `gzinflate`/`gzuncompress`/`str_rot13`), angle mort de `EB`.
- **Deux pièges d'instrumentation** : `find -size` **arrondit à l'unité supérieure**, donc `-size -1M` ne matche **que les fichiers de 0 octet** — deux critères sont restés muets jusqu'à ce qu'on écrive `-size -1025c` ; et **ne jamais modifier un script pendant qu'une série l'exécute** : bash lit un script au fil de l'eau, une modification en cours d'exécution produit des erreurs de syntaxe « fantômes » alors que le fichier sur disque est sain.
- **Angles morts de l'audit** (à repasser à la main, compte par compte) : les fichiers **de plus de 6 Mo** (le plafond `MAXSIZE=6M` les exclut du parcours — un installeur Windows de 32 Mo et un déployeur de 16 Mo sont passés dessous) ; la **grosse coquille** (plus de 20 Ko, `$password = ""` + `curl_exec` + `base64_decode` + `set_time_limit(0)`, sans bloc base64 en tête) ; les **noms de fonctions en hexadécimal** (`$Array = ['7068705f756e616d65', …]` = `php_uname` — `HEX` cherche des échappements `\xNN` et ne les voit pas) ; les **artefacts de camouflage** (`php.ini` qui *retire* les protections de PHP, `robots.txt` pointant un `inx_sitemap.xml` inexistant, compteurs `adman.*.txt` de 6 octets déposés dans la même fournée que les coquilles) ; le **magasin du kit** si son extension n'est pas celle d'un média ; le **bootstrap entièrement remplacé** — `IDX` ne voit que les `index.php` **portant encore** `# appel SPIP` (code ajouté *devant* l'appel) et `GT` que ceux ouvrant sur un `goto` : un `index.php` racine **réécrit de bout en bout** en porte de camouflage échappe aux deux (cas relevé en octobre 2026 : 592 o, `stripos($user_agent,'google')`/`is_mobile` → `include('files.php')`/`include('home.php')`, cloaque servant des liens de paris indonésiens aux robots et aux mobiles ; les trois installations SPIP d'un même compte avaient ainsi leur `index.php` racine détourné, seul le site de référence en 4.2.7 était sain). Critère : **tout `index.php` racine de plus de 200 o est détourné** (l'original fait 42 o). Leçon : repasser les critères sur les échantillons déjà connus du compte avant de conclure — un critère muet ne prouve pas un compte propre.
- **Faux positif à connaître** : le critère `PAY` (« chargeur base64 volumineux ») attrape le fichier de configuration de **Wordfence** `wp-content/wflogs/config-transient.php` (1,5 à 1,7 Mo), dont l'en-tête est `<?php exit('Access denied'); __halt_compiler(); ?>` suivi de « used by the Wordfence Web Application Firewall » (config sérialisée en base64, écrite par l'extension elle-même). Le reconnaître à cet en-tête et l'**exclure** — sur un autre compte, deux exemplaires du même fichier classés `PAY` avaient d'ailleurs été correctement écartés. Faux positif consigné dans `faux-positifs-arbitrage-20261025.tsv`.

- **La charge d'un squelette survit dans le cache compilé** : SPIP recopie le contenu du squelette dans un commentaire `//` de `tmp/cache/skel/*.php`. Or `?>` **interrompt un commentaire `//` en PHP** : une charge déposée dans un squelette s'y retrouve **exécutable**. Nettoyer le squelette ne suffit donc pas — le cache compilé, plus récent, reste tenu pour valide et doit être mis en quarantaine. Cas relevé (octobre 2026) : deux vagues, **2014-03-05** (jeton `evv`, 34 caches) et **2016-07-31** (jeton hexadécimal suivi d'un `die`, 18 caches), sur des squelettes d'origine 2009/2011 **restés sains** : seuls les caches portaient la charge.
- **Les squelettes `.html` échappent aux critères de contenu** : `audit-compte.sh` n'applique `EB`, `SEO`, `SHELL`, `GLOB`, `WPUP`, `PSW`, `HEX` et `GT` qu'aux fichiers `.php` (liste `$T.php`), et `IDX` ne vise que les `index.php` de plus de 200 octets. Une charge déposée dans un squelette `.html` n'est donc vue que par le cache compilé qu'elle produit — et **le nettoyage ne converge pas** : le cache mis en quarantaine est régénéré à la visite suivante tant que le squelette n'est pas traité.
- **Le `deny from all` de `tmp/.htaccess` ne protège pas de ce vecteur** : il ferme l'accès par URL, pas l'inclusion par SPIP lui-même.
- **Méthode d'inventaire** : **un seul parcours `find` par racine** (`-printf '%s\t%p\n'`), listes dérivées par `awk` (php, `.htaccess`, gros fichiers), critères appliqués par `xargs` — l'audit faisait auparavant quinze parcours NFS par racine (plusieurs minutes), il en fait un (~1 min). Le critère `MED` est en plus **borné par date** (`-newermt`) et par extension : sans cette borne il relit tous les médias du compte, soit des milliers de fichiers sur un NFS dégradé (plus de 3 minutes pour un seul compte). Outils d'incident sur `elisa` : `/root/audit-compte.sh <login>`, `/root/quarantaine-compte.sh <login> [--executer]`, `/root/quarantaine-arbres.sh <login> <liste> [--executer]`, `/root/restaure-htaccess-spip.sh <login> [--executer]`.
- **Signature d'un SPIP sain** (indispensable pour ne pas confondre l'attaquant avec le cœur) : `index.php` = **42 octets** (`<?php` / `# appel SPIP` / `include('spip.php');`) ; `.htaccess` de répertoire = liste d'extensions **contenant `phtml`** ; `.htaccess` de protection généré = `Require all denied`. L'attaquant **raccourcit progressivement** cette liste (127 o, puis 98 o le jour de l'incident) alors que sa copie de camouflage (226 o) la reprend complète : une liste tronquée est un indice, une liste complète n'en est pas un. Autres gabarits de **réouverture d'accès** relevés (octobre 2026) : **63 o** (`<FilesMatch '.*'>` + `Order Deny,Allow` + `Allow from all`, planté jusque dans `plugins/auto/spip2spip/…`) et **308/323 o** (`RewriteEngine Off` + `Require all granted` sur `\.php`). Restitution de la liste canonique : réécriture avec sauvegarde de chaque fichier et manifeste (procédure réversible).
- **Le `.htaccess` de camouflage du kit est un tout indivisible** : `Deny from all` sur les scripts, puis un `Allow from all` dont la liste blanche reprend **les noms de ses propres fichiers** (`filefuns.php`, `userfuns.php`, `gdftps.php`, `postnews.php`, …), puis un contrôleur frontal WordPress (`RewriteRule . index.php`). **Aucun de ces blocs n'est légitime : ne pas en restaurer un fragment.** Cas relevé en octobre 2026 : ce bloc `mod_rewrite` a été remis en place à la racine d'un site **et** à la racine de son application, par erreur d'appréciation — alors que l'application (Galette) ne distribue **aucun** `.htaccess` à la racine de son installation (seuls `webroot/.htaccess` et ceux de `data/`). **Comparer systématiquement avec ce que distribue l'application** (dépôt officiel, autre installation intacte du parc) avant de restituer un `.htaccess` mis en quarantaine ; en cas de doute, ne rien remettre et le consigner.
- **Un `index.php` de SPIP détourné se répare tout seul** : le code de l'attaquant est ajouté **devant** l'appel SPIP et le fichier est **réécrit à chaque visite**. Preuve par recoupement : journal d'accès (`GET /` à 11:54:21) et date du fichier (écriture à 11:54:22), le magasin du kit étant écrit dans la même seconde. **Conséquence** : mettre le fichier en quarantaine ne sert à rien (il revient à la première visite) — il faut **restaurer la partie SPIP authentique** (extraire à partir du dernier `<?php` précédant `# appel SPIP`, ou reprendre l'`index.php` de référence du dépôt SPIP présent sur le serveur), puis mettre le magasin en quarantaine. Contrôle : audit à 0 **et** date du fichier qui ne bouge plus malgré les visites.
- **Contrôle d'un déployeur d'accès distant** (un outil d'accès système n'est pas une simple porte dérobée web) : processus en cours, connexions **sortantes** (gsocket ouvre lui-même la liaison), fichiers `gs-*` / `.tmp_egg`, tâches planifiées **des membres** (pas seulement de `root`), `ld.so.preload`, unités systemd étrangères, ports en écoute inhabituels. Y ajouter la revue de `/root/.ssh/authorized_keys` : une clé ajoutée par un tiers est un accès persistant **indépendant** de l'outil (à confronter aux clés légitimes de l'équipe).
- **Suffixe de neutralisation** : un renommage `nom__<7 hex>` (`__f911e3d`, `__bedaff6`) rend un répertoire inerte sans rien supprimer. Un site ainsi traité n'a plus de point d'entrée PHP, mais **les fichiers malveillants restent sur le disque** et faussent les balayages : les inventorier à part et les mettre en quarantaine. L'origine de ces suffixes n'est tracée nulle part (voir la purge de la table `actions` ci-dessous). Les variantes `nom<6 hex>` (`wp-includes48c20e`, `wp-content600e3d`, `seoebf263`, `b2e0b20304c`) vont plus loin : quand elles **remplacent** le cœur (`wp-includes` réduit à quelques fichiers, `wp-content` vidé), le site n'est pas réparable par nettoyage — il relève d'une reconstruction.
- **Quarantaine en deux temps** : les fichiers dont le contenu est prouvé malveillant d'abord (manifeste + md5, un fichier par ligne), puis les arborescences entières de l'attaquant (manifeste par arbre : type, nombre de fichiers, octets, période, et md5 de chaque fichier). Un script qui écrit son manifeste en écrasement fait perdre la trace du passage précédent : **toujours ajouter, jamais écraser**, et vérifier après coup que chaque ligne du manifeste correspond à un fichier présent.
- **Contrôle d'intégrité** : sur un WordPress, les fichiers malveillants occupant des emplacements du cœur sont indiscernables par le nom ; seule la comparaison aux sommes de contrôle officielles de la version installée est exhaustive.
- **Traçabilité limitée** : la table `actions` d'AlternC ne remonte qu'à quelques jours (purgée). Toute reconstitution d'une opération ancienne est donc impossible par ce moyen ; `ps.log` ne contient que les processus du moment.

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

### Requêtes MySQL en lot (parsing tabulé)
`mysql -B` **échappe** les tabulations et les retours à la ligne : une valeur contenant `CHAR(9)` ressort en `\t` littéral, ce qui casse tout découpage ultérieur (`awk -F'\t'`, `cut`) et peut faire échouer silencieusement un script de traitement. Pour une extraction destinée à être parsée, forcer systématiquement le mode brut :
```bash
mysql --defaults-file=/etc/alternc/my.cnf -r -B alternc -e "SELECT ..."
```

### Vérification DKIM / SPF / DMARC
```bash
dig +short TXT alternc._domainkey.<domaine> @127.0.0.1   # domaine hébergé
dig +short TXT alternc._domainkey.lautre.net             # clé des comptes (d=lautre.net)

/usr/local/sbin/alternc-spf-dmarc.sh --report /tmp/spf.txt          # audit (sur elisa)
/usr/local/sbin/alternc-spf-dmarc.sh --apply --report /tmp/spf.txt  # corrige absents et doublons
/usr/local/sbin/alternc-spf-dmarc.sh --dns --resolver 127.0.0.1     # + contrôle de la publication
```
Sur `elisa`, `resolv.conf` pointe un cache muet pour nos zones : interroger `@127.0.0.1` (BIND autoritaire), sinon la vérification DNS ne voit rien. Le `--dns` complet prend ~1 min 40 et reste un outil de diagnostic (hors Nagios).

### Vérification de la supervision (`monit`)
```bash
nagios4 -v /etc/nagios4/nagios.cfg                       # 0 erreur attendue
su -s /bin/bash nagios -c "/usr/local/lib/nagios/kuma-aggregate HTTPS"   # poussée manuelle d'un service
curl -s --resolve status.lautre.org:443:127.0.0.1 https://status.lautre.org/api/status-page/lautrenet
sqlite3 /usr/lib/uptime-kuma/data/kuma.db "select id,name,active,weight from monitor order by id;"
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

### Un moniteur de la page de statut est `down` alors que le service répond
- L'agrégateur retient l'état **le plus dégradé** de toutes les instances : inspecter chaque hôte du groupe concerné (`grep -A16 "service_description=<Service>" /var/lib/nagios4/status.dat`) avant de conclure.
- Vérifier la sonde elle-même : une sonde visant une adresse **interne** (`check_http -I $HOSTADDRESS$`) peut échouer alors que l'URL publique répond — la faire porter sur l'URL publique (`check_https_public`).
- Rejouer la poussée à la main : `su -s /bin/bash nagios -c "/usr/local/lib/nagios/kuma-aggregate <Service>"` (affiche les hôtes en alerte et le code HTTP de la poussée).
- Un service Nagios dont les notifications sont suspendues pour **flapping** ne bloque pas la poussée du cron (toutes les 2 min), mais la poussée immédiate de `notify-service-kuma` ne partira pas.

### Les alertes mail de Nagios ne partent plus (ou n'arrivent pas)
- **Vérifier d'abord que le message quitte `monit`** : `grep 'from=<alertes@lautre.net>' /var/log/mail.log`. Un `status=sent` ici **ne prouve rien** — le premier bond va vers le relais `smtp.lautre.net`, c'est le **MX** qui décide ensuite.
- **Chercher le rejet côté MX** : sur `edna` et `erza`, `grep 'SMTPUTF8 is required' /var/log/mail.log`. Un `dsn=5.6.7 … SMTPUTF8 is required, but was not offered by host …` signifie qu'un **en-tête** du message est non ASCII (le plus souvent le `Subject` du script de notification) : les MX des destinataires ne proposent pas l'extension SMTPUTF8. Corriger l'objet (ASCII pur, translittération `iconv`) — voir « Script de notification par courriel ». L'avis de non-remise repart vers `alertes@lautre.net` et **non** vers les administrateurs, d'où l'impression de silence total.
- **Exécuter le script à la main** pour isoler la cause : `sudo -u nagios /usr/local/lib/nagios/notify-by-email.sh service PROBLEM CRITICAL <hôte> "<service>" "<sortie>" "$(date '+%F %T')" <destinataire>`, puis suivre le cycle complet sur `monit` **et** sur les MX.
- **Ne pas confondre avec un problème de whitelist** : le compte `alertes@lautre.net` est whitelisté sur les MX (voir « Relais Messagerie Postfix ») ; un blocage de ce côté se traduirait par un rejet `Sorry, user banned …`, pas par `SMTPUTF8`.
- **Aucune notification du tout ?** Le script est lu à chaque notification (aucun rechargement nécessaire) ; vérifier `bash -n /usr/local/lib/nagios/notify-by-email.sh` (le script utilise `set -euo pipefail`) et que les commandes de `40-commands.cfg` pointent bien dessus.

### Faux CRITICAL « Postfix relayhost is configured to … » sur `monit`
- `check_postfix_conf` (NRPE, plugin de 2020) n'accepte que `relayhost` vide ou `edna.admin.lautre.net`. Or `monit` **est** un relais authentifié **voulu** vers `[smtp.lautre.net]:587` : c'est un faux positif.
- **Correctif** : sur `monit` **uniquement**, `/etc/nagios/nrpe.d/check_postfix_conf_command.cfg` → `command[check_postfix_conf]=sudo /usr/local/nagios/plugins/check_postfix_conf norelayhost`, puis `systemctl restart nagios-nrpe-server`. Les autres hôtes gardent le contrôle strict (un `relayhost` y serait une anomalie).
- ⚠️ Depuis le 2026-10-27, ce fichier **est déployé par le rôle Ansible `nagios`** : le mode `norelayhost` doit donc être conservé dans `roles/nagios/files/check_postfix_conf_command.cfg` (sinon il est écrasé au prochain passage du rôle). `/root/t/nrpe.d/` reste un **vestige Puppet** (chemin `/usr/lib/...`) à ne pas redéployer. Incident : **#235**.

### Un vérificateur DKIM en ligne (mxtoolbox…) ne trouve aucun enregistrement
- Le sélecteur de L'Autre Net est **`alternc`** (défaut d'AlternC), absent des listes de sélecteurs courants des outils (`default`, `dkim`, `mail`, `google`, `selector1`…). Il faut l'indiquer à l'outil, ou interroger `alternc._domainkey.<domaine>` en DNS. La signature porte le sélecteur (`s=`), la découverte automatique n'a aucun effet sur la délivrabilité.
- Pour un domaine de compte `<login>.lautre.net` (`gesdns=0`), il n'y a rien à ce nom **par conception** : la signature est en `d=lautre.net` / `s=alternc`. Vérifier `alternc._domainkey.lautre.net`, l'en-tête `DKIM-Signature` du message (`d=`, `s=`) et l'`Authentication-Results` chez le destinataire.
- Effet de bord du joker à connaître : tout nom sous `<login>.lautre.net` hérite des TXT du joker, donc `default._domainkey.<compte>.lautre.net` renvoie le TXT **SPF** du joker — un enregistrement qui n'est pas du DKIM. Inoffensif à la réception (SPF et DMARC se départagent par leur préfixe `v=spf1` / `v=DMARC1`), mais brouille les diagnostics. Ne pas tenter de « corriger » en révoquant ces noms (`p=` vide) : ce serait pire que le bruit.

### Un site répond 503 alors que le compte est actif
- **Diagnostiquer sur le nœud qui sert, jamais sur le backend AlternC** : `elisa` génère les pools et les vhosts, mais ce sont les frontaux (`emma`, `web2`) qui exécutent PHP. Un `phpX.Y-fpm` arrêté **sur `elisa`** n'explique pas un 503 observé de l'extérieur : vérifié le 2026-10-25, `php7.4-fpm` y est `inactive (dead)` depuis le 11/10 alors que `<site1>.lautre.net` (type `php74-fpm`) et `<site2>.lautre.net` (type `vhost`) répondent **200**. Un `curl` sur `127.0.0.1` lancé depuis `elisa` mesure l'état d'`elisa`, pas le service rendu au membre.
- **Identifier le frontal d'abord** : l'en-tête `X-Backend-Server` de la réponse (`curl -sD - -o /dev/null https://<domaine>/`) désigne le nœud qui a réellement servi la page (en octobre 2026 : `emma`, qui porte `php7.4-fpm` **et** `php8.5-fpm` `active (running)`, ~133 sockets `php7.4` et ~123 `php8.5`).
- **Vérifier ensuite le pool sur ce frontal** : `systemctl status phpX.Y-fpm` et, dans `/var/log/apache2/error.log`, `AH02454: FCGI: attempt to connect to Unix domain socket … No such file or directory`. Ce message signifie que le **maître PHP-FPM de cette version ne tourne pas sur cet hôte** : les comptes servis par ce pool y renvoient 503.
- **Comparer le socket attendu aux sockets présents** : lire celui du vhost (`grep -m1 -A40 "ServerName <domaine>" /var/lib/alternc/apache-vhost/vhosts_all.conf | grep -oE 'php[0-9.]+-[a-z0-9_]+\.sock'`) puis `ls /run/php/` **sur le frontal concerné**. Un compte peut avoir deux pools (l'ancien et le nouveau) : c'est le **vhost** qui décide lequel est utilisé (`/etc/php/<version>/fpm/pool.d/<login>.alternc.conf`, directive `listen`). ⚠️ Un type `vhost` (legacy, servi par le module Apache PHP 5.6) n'a **aucun** pool `phpX.Y-<login>.sock` : l'absence de socket n'est pas en soi une anomalie.
- **Ne pas confondre avec une compromission** : un compte sain peut répondre 503, et un compte compromis peut répondre 200. Le contrôle de l'état du pool fait partie du diagnostic, avant toute conclusion. **Avant d'annoncer à un membre que son site est indisponible, le vérifier depuis l'extérieur** (`curl -sD - -o /dev/null https://<domaine>/`) : le 2026-10-25, une conclusion tirée d'un `curl` local sur `elisa` a fait écrire à deux membres que leur site était arrêté alors qu'il répondait 200.

### Le parc NFS se fige et la charge monte sans processus actif
- `/var/www/alternc` est monté en NFS **`hard`** (export `/var/alternc/html` du serveur de fichiers) : sur un serveur dégradé, une requête **n'expire jamais**. Le processus reste en état `D` (attente d'entrée/sortie non interruptible) et `kill -9` ne le fait disparaître qu'au retour des E/S.
- **Premier réflexe** : `ps -eo pid,ppid,stat,etime,args | awk '$3 ~ /^D/'`. La charge compte les processus bloqués : une charge de 15 avec un seul processus éligible signale un blocage d'E/S, pas de la charge réelle.
- **Cause la plus fréquente constatée** (2026-10-25) : le cron de quota d'`/etc/cron.d/alternc-lautrenet` (`0 1 * * * root /usr/lib/alternc/spoolsize_web.php`) parcourt chaque compte via `sudo /usr/lib/alternc/du.pl` → `du -s`. Sur un NFS dégradé chaque `du` s'accroche ; l'exécution du jour ne se termine pas et les suivantes s'empilent (deux exécutions simultanées observées, dont une de plus de 24 h). Rien n'est alors « actif », tout est bloqué.
- **Dégager la charge** : repérer les exécutions bloquées (`ps -eo pid,lstart,args | grep spoolsize_web`) et arrêter toute la chaîne (`sh -c … spoolsize_web.php`, `php -q …`, `logger`, puis `du.pl` et `du -s`). Conséquence assumée : les quotas restent sur leurs valeurs précédentes jusqu'à la prochaine exécution réussie.
- **Ne pas confondre avec un balayage d'incident** : les inventaires lancés à la main sur le parc produisent exactement les mêmes processus `D`. Borner chaque racine, et arrêter ses propres balayages avant d'incriminer le stockage.
- **Témoin de l'état du stockage** : `timeout 15 du -s /var/www/alternc/<lettre>/<compte>`. Un blocage au-delà de 15 s sur plusieurs comptes désigne le serveur de fichiers, pas la commande — même lorsque `ls` répond encore (la lecture d'un répertoire et le parcours récursif n'ont pas le même coût).

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

## Chantiers en cours et points ouverts (état 2026-10-25)

| Sujet | Suivi | État |
| --- | --- | --- |
| Incident de compromission du parc (SPIP/WordPress) : quarantaines compte par compte, courriels aux membres | #183, #185, #198, #202, #212 | 17 comptes notifiés (dernière vague le 2026-10-25) ; restent les 92 comptes sans PHP et les reconstructions (#198) |
| Domaines encore en `php74-fpm` (373 sous-domaines / 140 comptes) | #180, #178, #175 | migration par lots planifiée |
| `unattended-upgrades` ne couvre pas l'origine Sury : PHP 8.5 n'est pas mis à jour automatiquement | #190 | à traiter |
| LibreNMS (`/opt/librenms`, installé en janvier 2020, `vendor/illuminate/support/Str.php` absent, `net.lautre.org` → 500, aucun trafic réel) | #191 | réparer ou retirer |
| Vhosts nginx : `listen … http2` (syntaxe obsolète) sur `mon`, `net`, `status`, `prom`, `graph` | #192 | traitement global (un correctif isolé provoque « protocol options redefined ») |
| Hôte `nginx` : l'HTTPS **interne** n'émet aucune réponse HTTP (TLS OK en ~25 ms, aucun premier octet ; `monit` répond 302) | #200 | à investiguer sur l'hôte |
| 3 doublons SPF côté membres (`<domaine1>`, `<domaine2>`, `<domaine3>`) : valeurs `txt` héritées contenant une ligne de zone entière avec tabulations littérales, donc deux TXT publiés (PermError) | #168 (clos) | à trancher : réparation fusionnée ou notification |
| Zone `admin.lautre.net` verrouillée (`;; LOCKED:YES`) : SPF et DMARC posés à la main, `rua` différent de la variable par défaut | #168 (clos) | alignement manuel seulement |

## Notes Importantes

1. **PHP Versions** : Le code AlternC peut être compatible PHP 5.3/5.6/7.x, mais l'environnement CLI peut être sur une version différente
2. **Base de données** : Le serveur MySQL principal est distant (`sql.lautre.net`), les connexions peuvent être affectées par des problèmes réseau
3. **NFS** : De nombreuses configurations sont synchronisées via NFS, les problèmes de réseau NFS peuvent impacter les services
4. **HA** : Certains services sont en haute disponibilité, les changements doivent être coordonnés entre les nœuds
5. **Variables système** : Certaines valeurs sont stockées dans la base de données et peuvent être réinitialisées par le code par défaut