#!/usr/bin/env bash

function dirs(){

    # shellcheck disable=SC2154
    local wordlist="${wordlist_dirs}"

    cat <<EOF
 ____  _          
|  _ \(_)_ __ ___ 
| | | | | '__/ __|
| |_| | | |  \__ \\
|____/|_|_|  |___/

EOF

    echo -e "${WHITE}[${BLUE}DIRS${WHITE}] ${BLUE}Abrindo um novo terminal...${NUL}"
    
    if [[ ! -e "${wordlist}" ]]; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}O caminho da wordlist não foi especificado!${NUL}" >&2
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Utilizando a wordlist padrão...${NUL}" >&2
        wordlist="$PWD/src/wordlists/big2.txt"
    fi    

    # shellcheck disable=SC2154
    echo -e "${WHITE}[${BLUE}DIRS${WHITE}] ${BLUE}Testando: ${WHITE}http://${CYAN}${surl} ${WHITE}-> { ${GREEN}${wordlist} ${WHITE}}${NUL}"
    
    # shellcheck disable=SC2154
    gobuster dir -u "${surl}" -w "${wordlist}" -H "Cookie: $get_cookie" -x "php,txt,html,js,css,json,xml,sql,bak,backup,bkp,old,log,db,ini,conf,config" --random-agent --delay 500ms --no-tls-validation --status-codes-blacklist "404,403" --exclude-length 0 --threads 30 --quiet

    echo -e "${WHITE}[${BLUE}DIRS${WHITE}] Finalizando o teste...${NUL}"

    # ! Reseta o cookie depois que finaliza
    # shellcheck disable=SC2154
    sed -i "s/^cookie_gobuster=.*/cookie_gobuster=\"\"/" "$save_cookie"
}
