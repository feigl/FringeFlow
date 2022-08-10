#!/bin/sh

# https://wiki.earthdata.nasa.gov/display/EL/How+To+Access+Data+With+cURL+And+Wget
fetch_urls() {
        while read -r line; do
            curl -b ~/.urs_cookies -c ~/.urs_cookies -L -n -f -Og $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
        done;
}
fetch_urls <<'EDSCEOF'
