#!/bin/bash
# Updates packages given as 'user/repo/branch/file' links

# Directory for downloading packages
PKG_DIR=lib
[[ -d $PKG_DIR ]] || mkdir -p $PKG_DIR

# Split $1 into variables
arg=$( echo $1 | sed 's|//*| |g' )
read user repo branch <<< $arg
file=$2

url="https://api.github.com/repos/$user/$repo/commits/$branch?path=$file"
raw_url="https://raw.githubusercontent.com/$user/$repo/$branch/$file"

package=$PKG_DIR/$(basename $file)
if [[ -f $package ]]; then
    # fetch modification timestamps from local file and file on github.com
    remote_timestamp=$( curl -s -I $url | grep "Last-Modified:" | sed 's/Last-Modified://' | date -f - +%s )
    local_timestamp=$(stat -c%Y $package)
    if [[ $local_timestamp -ge $remote_timestamp ]]; then
        echo "✔ $package"
        exit 0
    fi
fi

echo "✘ $package"
curl --progress-bar $raw_url -o $package
