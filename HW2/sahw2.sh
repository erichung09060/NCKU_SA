usage() {
    echo -e "\nUsage: sahw2.sh {--sha256 hashes ... | --md5 hashes ...} -i files ...\n\n--sha256: SHA256 hashes to validate input files.\n--md5: MD5 hashes to validate input files.\n-i: Input files."
}

sha256=false
md5=false
hashVal=()
fileName=()

while [[ $# != 0 ]]; do
    if [ $1 == "-h" ]; then
        usage
        exit 0
    elif [ $1 == "--sha256" ]; then
        sha256=true
        shift
        while [[ $# != 0 && ! $1 =~ ^- ]]; do
            hashVal+=($1)
            shift
        done
    elif [ $1 == "--md5" ]; then
        md5=true
        shift
        while [[ $# != 0 && ! $1 =~ ^- ]]; do
            hashVal+=($1)
            shift
        done
    elif [ $1 == "-i" ]; then
        shift
        while [[ $# != 0 && ! $1 =~ ^- ]]; do
            fileName+=($1)
            shift
        done
    else
        echo -e "Error: Invalid arguments." 1>&2
        usage
        exit 1
    fi
done

if $sha256 && $md5; then
    echo "Error: Only one type of hash function is allowed." 1>&2
    exit 1
elif [ ${#fileName[@]} != ${#hashVal[@]} ]; then
    echo "Error: Invalid values." 1>&2
    exit 1
fi

fileNumber=${#fileName[@]}

for ((i = 0; i < $fileNumber; i++)); do
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

User=()
Password=()
Shell=()
Groups=()

for ((t = 0; t < $fileNumber; t++)); do
    FileType=$(file ${fileName[$t]} | cut -d ' ' -f 2)

    if [ $FileType == "CSV" ]; then
        line=0
        while IFS=',' read user password shell groups; do
            if [[ $((++line)) == 1 ]]; then continue; fi
            User+=($user)
            Password+=($password)
            Shell+=($shell)
            Groups+=("$groups")
        done < ${fileName[$t]}

    elif [ $FileType == "JSON" ]; then
        User+=($(jq -r ".[] | .username" ${fileName[$t]}))
        Password+=($(jq -r ".[] | .password" ${fileName[$t]}))
        Shell+=($(jq -r ".[] | .shell" ${fileName[$t]}))
        group_tmp=$(jq -r ".[] | .groups" ${fileName[$t]})
        groups=""
        for i in $(echo $group_tmp | sed s/[\",]//g); do 
            if [[ $i == "[]" ]]; then
                Groups+=("")
            elif [[ $i == "]" ]]; then
                Groups+=("$groups")
                groups=""
            elif [[ $i == "[" ]]; then
                continue
            else
                groups="$groups $i"
            fi
        done
    else
        echo "Error: Invalid file format." 1>&2
        exit 1
    fi
done

userNumber=${#User[@]}

echo -n "This script will create the following user(s):" ${User[@]} "Do you want to continue? [y/n]:"
read reply

if [[ $reply == "n" || $reply == "" ]]; then
    exit 0
fi

for ((i = 0; i < $userNumber; i++)); do
    if id ${User[$i]} &>/dev/null; then
        echo "Warning: user ${User[$i]} already exists."
        continue
    fi
    
    if [[ ${Groups[$i]} == "" ]]; then
        sudo pw useradd ${User[$i]} -s ${Shell[$i]}
        echo ${Password[$i]} | sudo pw mod user ${User[$i]} -h 0
    else
        for j in ${Groups[$i]}; do
            sudo pw addgroup $j >/dev/null 2>&1
        done
        Groups[$i]=$(echo ${Groups[$i]} | sed "s/ /,/g")
        sudo pw useradd ${User[$i]} -s ${Shell[$i]} -G ${Groups[$i]}
        echo ${Password[$i]} | sudo pw mod user ${User[$i]} -h 0
    fi
done