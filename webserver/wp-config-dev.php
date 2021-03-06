<?php

// See also: wp-config-live-debug.php

/*
PHP-FPM pool config
    env[WP_ENV] = development
Apache mod_php .htaccess
    SetEnv WP_ENV development
Values: production, staging, development
*/

// WP_ENV by roots.io  https://github.com/roots/wp-stage-switcher/blob/master/wp-stage-switcher.php
define( 'WP_ENV', ( getenv( 'WP_ENV' ) ? : 'development' ) );

/** Development environment */
if ( defined( 'WP_ENV' ) && 'development' === WP_ENV ) {
    // WP_LOCAL_DEV by Mark Jaquith  https://gist.github.com/markjaquith/1044546
    define( 'WP_LOCAL_DEV', true );

    // WARNING! Lazy dev site - Links and images in posts are still pointing to the production site. Use wp-cli.
    define( '_REQUEST_SCHEME', ( isset( $_SERVER['HTTPS'] ) && 'on' === $_SERVER['HTTPS'] ) ? 'https://' : 'http://' );
    // EDIT core directory
    define( 'WP_SITEURL', sprintf( '%s%s/wordpress', _REQUEST_SCHEME, $_SERVER['HTTP_HOST'] ) );
    define( 'WP_HOME', _REQUEST_SCHEME . $_SERVER['HTTP_HOST'] );
    // EDIT wp-content directory
    define( 'WP_CONTENT_DIR', $_SERVER['DOCUMENT_ROOT'] . '/static' );
    // EDIT wp-content directory
    define( 'WP_CONTENT_URL', sprintf( '%s%s/static', _REQUEST_SCHEME, $_SERVER['HTTP_HOST'] ) );
    define( 'WP_DEBUG', true );
    define( 'WP_CACHE', false );
}
// EDIT production domain name
if ( 'production.com' === $_SERVER['SERVER_NAME'] ) {
    exit( 'Environment failure: no production on this domain!' );
}

/** Constants from Production environment */
define( 'WP_USE_EXT_MYSQL', false );
define( 'WP_POST_REVISIONS', 10 );
define( 'DISABLE_WP_CRON', true );
define( 'AUTOMATIC_UPDATER_DISABLED', true );

/*
   See /webserver/Wp-config-dev.md for complete how-to
*/
