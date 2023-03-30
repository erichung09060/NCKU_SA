# #!/usr/local/bin/bash.
#!/bin/bash

usage() {
    echo -e "\nUsage: sahw2.sh {--sha256 hashes ... | --md5 hashes ...} -i files ...\n\n--sha256: SHA256 hashes to validate input files.\n--md5: MD5 hashes to validate input files.\n-i: Input files."
}

sha256=false
md5=false
hashVal=()
fileName=()
curType=""

until [ $# -eq 0 ]; do
    if [ $1 == "-h" ]; then
        usage
        exit 0
    elif [ $1 == "--sha256" ]; then
        sha256=true
        curType="hash"
    elif [ $1 == "--md5" ]; then
        md5=true
        curType="hash"
    elif [ $1 == "-i" ]; then
        curType="file"
    elif [ ${1:0:1} == "-" ]; then
        echo -e "Error: Invalid arguments." 1>&2
        usage
        exit 1
    elif $sha256 && $md5; then
        echo "Error: Only one type of hash function is allowed." 1>&2
        exit 1
    elif [ $curType == "file" ]; then
        fileName+=($1)
    elif [ $curType == "hash" ]; then
        hashVal+=($1)
    fi
    shift
done

if [ ${#fileName[@]} != ${#hashVal[@]} ]; then
    echo "Error: Invalid values." 1>&2
    exit 1
fi

N=${#fileName[@]}

for ((i = 0; i < $N; i++)); do
    if $md5; then
        hash=$(md5sum ${fileName[i]} | cut -d ' ' -f 1)
    else
        hash=$(sha256sum ${fileName[i]} | cut -d ' ' -f 1)
    fi

    if [ $hash != ${hashVal[$i]} ]; then
        echo "Error: Invalid checksum." 1>&2
        exit 1
    fi
done

#  cat data.json | jq -r ".[] | .username"
User=""
for ((i = 0; i < $N; i++)); do
    Content=$(file ${fileName[$i]} | cut -d ' ' -f 2)

    if [ $Content == "CSV" ]; then
        User="$User $(awk -F ',' '{if (NR!=1) print $1}' ${fileName[$i]})"

    elif [ $Content == "JSON" ]; then
        User="$User $(cat ${fileName[$i]} | jq -r ".[] | .username")"
    else
        echo "Error: Invalid file format." 1>&2
        exit 1
    fi
done

echo -n "This script will create the following user(s):" $User "Do you want to continue? [y/n]:"
read reply
if [[ $reply == "n" || $reply == "" ]]; then
    exit 0
fi
