# Setting up a production WordPress website

1. [Installation](#installation)
1. [Migration](#migration)
1. [Upgrade](#upgrade)
1. [Check](#check)
1. [Monitor](#monitor)
1. [Backup](#backup)
1. [Uninstallation](#uninstallation)


## Installation


### DNS setup

- A, CNAME (for [CDN](http://www.cdnplanet.com/cdns/))
- MX
- SPF, DKIM

### SSL certificate

- For safety (personal data)
- For security (less attacks)
- For trust (green lock in browsers)
- For better SEO ranking
- For speed (enables HTTP/2)
- For receiving referrer information (up to April 2012)
- Very cheap

Providers: Let's Encrypt, StartSSL, RapidSSL, CloudFlare SSL

OCSP performance: http://uptime.netcraft.com/perf/reports/performance/OCSP

1. [Apache-SSL.md](./Apache-SSL.md)
1. https://www.ssllabs.com/ssltest/

### WordPress core, theme from git

`git clone --recursive ssh://user@server:port/path/to/git`

1. Set up database connection in `wp-config.php`
1. Define contants, generate salts based on [wp-config.php skeleton](./wp-config.php)
1. Edit `../wp-cli.yml`

### Install plugins

`wp plugin install --activate classic-smilies`

`wp plugin install --activate wordpress-seo w3-total-cache contact-form-7`

Disable comments? `mu-disable-comments`

Allow accents in URL-s? `mu-latin-accent-urls`

MU plugins: https://github.com/szepeviktor/wordpress-plugin-construction

### Create root files

- robots.txt
- favicon.ico
- apple-touch-icon.png
- browserconfig.xml
- etc.

### Maintenance

Custom maintenance page

### Set up CDN

- [Revving filenames](http://www.stevesouders.com/blog/2008/08/23/revving-filenames-dont-use-querystring/)
- HTML caching or no-cache?
- Disallow HTML pages on CDN (robots-cdn.txt)
- https://aws.amazon.com/console/
- https://www.cloudflare.com/a/login see also CloudFlare.md

### Set up mail sending

`wp plugin install --activate wp-mailfrom-ii smtp-uri`

`wp eval 'wp_mail("admin@szepe.net","first outgoing",site_url());'`

- Obfuscate email addresses `antispambot( 'e@ma.il' )`
- [JavaScript href fallback](https://gist.github.com/joshdick/961154): https://www.google.com/recaptcha/admin#mailhide
- Authenticated send for email notifications
- Shortest route of delivery
- Add server as `RELAYCLIENT` on the smarthost
- Email `From:` name and address
- Subject line
- Easy identification for email notifications (filtering to mail folders)
- SPF
- DKIM

Consider transactional email service through HTTP API: Mailjet, Amazon SES etc.

Mandrill API for WordPress: https://github.com/danielbachhuber/mandrill-wp-mail

### Security

- Allow loading in an IFRAME? (Google translate, Facebook app)
- `wordpress-fail2ban`
- Option: Sucuri Scanner plugin
- Option: [Ninja Firewall Pro](http://ninjafirewall.com/pro/download.php)
- Option: ionCube24 `ic24.enable = on` (PHP file modification time protection)
- Tripwire.php or git (file change notifications @30 minutes)
- .php and .htaccess changes (monitoring/siteprotection.sh @daily)
- Front page change notification (@hourly)
- Sucuri SiteCheck (Google Safe Browsing), Virustotal (HTTP API @daily)
- Can-send-email (monitoring/cse @6 hours)
- Maximum security: convert website into static HTML files + [formspree](https://formspree.io/)
- Subresource Integrity (SRI) `integrity="sha256-$(cat resource.js | openssl dgst -sha256 -binary | openssl enc -base64)" crossorigin="anonymous"`

### Set up cron jobs

Remove left-over WP-Cron events.

`wp cron event list; wp cron schedule list`

Use real cron job.

`wp-cron-cli.sh`

### Settings

- General Settings
- Writing Settings
- Reading Settings
- Media Settings (fewer generated image sizes)
- Permalink Settings
- WP Mail From

### User management

- 1 administrator
- Personal accounts for editors and authors
- Modify post and page authors
- Enable/disable author sitemaps


## Migration


### Search & replace URL and installation path

Replace constants in `wp-config.php`.

`wp search-replace --precise --recurse-objects --all-tables-with-prefix ${OLD} ${NEW}`

1. `http://DOMAIN.TLD/wp-includes` -> `https://NEW-DOMAIN.TLD/SITE/wp-includes` (no trailing slash)
1. `//DOMAIN.TLD/wp-includes` -> `//NEW-DOMAIN.TLD/SITE/wp-includes` (no trailing slash)
1. `http://DOMAIN.TLD/wp-content` -> `https://NEW-DOMAIN.TLD/static` (no trailing slash)
1. `//DOMAIN.TLD/wp-content` -> `//NEW-DOMAIN.TLD/static` (no trailing slash)
1. `http://DOMAIN.TLD` (no trailing slash)
1. `//DOMAIN.TLD` (no trailing slash)
1. `/home/PATH/TO/SITE` (no trailing slash)
1. `EMAIL@ADDRESS.ES` (all addresses)
1. `DOMAIN.TLD` (now without protocol)

Check home and siteurl.

`wp option get home; wp option get siteurl`

### Uploads, media

`wp media regenerate --yes`

### Clean up database

Check database collation and table storage engines.

See [alter-table.sql](/mysql/alter-table.sql)

Delete transients and object cache.

`wp plugin install --activate wp-sweep`

```
wp transient delete-all
wp db query "DELETE FROM $(wp eval 'global $table_prefix;echo $table_prefix;')options WHERE option_name LIKE '%_transient_%'"
wp cache flush
```

Purge page cache.

```
wp w3-total-cache flush
ls -l /home/${U}/website/html/static/cache/
ls -l /home/${U}/website/pagespeed/; touch /home/${U}/website/pagespeed/cache.flush
```

Check spam and trash comments.

```
wp comment list --status=spam --format=count
wp comment list --status=trash --format=count
```

Optimize database tables.

`wp db optimize`

### Remove development and testing stuff

- Code editor configuration file `.editorconfig`
- Files: `find -iname "*example*" -iname "*sample*" -iname "*demo*"`
- PHP-FPM pool config: `env[WP_ENV] = production`

### VCS

Put custom theme and plugins under git version control.

Keep git dir above document root.

### Redirect old URL-s (SEO)

`wp plugin install --activate safe-redirect-manager`

`https://www.google.com/search?q=site:DOMAIN`

### Flush Google public DNS cache

http://google-public-dns.appspot.com/cache


## Upgrade


@TODO ## Downgrade


## Check


### Marketing

- [Videos by one person!](https://wistia.com/blog/startup-ceo-makes-videos)
- External URL-s should open in new window
- Newsletter subscribe
- Offer free download
- Exit modal or Hijack box: coupon, free download, blog notification, newsletter etc.
- Background: http://www.aqua.hu/files/pix-background/nv-gf-gtx-heroesofthestormgeneric-skin2-hun.jpg
- Sharing: https://www.addthis.com/ https://www.po.st/ http://www.sharethis.com/
- Content to share: https://paper.li/

### Code styling

- UTF-8 encoding (no BOM)
- Line ends
- Indentation
- Trailing spaces `sed -i 's;\s\+$;;' file.ext`

### Theme and plugin check

1. Theme meta and version in style.css
1. `query-monitor` errors and warnings
1. `theme-check` and http://themecheck.org/
1. `vip-scanner`
1. Frontend Debugger `?remove-scripts`
1. `p3-profiler`
1. https://validator.w3.org
1. https://validator.nu/
1. https://www.webpagetest.org/

#### Typical theme and plugin errors

- Dynamic page parts (e.g. rotating quotes by PHP)
- Dynamically generated resources `style.css.php` (fix: `grep -E "(register|enqueue).*\.php"`)
- Missing resource version in `grep -E "wp_(register|enqueue)_.*\("` calls
- New WordPress entry point (fix: `grep -E "\b(require|include).*wp-"`)
- Always require admin code (fix: `whats-running`)
- Lack of `grep -E "\\\$_(GET|POST)"` sanitization
- PHP short opentags `grep -F "<?="`
- PHP errors, WP deprecated (fix: `define( 'WP_DEBUG', true );`)
- Permissions for WP editors
- Non-200 HTTP response
- Extra server-side requests: HTTP, DNS, file access
- Independent e-mail sending (fix: `grep -E "\b(wp_)?mail\("`)
- Propiertary install/update (fix: comment out TGM-Plugin-Activation)
- Home call, external URL-s (fix: search for URL-s, use Snitch plugin and tcpdump)
- Insufficient or excessive font character sets (fix: `&subset=latin,latin-ext`)
- `@font-face` formats: eof, woff2, woff, ttf, svg; position: top of first CSS
- Form field for file upload: `<input type="file" />`
- BOM (fix: `sed -ne '1s/\xEF\xBB\xBF/BOM!!!/p'`)
- Characters before `<!DOCTYPE html>`
- JavaScript code parsable as HTML link (e.g. `<a>` or `<iframe>`)
- Display content by JavaScript (causes FOUC)
- Mobile views
- Confusion in colors: normal text color, link and call2action color, accent color
- Firefox carot
- Email header and content check with https://www.mail-tester.com/

### 404 page

- Informative
- Cooperative (search form, automatic suggestions, Google's fixurl.js)
- Attractive

### Resource optimization

- Image format `convert PNG --quality 100 JPG`
- Image name `mv DSC-0005.JPG prefix-descriptive-name.jpg`
- Image optimization `jpeg-recompress JPG OPTI_JPG`
- JS, CSS concatenation, minimization `cat small_1.css small_2.css > large.css`
- Conditional, lazy or late loading (slider, map, facebook content, image gallery)
- Light loading, e.g. `&controls=2` for YouTube
- HTTP/2 server push

### PHP errors

wp-config.php: `define( 'WP_DEBUG', true );`

```bash
tail -f /var/log/apache2/SITE_USER-error.log | sed -e 's;\\n;\n●;g'
```

### JavaScript errors

@TODO

Send to Analytics, report to `/js-error.php`

### SEO

- `blog_public` and robots.txt
- XML sitemap
- Page title (blue in SERP)
- Permalink structure and slug optimization (green in SERP)
- Page meta description (grey in SERP)
- Headings: h1, h2 / h3-h6
- Images: alt, title
- Breadcrumbs
- [noarchive?](https://support.google.com/webmasters/answer/79812)
- Structured data: https://schema.org/ http://microformats.org/
- Content Keywords
- [Google My Business](https://www.google.com/business/)

### Legal

- Privacy policy + opt out
- Terms & Conditions
- Cookie consent + opt out
- "Operated by", "Hosted at"

### Print friendly

http://www.printfriendly.com/

### External resources (3rd party services)

Document in README.md and check functionality.

- External search
- Analytics (make UA-number `'UN'+'parse'+'able'`), tracking
- Social media
- Video
- Advertisement
- Live chat
- Newsletter subscription
- Payment gateway
- CDN

### Tracking

Gain access, set up and test.

- Google Analytics, Remarketing
- Facebook pixel
- Piwik
- Clicktale
- URL shortening: Link tracking, Download tracking

### Last checks

- Basic site functionality
- Registration
- Purchase
- Contact forms


## Monitor


https://wiki.apache.org/httpd/ListOfErrors

1. Domain expiry
1. DNS records
1. SSL certificate expiry
1. @TODO `monitoring/rbl-watch.sh`, `rblcheck`, [RBL blacklist monitoring](https://www.rblmon.com/), https://www.projecthoneypot.org/ (also for shared-hosting servers)
1. HTML source code inspection
1. Malware: [Sucuri SiteCheck (Safebrowsing)](https://sitecheck.sucuri.net/results/example.com), [Virustotal URL](https://www.virustotal.com/hu/domain/example.com/information/)
1. Uptime: https://uptimerobot.com/signUp , `shared-hosting-aid/ping.php`, `ping.php?time=$(date "+%s")`
1. @TODO Detect JavaScript errors
  - Piwik
  - http://jserrlog.appspot.com/
  - https://github.com/mperdeck/jsnlog.js
  - https://developers.google.com/analytics/devguides/collection/analyticsjs/exceptions
  - https://github.com/errbit/errbit
  - https://github.com/airbrake/airbrake-js
  - handle ad blockers (Adblock Plus, uBlock Origin, Disconnect, Ghostery)
1. Front page monitoring `monitoring/frontpage-check.sh`
1. Visual changes: https://visualping.io/ @TODO PhantomJS/slimerJS + `compare -metric MAE/PAE reference.png current.png`
1. File changes `lucanos/Tripwire`, `lasergoat/Tripwire` (rewrite)
1. Filter Apache error log `monitoring/apache-xreport.sh` @TODO munin plugin: log size in lines
1. Monitor Apache error log `monitoring/apache-4xx-report.sh`, `error-log-monitor` plugin on shared hosting, `shared-hosting-aid/remote-log-watch.sh` @TODO Remote rotate error.log
1. Connected services: trackers, API-s, CDN etc.
1. Email delivery, also recipient accounts: `can-send-email`
1. Also for email recipient domains: domain expiry, DNS, blacklist
1. Speed: https://developers.google.com/speed/pagespeed/insights/ https://www.webpagetest.org/
1. Google Search Console
1. Traffic: Analytics
1. SEO ranking: SEO Panel


## Backup


1. DB
1. Files
1. Settings (connected services)
1. Authentication data


## Uninstallation


- Archive for long term
- Monitoring
- Backups
- DNS records
- Webserver vhost, add placeholder page
- PHP-FPM pool
- Files
- Linux user
- Email accounts
- DB, DB user
- External resources (3rd party services)
- [Google Search Console](https://www.google.com/webmasters/tools/url-removal)
- ... @TODO
