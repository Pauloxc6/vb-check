#!/usr/bin/env bash

function sslc(){

    # shellcheck disable=SC2154
    url="${surl}"

    cat <<EOF
 ____ ____  _     
/ ___/ ___|| |    
\___ \___ \| |    
 ___) |__) | |___ 
|____/____/|_____|
                  
EOF

    # Main
    sslscan "${url}" | grep -A5 -E "Protocol|Cipher|Certificate|Not valid" 2>/dev/null

    # Heartbleed Check
    result1="$(sslyze "${url}" --heartbleed | awk -F '  +' '/Heartbleed/ {print $2}')"
    result="${result1:1}"

    if [[ -n "${result}" ]]; then
        echo -e "${WHITE}[${GREEN}+${WHITE}] Heartbleed: ${BLUE}${result}${NUL}"
    else
        echo -e "${WHITE}[${RED}!${WHITE}] Heartbleed: ${RED}Não foi possível obter o resultado${NUL}"
    fi    

}