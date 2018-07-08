#!/bin/sh

# Copyright (c) 2018 Nicholas de Jong <contact[at]nicholasdejong.com>
#  - All rights reserved.
#
# Apache License v2.0
#  - http://www.apache.org/licenses/LICENSE-2.0


AWS_INSTANCEDATA_LOCAL_DEFAULT="/var/lib/cloud/instance/instance-data"


aws_instancedata_sync()
{
    local local_path="$1"
    local aws_root="$2"

    # NB: defaults dealt with in long-hand because using {} approach causes Terraform to (attempt to) interpolate

    if [ -z "$local_path" ]; then
        local_path="$AWS_INSTANCEDATA_LOCAL_DEFAULT"
    fi

    if [ -z "$aws_root" ]; then
        aws_root="/"
    fi

    aws_instancedata_get()
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
            echo $(curl -s "$url" 2> /dev/null)
            return 0
        elif [ $(uname | grep -i freebsd | wc -l) -gt 0 ]; then
            echo $(fetch -q -o - "$url" 2> /dev/null)
            return 0
        fi

        return 1
    }

    aws_instancedata_walk()
    {
        local key
        local filename
        local local_path="$1"
        local aws_path="$2"

        for key in $(aws_instancedata_get "$aws_path"); do
            if [ $(echo -n $key | tail -c1) = "/" ]; then
                echo $(aws_instancedata_walk "$local_path" "$aws_path$key")
            else
                filename="$local_path$aws_path$key"
                mkdir -p $(dirname "$filename")
                echo $(aws_instancedata_get "$aws_path$key") > "$filename"
            fi
        done
    }

    if [ -z "$local_path" ] || [ "$local_path" = "/" ]; then
        echo "FATAL: bad $local_path value"
        exit 1
    fi
    rm -Rf "$local_path"
    mkdir -p "$local_path"

    aws_instancedata_walk "$local_path" "$aws_root"
}

aws_instancedata_sync
