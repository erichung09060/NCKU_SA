# #!/usr/local/bin/bash.
#!/bin/bash

usage() {
    echo -e "Usage: sahw2.sh {--sha256 hashes ... | --md5 hashes ...} -i files ...\n\n--sha256: SHA256 hashes to validate input files.\n--md5: MD5 hashes to validate input files.\n-i: Input files."
}

sha256=false
md5=false

until [ $# -eq 0 ]; do
    if [ $1 == "-h" ]; then
        usage
        exit 0
    elif [ $1 == "--sha256" ]; then
        sha256=true
        shift
    elif [ $1 == "--md5" ]; then
        md5=true
        shift
    elif [ $1 == "-i" ]; then

        shift
    elif [ $(echo $1 | cut -c1-1) == "-" ]; then
        echo "Error: Invalid arguments.\n" 2>&1
        usage
        exit 1
    else
        echo "Error: Invalid values." 2>&1
        exit 1
    fi
    
    if $sha256 && $md5; then
        echo "Error: Only one type of hash function is allowed." 2&>1
        exit 1
    fi

    shift
done



