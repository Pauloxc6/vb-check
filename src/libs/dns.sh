#!/usr/bin/env bash

function getinfoip(){
        
        local api="http://ip-api.com/json"

        echo -e "${WHITE}[${BLUE}+${WHITE}] ${BLUE}Verficando a geo localização${NUL}"

        
        local cmd=$(curl -s "${api}/${surl}")

        local country="$( echo "${cmd}" | jq -r '.country' )"
        local state="$( echo "${cmd}" | jq -r '.regionName' )"
        local city="$( echo "${cmd}" | jq -r '.city' )"

        local lat="$( echo "${cmd}" | jq -r '.lat' )"
        local lon="$( echo "${cmd}" | jq -r '.lon' )"

        local isp="$( echo "${cmd}" | jq -r '.isp' )"
        local org="$( echo "${cmd}" | jq -r '.org' )"

        local ip="$( echo "${cmd}" | jq -r '.query' )"

        echo -e "
${WHITE}[ Host: ${GREEN}${surl} ${WHITE}-> IP: ${RED}${ip} ${WHITE}]
${WHITE}\
${WHITE}[ ${BLUE}${country} ${WHITE}| ${BLUE}${state} ${WHITE}| ${BLUE}${city} ${WHITE}]
${WHITE}[ ISP: ${BLUE}${isp} ${WHITE}/ ORG: ${BLUE}${org} ${WHITE}| ${BLUE}Lat: ${YELLOW}${lat} ${BLUE}Lon: ${YELLOW}${lon} ${WHITE}]
${RESET}"

        echo -e "${WHITE}Infomarções de conexão: ${YELLOW}"
        whois -h bgp.tools "${ip}"
        echo -e "${NUL}"
}


