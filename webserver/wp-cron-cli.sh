#!/bin/bash
#
# Run WordPress cron from CLI.
#
# VERSION       :0.7.2
# DATE          :2015-07-08
# AUTHOR        :Viktor Szépe <viktor@szepe.net>
# LICENSE       :The MIT License (MIT)
# URL           :https://github.com/szepeviktor/debian-server-tools
# BASH-VERSION  :4.2+
# DEPENDS       :apt-get install php5-cli
# LOCATION      :/usr/local/bin/wp-cron-cli.sh

# Disable wp-cron in your wp-config.php
#
#     define( 'DISABLE_WP_CRON', true );
#
# Reasons for WP-Cron to fail could be due to:
#  - DNS issue in the server.
#  - Plugins conflict
#  - Heavy load in the server which results in WP-Cron not executed fully
#  - WordPress bug
#  - Using of cache plugins that prevent the WP-Cron from loading
#  - And many other reasons
#
# Create cron job
#
#     01,31 *	* * *	webuser	/usr/local/bin/wp-cron-cli.sh /home/webuser/website/html

WPCRON_LOCATION="$1"

Die() {
    local RET="$1"

    shift
    echo -e "[wp-cron-cli] $*" 1>&2
    exit "$RET"
}

Get_meta() {
    # Defaults to self
    local FILE="${1:-$0}"
    # Defaults to "VERSION"
    local META="${2:-VERSION}"
    local VALUE="$(head -n 30 "$FILE" | grep -m 1 "^# ${META}\s*:" | cut -d ':' -f 2-)"

    if [ -z "$VALUE" ]; then
        VALUE="(unknown)"
    fi
    echo "$VALUE"
}

# Look for usual document root: /home/user/website/html
if [ -z "$WPCRON_LOCATION" ] \
    && [ -f "${HOME}/website/html/wp-cron.php" ]; then
    WPCRON_DIR="${HOME}/website/html"
# Directly specified
elif [ "$(basename "$WPCRON_LOCATION")" == "wp-cron.php" ] \
    && [ -f "$WPCRON_LOCATION" ]; then
    WPCRON_DIR="$(dirname "$WPCRON_LOCATION")"
# "website" directory
elif [ -f "${WPCRON_LOCATION}/html/wp-cron.php" ]; then
    WPCRON_DIR="${WPCRON_LOCATION}/html"
# WordPress root directory
elif [ -f "${WPCRON_LOCATION}/wp-cron.php" ]; then
    WPCRON_DIR="$WPCRON_LOCATION"
else
    Die 1 "Wp-cron not found (${WPCRON_LOCATION})"
fi

# Set server and execution environment information
export REMOTE_ADDR="127.0.0.1"
#export SERVER_ADDR="127.0.0.1"
#export SERVER_SOFTWARE="Apache"
#export SERVER_SOFTWARE="nginx"
#export SERVER_NAME="<DOMAIN>"

# Request data
export REQUEST_METHOD="GET"
#export REQUEST_URI="/<SUBDIR>/wp-cron.php"
#export SERVER_PROTOCOL="HTTP/1.1"
export HTTP_USER_AGENT="Wp-cron/$(Get_meta) (php-cli; Linux)"

pushd "$WPCRON_DIR" > /dev/null || Die 2 "Cannot change to directory (${WPCRON_DIR})"
[ -r wp-cron.php ] || Die 3 "File not found (${WPCRON_DIR}/wp-cron.php)"

#     wp --quiet cron event list --fields=hook,next_run_relative --format=csv \
#         | sed -n -e 's;^\(.\+\),now$;\1;p' | xargs -r wp --quiet cron event run
# Since 0.24.0
#     wp cron event run --due-now
if ! nice /usr/bin/php wp-cron.php; then
    Die 4 "PHP exit status $? in ${WPCRON_DIR}/wp-cron.php"
fi

popd > /dev/null

exit 0
