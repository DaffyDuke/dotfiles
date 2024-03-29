#!/bin/bash

cleanup()
{
    local data_path="$1"        # full path to data directory of wiki
    local retention_days="$2"   # number of days after which old files are to be removed

    # purge files older than ${retention_days} days from attic and media_attic (old revisions)
    find "${data_path}"/{media_,}attic/ -type f -mtime +${retention_days} -delete

    # remove stale lock files (files which are 1-2 days old)
    find "${data_path}"/locks/ -name '*.lock' -type f -mtime +1 -delete

    # remove empty directories
    find "${data_path}"/{attic,cache,index,locks,media,media_attic,media_meta,meta,pages,tmp}/ \
        -mindepth 1 -type d -empty -delete

    # remove files older than ${retention_days} days from the cache
    if [ -e "${data_path}"/cache/?/ ]
    then
        find "${data_path}"/cache/?/ -type f -mtime +${retention_days} -delete
    fi
}

# cleanup DokuWiki installations (path to datadir, number of days)
# some examples:

cleanup /home/user1/htdocs/doku/data    256
cleanup /home/user2/htdocs/mywiki/data  180
cleanup /var/www/superwiki/data         180