function bruteDNS(){
    # shellcheck disable=SC2154
    local dns="${surl}"
    local ip1=""

    # dns_tld="$(echo "${dns}" | cut -d'.' -f2)"
    # dns_domain="$(echo "${dns}" | cut -d'.' -f1)"

    local database_logs="$PWD/src/database/logs_database.db"

    declare -a querys_dns=(
        "A"
        "AAAA"
        "CNAME"
    )

    # shellcheck disable=SC2154
    local wordlist="${wordlist_dns}"

    local regex_ip='^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$'

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

    getinfoip

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
    if [[ "$dns" =~ $regex_ip ]]; then
        echo -e "${WHITE}[${RED}!${WHITE}] O padrão de ${YELLOW}${dns}${WHITE} não atende aos requisitos!${NUL}"
    else
        local count=0
        local lenghtword="$(wc -l < "${wordlist}")"
        while IFS= read -r subs; do
            
            [[ "${verbose_on:-0}" -eq 1 ]] && {
                echo -e "${WHITE}[${PURPLE}VERBOSE/DNS${WHITE}] Testando: ${YELLOW}$subs ${WHITE}|> ${BLUE}${surl}${NUL}"
            }
            
            for query in "${querys_dns[@]}"; do
            
                case "$query" in
                    "A") fmsgquery="has address" ; awkf='$4' ;;
                    "AAAA") fmsgquery="has IPv6 address"; awkf='$5' ;;
                    "CNAME") fmsgquery="an alias" ; awkf='$6' ;;
                esac

                # if mapfile -t result < <(host -t "$query" "${subs}.${dns}" 2>/dev/null); then

                #     for res in "${result[@]}"; do
                #         ip1="$(echo "${res}" | awk "/${fmsgquery}/ {print $awkf}")"

                #         if [[ -n "${ip1}" ]]; then
                #             echo -e "${WHITE}[${BLUE}DNS${WHITE}] ${BLUE}Encontrado ($query): ${WHITE}http://${YELLOW}${subs}.${CYAN}${surl} ${WHITE}-> { ${GREEN}${ip1} ${WHITE}}${NUL}"

                #             echo "${subs}.${surl}" >> "${rootdir}/src/exports/${surl}/subs.txt"
                #             count="$((count + 1))"
                #         fi
                #     done

                # fi

                result=$(host -t "$query" "${subs}.${dns}" 2>/dev/null)
                ip1="$(echo "${result}" | awk "/${fmsgquery}/ {print $awkf}")"

                if [[ -n "${ip1}" ]]; then
                    status=$(httpx -u "${subs}.${dns}" -status-code -silent </dev/null | awk -F' ' '{print $2}')
                    echo -e "${WHITE}[${BLUE}DNS${WHITE}] ${BLUE}Encontrado ($query)${NUL}${status}${BLUE}: ${WHITE}http://${YELLOW}${subs}.${CYAN}${surl} ${WHITE}-> { ${GREEN}${ip1} ${WHITE}}${NUL}"

                    echo "${subs}.${surl}" >> "${rootdir}/src/exports/${surl}/subs.txt"
                    count="$((count + 1))"
                fi

            done

        done < "${wordlist}"

        subdomains_count="${count}"

        echo -e "${WHITE}[${BLUE}DNS${WHITE}] ${CYAN}Total de subdomínios ${WHITE}${WHITE}${subdomains_count}/${lenghtword}${NUL}"
    fi

    if [[ "$dns" =~ $regex_ip ]]; then
        echo -e "${WHITE}[${BLUE}DNS${WHITE}] Iniciando pesquisa reserva de ip${NUL}"
        while IFS= read -r rips;do
            echo -e "${WHITE}[${BLUE}DNS${WHITE}] ${YELLOW}${dns} ${BLUE}-> ${GREEN}${rips}"
        done < <(host "$dns" | awk '/domain name/ {print $5}') || echo -e "${WHITE}[${BLUE}DNS${WHITE}] ${RED}Nenhum nome reverso encontrado!${NUL}"
    #    echo -e "${WHITE}[${RED}!${WHITE}] O padrão de ${YELLOW}${dns}${WHITE} não pode ser analisado!${NUL}"
    else 
        # * Banco de dados
        while IFS= read -r ips; do
            sqlite3 "$database_logs" "INSERT INTO dns(domain, ip) VALUES ('$dns', '$ips');"
        done < <(host -t A "${dns}" | awk '/has address/ {print $4}')


        echo -e "\n${WHITE}[${GREEN}+${WHITE}] Iniciando testes nos servidores NS${NUL}"
        for ns in $(dig "${dns}" NS +short | sed 's/\.$//'); do
            [[ -z "${ns}" ]] && { echo -e "${RED}[!] Não foi possível determinar o servidor ns!${NUL}" ; break ;} 
            if message=$( dig @"$ns" "${dns}" AXFR +short 2>&1 | head -n1 ); then
                [[ "$message" =~ "; Transfer failed" ]] && echo -e "${RED}${message} ${WHITE}-> ${BLUE}${ns}${WHITE}/${YELLOW}${dns}${NUL}"
                [[ "$message" =~ ";; communications error" ]] && echo -e "${RED}${message} ${WHITE}-> ${BLUE}${ns}${WHITE}/${YELLOW}${dns}${NUL}"
                [[ "$message" =~ ";; no servers" ]] && echo -e "${RED}${message} ${WHITE}-> ${BLUE}${ns}${WHITE}/${YELLOW}${dns}${NUL}"
            else
                echo "${message}"
            fi
        done

        echo -e "\n${WHITE}[${GREEN}+${WHITE}] Iniciando teste de amplificação DDoS nos servidores NS${NUL}"
        for ns in $(dig "${dns}" NS +short | sed 's/\.$//');do
            echo -ne "${WHITE}[${BLUE}-${WHITE}] ${BLUE}Testando servidor: ${GREEN}${ns} ${WHITE}|> ${PURPLE}"
            if [ "${ns}" ]; then
                nping --udp -c 10000 --data 1000 --rate 500 "${ns}" -p 53 2>/dev/null | grep -vE "SENT|Starting|Nping" | tr -d "\n" | sed "s/UDP/ | UDP/g"
            else
                echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Não foi possível realizar o teste de amplificação DDoS nos servidores NS!${NUL}" >&2
            fi
            echo -e "${NUL}"
        done

        echo -e "\n${WHITE}[${GREEN}+${WHITE}] Iniciando teste de registro TXT${NUL}"
        if ! message=$(host -t txt "$dns" 2>&1); then
            [[ "${message}" =~ ";; communications" ]] && echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Não foi possível se conectar com servidor DNS local em /etc/resolv.conf!${NUL}"
            echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Não foi possível determinar o registro TXT!${NUL}" >&2
        else
            echo "${message}"
        fi

        while IFS= read -r txt; do
            sqlite3 "${database_logs}" "INSERT INTO dns_text(domain, txt) VALUES ('$dns','$txt')"
        done < <(host -t txt "$dns" | awk '/descriptive text/ {print $4}')

        echo -e "\n${WHITE}[${GREEN}+${WHITE}] Iniciando teste de registro SRV${NUL}"
        if ! dnsrecon -t srv -d "$dns"; then
             echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Não foi possível determinar o registro SRV!${NUL}" >&2
        fi

        echo -e "${WHITE}[${GREEN}+${WHITE}] Iniciando teste de registro SOA${NUL}"
        if ! ns2=$(dig "$dns" SOA +short 2>/dev/null | awk '{print $1}' | sed 's/\.$//'); then 
            if [ -n "${ns2}" ]; then
                message="$(dig @"${ns2}" "$dns" AXFR +short 2>/dev/null)"
                [[ "$message" =~ "; Transfer failed" || "$message" =~ ^";; communications error" || "$message" =~ ^";; no servers" ]] &&  { 
                    echo -e "${RED}${message} ${WHITE}-> ${BLUE}${ns}${WHITE}/${YELLOW}${dns}${NUL}" 
                } || echo "${message}"
            else
                echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Não foi possível realizar o teste no registro SOA!${NUL}" >&2
            fi
        fi

    fi

    # Support Whois
    echo -e "\n${WHITE}[${GREEN}+${WHITE}] Iniciando analise whois${NUL}"
    whois "${surl}" | awk -F': ' '
/^Registrar WHOIS Server:/   {print "Server Whois :", $2}
/^Domain Name:/              {print "Domínio      :", $2}
/^Registrar:/                {print "Registrador  :", $2}
/^Creation Date:/            {print "Criado em    :", $2}
/^Updated Date:/             {print "Atualizado   :", $2}
/^Registry Expiry Date:/     {print "Expira em    :", $2}
/^Registrant Organization:/  {print "Empresa      :", $2}
/^Registrant Country:/       {print "País         :", $2}
/^Name Server:/              {print "DNS          :", $2}
/^Registrar Abuse Contact Email:/   {print "Email        :", $2}
/^Registrar Abuse Contact Phone:/   {print "Telefone     :", $2}
' || { echo -e "${RED}[!] Não foi possivel determinar a reposta para o whois!${NUL}" ; return 0 ;}

}
