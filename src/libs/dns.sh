#!/usr/bin/env bash

function bruteDNS(){
    # shellcheck disable=SC2154
    local dns="${surl}"
    local ip1=""

    local dns_tld="$(echo "${dns}"    | cut -d . -f2)"
    local dns_domain="$(echo "${dns}" | cut -d . -f1)"

    local database_logs="$PWD/src/database/logs_database.db"

    declare -a querys_dns=(
        "A"
        "AAAA"
        "CNAME"
    )

    # shellcheck disable=SC2154
    local wordlist="${wordlist_dns}"

    cat <<EOF
    _                _ _            ____  _   _ ____  
   / \   _ __   __ _| (_)___  ___  |  _ \| \ | / ___| 
  / _ \ | '_ \ / _' | | / __|/ _ \ | | | |  \| \___ \ 
 / ___ \| | | | (_| | | \__ \  __/ | |_| | |\  |___) |
/_/   \_\_| |_|\__,_|_|_|___/\___| |____/|_| \_|____/ 
                                                                       
EOF
    
    if [[ ! -e "${wordlist}" ]]; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}O caminho da wordlist não foi especificado!${NUL}" >&2
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Utilizando a wordlist padrão...${NUL}" >&2
        wordlist="$PWD/src/wordlists/namelist.txt"
    fi

    # * NS Check
    while IFS= read -r ns1; do

        while IFS= read -r ip_ns; do 
            sqlite3 "$database_logs" "INSERT INTO dns_ns(ns, ip) VALUES ('$ns1', '$ip_ns');"
        done < <(host -t A "${ns1}" | awk '/has address/ {print $4}')

        echo -e "${WHITE}[${GREEN}+${WHITE}] Servidor de nomes: ${BLUE}${ns1}${NUL}"
    done < <(host -t ns "${dns}" | awk '/name server/ {print $4}')

    # * MX Check
    while IFS= read -r mx; do

        while IFS= read -r ip_mx; do 
            sqlite3 "$database_logs" "INSERT INTO dns_mx(mx, ip) VALUES ('$mx', '$ip_mx');"
        done < <(host -t A "${mx}" | awk '/has address/ {print $4}')

        echo -e "${WHITE}[${GREEN}+${WHITE}] Servidor de e-mail: ${BLUE}${mx}${NUL}"
    done < <(host -t mx "${dns}" | awk '/is handled/ {print $7}')

    # Brute force
    echo -e "\n${WHITE}[${GREEN}+${WHITE}] Iniciando teste de brute force de subdomínios${NUL}"

    # main
    if [[ "$dns" =~ ^([a-zA-Z0-9-]+\.){2,}[a-zA-Z]{2,}$ ]]; then
        echo -e "${WHITE}[${RED}!${WHITE}] O padrão de ${YELLOW}${dns}${WHITE} não atende aos requisitos!${NUL}"
    else
        while IFS= read -r subs; do
            
            [[ "${verbose_on:-0}" -eq 1 ]] && {
                echo -e "${WHITE}[${PURPLE}VERBOSE/DNS${WHITE}] Testando: ${YELLOW}$subs ${WHITE}|> ${BLUE}${dns_domain}.${dns_tld}${NUL}"
            }
            
            for query in "${querys_dns[@]}"; do
                case "$query" in
                    "A") fmsgquery="has address" ; awkf='$4' ;;
                    "AAAA") fmsgquery="has IPv6 address"; awkf='$5' ;;
                    "CNAME") fmsgquery="an alias" ; awkf='$6' ;;
                esac

                if result="$(host -t "$query" "${subs}.${dns}" 2>/dev/null)"; then
                    ip1="$(echo "${result}" | awk "/${fmsgquery}/ {print $awkf}")"

                    if [[ -n "${ip1}" ]]; then
                        echo -e "${WHITE}[${BLUE}DNS${WHITE}] ${BLUE}Encontrado ($query): ${WHITE}http://${YELLOW}${subs}.${CYAN}${dns_domain}.${dns_tld} ${WHITE}-> { ${GREEN}${ip1} ${WHITE}}${NUL}"
                    fi

                fi

            done

        done < "${wordlist}"
    fi

    # * Banco de dados
    while IFS= read -r ips; do
        sqlite3 "$database_logs" "INSERT INTO dns(domain, ip) VALUES ('$dns', '$ips');"
    done < <(host -t A "${dns}" | awk '/has address/ {print $4}')


    echo -e "\n${WHITE}[${GREEN}+${WHITE}] Iniciando testes nos servidores NS${NUL}"
    for ns in $(dig "${dns}" NS +short); do 
        dig @"$ns" "${dns}" AXFR
    done

    echo -e "\n${WHITE}[${GREEN}+${WHITE}] Iniciando teste de amplificação DDoS nos servidores NS${NUL}"
    for ns in $(dig "${dns}" NS +short);do
        hping3 --udp -c 10000 --data 1000 --faster "${ns}"
    done

    echo -e "\n${WHITE}[${GREEN}+${WHITE}] Iniciando teste de registro TXT${NUL}"
    host -t txt "$dns"

    while IFS= read -r txt; do
        sqlite3 "${database_logs}" "INSERT INTO dns_text(domain, txt) VALUES ('$dns','$txt')"
    done < <(host -t txt "$dns" | awk '/descriptive text/ {print $4}')

    echo -e "\n${WHITE}[${GREEN}+${WHITE}] Iniciando teste de registro SRV${NUL}"
    dnsrecon -t srv -d "$dns"

    echo -e "${WHITE}[${GREEN}+${WHITE}] Iniciando teste de registro SOA${NUL}"
    if ns2=$(dig "$dns" SOA +short | awk '{print $1}') 2>/dev/null; then 
        if [ -n "$ns2" ]; then
            dig @"$ns2" "$dns" AXFR 2>/dev/null
        else
            echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Não foi possível realizar o teste no registro SOA!${NUL}" >&2
        fi
    fi

}
