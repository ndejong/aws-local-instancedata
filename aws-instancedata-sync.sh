#!/bin/sh

# Copyright (c) 2018 Nicholas de Jong <contact[at]nicholasdejong.com>
#  - All rights reserved.
#
# Apache License v2.0
#  - http://www.apache.org/licenses/LICENSE-2.0


AWS_INSTANCEDATA_LOCAL_PATH='/var/lib/cloud/instance/instance-data'


aws_instancedata_sync()
{
    aws_instancedata_aws_root=$1
    aws_instancedata_local_path=$2

    aws_instancedata_get()
    {
        if [ $1 == '/meta-data/public-keys/' ]; then
            echo '0/openssh-key'
            return 0
        elif [ $1 == '/' ]; then
            printf "dynamic/\nmeta-data/\nuser-data"
            return 0
        else
            url='http://169.254.169.254/latest'$1
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
        for key in $(aws_instancedata_get "$1"); do
            if [ $(echo -n $key | tail -c1) == '/' ]; then
                echo "$(aws_instancedata_walk $1$key)"
            else
                filename=$aws_instancedata_local_path$1$key
                mkdir -p "$(dirname $filename)"
                echo "$(aws_instancedata_get $1$key)" > "$filename"
            fi
        done
    }

    if [ -z $aws_instancedata_local_path ] || [ $aws_instancedata_local_path == '/' ]; then
        echo 'FATAL: bad $aws_instancedata_local_path value'
        exit 1
    fi
    rm -Rf "$aws_instancedata_local_path"
    mkdir -p "$aws_instancedata_local_path"

    aws_instancedata_walk "$aws_instancedata_aws_root"
}

aws_instancedata_sync "/" "$AWS_INSTANCEDATA_LOCAL_PATH"

