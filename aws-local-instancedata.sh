#!/bin/sh

# Copyright (c) 2018 Verb Networks Pty Ltd <contact [at] verbnetworks.com>
#  - All rights reserved.
#
# Apache License v2.0
#  - http://www.apache.org/licenses/LICENSE-2.0


aws_local_instancedata()
{
    local local_path="$1"
    local aws_root="$2"

    # NB: defaults are dealt with in long-hand because using {} approach causes Terraform to (attempt to) interpolate

    if [ -z "$local_path" ]; then
        local_path="/var/lib/cloud/instance/instance-data"
    fi

    if [ -z "$aws_root" ]; then
        aws_root="/"
    fi

    aws_local_instancedata_get()
    {
        local url
        local aws_path="$1"

        if [ "$aws_path" = "/meta-data/public-keys/" ]; then
            echo '0/openssh-key'
            return 0
        elif [ "$aws_path" = "/" ]; then
            printf "dynamic/\nmeta-data/\nuser-data"
            return 0
        else
            url="http://169.254.169.254/latest$aws_path"
        fi

        if [ $(uname | grep -i linux | wc -l) -gt 0 ]; then
            # linux - depends on curl
            echo $(curl -s "$url" 2> /dev/null)
            return 0
        elif [ $(uname | grep -i freebsd | wc -l) -gt 0 ]; then
            # freebsd - depends on fetch
            echo $(fetch -q -o - "$url" 2> /dev/null)
            return 0
        fi

        return 1
    }

    aws_local_instancedata_walk()
    {
        local key
        local filename
        local local_path="$1"
        local aws_path="$2"

        for key in $(aws_local_instancedata_get "$aws_path"); do
            if [ $(echo -n $key | tail -c1) = "/" ]; then
                echo $(aws_local_instancedata_walk "$local_path" "$aws_path$key")
            else
                filename="$local_path$aws_path$key"
                mkdir -p $(dirname "$filename")
                echo $(aws_local_instancedata_get "$aws_path$key") > "$filename"
            fi
        done
    }

    # prevent obviously wrong or bad $local_path values that could cause bad things to happen below in `rm -Rf`
    if [ -z "$local_path" ] || [ "$local_path" = "/" ]; then
        echo "FATAL: bad $local_path value"
        exit 1
    fi
    rm -Rf "$local_path"
    mkdir -p "$local_path"

    aws_local_instancedata_walk "$local_path" "$aws_root"
}
