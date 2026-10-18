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
- `/usr/lib/alternc/php7-fpm` (ou php82-fpm) : Génération et synchronisation des pools PHP-FPM via NFS vers les serveurs web frontaux
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
- Type de PHP par défaut : `php82-fpm` (remplace l'ancien `VHOST`/`mod_php`)
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
- Le script AlternC génère les fichiers `/etc/php/*/fpm/pool.d/<user>.alternc.conf`
- Synchronisation via NFS vers `/etc/alternc/sharedconf/php/`
- Support de multiples versions PHP (5.6, 7.x, 8.2)

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