# WordPress development environment

### Server configuration

- Apache virtual host, HTTP/AUTH?
- PHP-FPM pool
- Fail2ban
- MTA
- Backup to object storage (s3ql with OpenStack swift or S3)

### Website

WP-CLI config: [wp-cli.yml](http://wp-cli.org/config/) possibly above document root.

```yaml
path: /home/user/website/html/wp
url: http://SITENAME.COM
debug: true
skip-plugins:
    # Version randomizer
    - better-wp-security
    - backupwordpress
user: USERNAME
core download:
    locale: hu_HU
core update:
    locale: hu_HU
```

```bash
wp db import wp-database.sql
#zcat wp-database.sql.gz | wp db import -
```

Create /robots.txt

```bash
cd $DOCUMENT_ROOT/
wget https://my.brand.site/favicon.ico
echo -e "User-agent: *\nDisallow: /\n# Please stop sending further requests." > robots.txt
```

Upload /robots.txt and your developer /favicon.ico

```
User-agent: *
Disallow: /
# Please stop sending further requests.
```

### wp-config.php constants

See https://codex.wordpress.org/Editing_wp-config.php

Import database, set DB_* constants.

Replace original URL.

```bash
read -r -e -p "ORIGINAL URL=" ORIG_URL
read -r -e -p "ORIGINAL PATH=" ORIG_PATH
read -r -e -p "ORIGINAL EMAIL=" ORIG_MAIL
read -r -e -p "DEVELOPMENT URL=" DEV_URL
read -r -e -p "DEVELOPMENT PATH=" DEV_PATH
read -r -e -p "DEVELOPMENT EMAIL=" DEV_MAIL
wp search-replace --precise --recurse-objects --all-tables-with-prefix "${ORIG_URL%/}" "${DEV_URL%/}"
wp search-replace --precise --recurse-objects --all-tables-with-prefix "${ORIG_URL#*:}" "${DEV_URL#*:}"
wp search-replace --precise --recurse-objects --all-tables-with-prefix "$ORIG_PATH" "$DEV_PATH"
wp search-replace --precise --recurse-objects --all-tables-with-prefix "$ORIG_MAIL" "$DEV_MAIL"
ORIG_DOMAIN="${ORIG_URL#*//}"
DEV_DOMAIN="${DEV_URL#*//}"
wp search-replace --precise --recurse-objects --all-tables-with-prefix "${ORIG_URL%%/*}" "${DEV_URL%%/*}"
```

Force site URL (see /webserver/wp-config-dev.php) or download Search-Replace-DB

1. https://github.com/interconnectit/Search-Replace-DB/raw/master/index.php
1. https://github.com/interconnectit/Search-Replace-DB/raw/master/srdb.class.php

Upload index.php as srdb.php (delete both files after replace).

1. `http://DOMAIN.TLD` → `https://DEV.SITE.COM` (no trailing slash)
1. `//DOMAIN.TLD` → `//DEV.SITE.COM` (no trailing slash)
1. `/home/PATH/TO/SITE` → `C:/wamp/php/wordpress` (no trailing slash)
1. `EMAIL@ADDRESS.ES` → `DEVELOPMENT@ADDRE.SS` (all addresses)
1. `DOMAIN.TLD` → `DEV.SITE.COM` (now without protocol)

Change salts.

- If you have apg installed: `wordpress-plugin-construction/wp-safe-salt.sh >> wp-config.php`
- Using PHP's OpenSSL support: `php wordpress-plugin-construction/wp-safe-salt.php >> wp-config.php`
- From Automattic: `wget -qO- https://api.wordpress.org/secret-key/1.1/salt/ >> wp-config.php`
- Get salts from Automattic: https://api.wordpress.org/secret-key/1.1/salt/

Constants for [debugging](https://codex.wordpress.org/Debugging_in_WordPress):

```php
define( 'SCRIPT_DEBUG', true );
define( 'SAVEQUERIES', false );
// Look for plugin *_DEV constants: grep -E -r -m1 "defined.*(_DEV|DEV_)" wp-content/plugins/*
define( 'JETPACK_DEV_DEBUG', true );
define( 'PODS_DEVELOPER', true );
define( 'SIMPLE_HISTORY_DEV', true );
define( 'W3TC_PRO_DEV_MODE', true );
```

See https://github.com/szepeviktor/WPHW

## Plugins

MU plugins are from https://github.com/szepeviktor/wordpress-plugin-construction

Faster plugin install: `plugin-installer-speedup`

Deactivate unnecessary plugins:
- security on localhost but **not** on public development site
- backup
- email, newsletter
- 3rd-party service

@TODO Auto-disable and require some plugins.

Protect plugins from deactivation: `mu-protect-plugins`

Prevent indexing: `mu-prevent-public`

Disable updates: `mu-disable-updates`

Triggers WP-cron manually: `manual-cron`

Disable CDN rewriting.

Set admin email:

- `wp option set admin_email DEVELOPMENT@ADDRE.SS`
- `http://DEV.SITE.COM/wp-admin/options-general.php`

Enable developer's user as administrator:

- `wp user set-role DEVELOPER administrator`
- `http://DEV.SITE.COM/wp-admin/users.php`

Development tools:

- `option-inspector`
- `what-the-file`
- `error-log-monitor`
- `query-monitor`
- `p3-profiler`

@TODO Move to wordpress-sitebuild/...

Block all outgoing HTTP traffic: `airplane-mode`

`wp install plugin "https://github.com/norcross/airplane-mode/archive/master.zip" --activate`

@TODO Block HTTP traffic on admin and on frontend:

- ? `if ( 'on' === get_site_option( 'airplane-mode' ) )`
- Google Analytics
- New Relic `php_admin_flag[newrelic.browser_monitoring.auto_instrument] = Off`
- Mouse tracking
- Other 3rd-party services

@TODO Distinguish development site:

- Admin bar: outline-bottom + transition
- [TAG] Page title: admin and frontend
- https://plugins.svn.wordpress.org/easy-local-site/trunk/easy-local-site.php

### Email delivery

By `wp_mail()`

- Log `wp_mail()` calls instead of sending: `mu-no-mail`

By `sendmail` (calling `mail()` function)

- Log all `mail()` calls:
  - FPM: `php_admin_value[mail.log] = /home/user/log/mail.log`
  - .htaccess: `php_admin_value sendmail_path /home/user/log/mail.log`
- Force recipient for all `mail()` calls:
  - FPM: `php_admin_value[mail.force_extra_parameters] = "DEVELOPMENT@ADDRE.SS"`
  - .htaccess: `php_admin_value mail.force_extra_parameters "DEVELOPMENT@ADDRE.SS"`
- Dump all messages sent by `mail()` to a file:
  - FPM: `php_admin_value[sendmail_path] = /usr/local/sbin/dev-sendmail.sh`
  - .htaccess: `php_admin_value sendmail_path /home/user/bin/dev-sendmail.sh`
- Block `mail()` function:
  - In PHP PFM pool config append `mail` to `php_admin_value[disable_functions]`
  - In php.ini append `mail` to `disable_functions`

By SMTP

- Use local SMTP server: `smtp-uri` and [Mailcatcher](https://mailcatcher.me/) or [MailHog](https://github.com/mailhog/MailHog)
- Forward SMTP traffic to Mailcatcher, MailHog or any other SMTP server
- Block outgoing SMTP traffic (TCP port 25, 587 and 465) by user

### Media

Use production Media Library from a staging/development site.

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond "%{REQUEST_FILENAME}" !-f
    RewriteRule "wp-content/uploads/(.*)$" "https://www.PRODUCTION.NET/wp-content/uploads/$1" [R,L]
</IfModule>
```

### Export plugins and theme

- Export plugin and theme settings separately
- Push to git repository
- [WP downloader](https://github.com/szepeviktor/wordpress-plugin-construction/tree/master/shared-hosting-aid/wp-downloader)
- [Clean database](/webserver/Production-website.md#clean-up-database)
- Dump database in a single transaction
