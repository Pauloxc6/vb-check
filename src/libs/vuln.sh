#!/usr/bin/env bash

export vuln_count=0

function vuln.smtp.userenum(){

    function loading() {
        printf "\r\e[K${PURPLE}[-] Brute Force / Subdomínio: ${WHITE}%s.${suburl}${NUL}" "$1"
        sleep 0.02s
    }

    local count=0
    local suburl="${surl}"

    declare -a subs=(
        smtp
        mail
        email
        inbox
        mx
        webmail
        mailserver
        mailhost
        smtps
        smtp-in
        imap
        imaps
        imap4
        pop
        pop3
        pops
        webmail
        mail-web
        exchange
        autodiscover
        mta
        mda
        msa
        mx1
        mx2
        mx-in
        postmaster
        mailer
        outbound
        inbound
        relay
        smarthost
        gate
        gateway
    )

    lenghtsubs="${#subs[@]}"
    subcount=0

    cat <<EOF
 __     __     _            _                _           _     
 \ \   / /   _| |_ __      / \   _ __   __ _| |_   _ ___(_)___ 
  \ \ / / | | | | '_ \    / _ \ | '_ \ / _' | | | | / __| / __|
   \ V /| |_| | | | | |  / ___ \| | | | (_| | | |_| \__ \ \__ \ 
    \_/  \__,_|_|_| |_| /_/   \_\_| |_|\__,_|_|\__, |___/_|___/
                                               |___/            
EOF

    local port=25
    local mode_attack="25"
    local wordlistsmtp="${rootdir}/src/wordlists/smtpusers.txt"

    function teste_mode(){
        # Array indexado simples
        local modes=("VRFY" "EXPN")

        for mode in "${modes[@]}"; do
            [[ "$verbose_on" -eq 1 ]] && echo -e "${WHITE}[${PURPLE}VERBOSE${WHITE}] ${BLUE}Testando o modo: ${WHITE}$mode${NUL}"

            # Captura a resposta, remove o banner 220 e pega o código de status (primeiros 3 dígitos)
            # 250/252 geralmente indicam sucesso no VRFY/EXPN
            response=$(ncat "$suburl" "$port" 2>/dev/null <<< "$mode root" | grep -v "^220" | head -n 1 | cut -c 1-3)

            if [[ "$response" =~ ^(250|252) ]]; then
                echo -e "${GREEN}[+] O servidor tem o modo ${WHITE}$mode ${GREEN}HABILITADO (Resposta: ${WHITE}$response${GREEN})${NUL}"
                mode_attack="${mode}"
                break
            else
                echo -e "${RED}[ERROR] O servidor tem o modo ${WHITE}$mode ${RED}DESABILITADO ou BLOQUEADO${NUL}"
                count=$(( count + 1)) 
                [[ "$count" == 2 ]] && { echo ; break ;}
            fi
        done
    }

    echo -e "${WHITE}[${GREEN}+${WHITE}] Iniciando o exploit : smtp.userenum${NUL}"
    sleep 1s

    if [[ -z "$surl" || -z "$wordlistsmtp" ]]; then
        echo -e "${RED}[ERROR] url ou wordlist não fornecidos!${NUL}"
        return 1
    fi

    echo -e "${WHITE}[${BLUE}+${WHITE}] ${BLUE}Carregando a wordlist${NUL}"
    sleep 1s

    if [[ ! -f "$wordlistsmtp" ]]; then
        echo -e "${RED}[ERROR] Wordlist não encontrada: ${WHITE}$wordlistsmtp${NUL}"
        return 1
    fi

    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Validando os dados${NUL}"
    sleep 1s

    if ! response=$(ncat -w 1 "$surl" "$port" <<< "QUIT" 2>/dev/null | grep -v "^(220|221)" | head -n 1 | cut -d " " -f 1); then
        echo -e "${RED}[ERROR] Porta ${WHITE}$port ${RED}desabilitada para o host ${WHITE}[${BLUE}${sub}.$surl${WHITE}]${NUL}"
        return 1
    fi

    if [[ ! "${response}" =~ ^(252|250) ]];then
        echo -e "${WHITE}[${PURPLE}+${WHITE}] ${PURPLE}Tentando bruteforce de subdominios de email${NUL}"
        for sub in "${subs[@]}"; do
            loading "${sub}"
            if host "${sub}"."${surl}" >/dev/null 2>&1; then 
                [[ "$(ncat -w 1 "${sub}"."${surl}" "$port" 2>&1 >/dev/null <<< "QUIT")" != "Ncat: TIMEOUT." ]] && {
                    suburl="${sub}.${surl}"
                    echo -e "\n${GREEN}[!] Porta ${WHITE}$port ${GREEN}habilitada para o host ${WHITE}[${BLUE}$suburl${WHITE}]${NUL}"
                    break
                }
                ((subcount++))
                [[ "${subcount}" -eq "${lenghtsubs}" ]] && { echo ; return 1; }
            fi
        done
    else
        echo -e "${GREEN}[ERROR] Porta ${WHITE}$port ${GREEN}habilitada para o host ${WHITE}[${BLUE}$surl${WHITE}]${NUL}"
        suburl="${surl}"
    fi

    if ! echo ; teste_mode; then return 1; fi

    if [[ "$ssl_on" == 1 ]] ;then
        if [[ "$port" -eq 465 ]];then
            CMD_PREFIX="ncat --ssl -q 1 $suburl $port"
        elif [[ "$port" -eq 587 ]];then
            CMD_PREFIX="openssl -starttls smtp -quiet -connect $suburl:$port"
        fi
    else
        CMD_PREFIX="ncat -q 1 -q 1 $suburl $port"
    fi

    while IFS= read -r payload; do
        [[ "$verbose_on" -eq 1 ]] && echo -e "${WHITE}[${PURPLE}VERBOSE${WHITE}] Testando: ${YELLOW}$payload@$suburl:$port${NUL}"

        response=$($CMD_PREFIX <<< "$mode_attack $payload" 2>/dev/null | grep -v "^(220|221)" | head -n 1 | cut -d " " -f 1)

        if [[ "$response" == "252" || "$response" == "250" ]]; then
            echo -e "${WHITE}[${GREEN}+${WHITE}] ${CYAN}Usuário encontrado: ${GREEN}$payload@$suburl:$port${NUL}"
            vuln_count=$((vuln_count + 1))
        fi
    done < "$wordlistsmtp"

}

function vuln.nuclei.scan(){

    echo -e "${WHITE}[${GREEN}+${WHITE}] Iniciando o exploit : nuclei${NUL}"
    sleep 1s

    if [[ "${ssl_on}" -eq 1 ]]; then
        local url="https://${surl}/${path}"
    else
        local url="http://${surl}/${path}"
    fi

    echo -e "${WHITE}[${BLUE}NUCLEI${WHITE}] ${BLUE}Iniciando teste em ${CYAN}${surl} com ${WHITE}nuclei${NUL}"
    sleep 1s

    echo -e "${WHITE}[${BLUE}NUCLEI${WHITE}] ${GREEN}Teste de vulnerabilidade baixas e médias${NUL}"
    local result=$(nuclei -tags vuln -silent -c 50 -rl 150 -severity low,medium -u "${url}")

    if [[ -z "${result}" ]]; then
        echo -e "${RED}[ERROR] Não foi possível determinar as vulnerabilidade!${NUL}"
    else
        echo "${result}"
        vuln_count=$((vuln_count + 1))
    fi

    echo -e "${WHITE}[${BLUE}NUCLEI${WHITE}] ${YELLOW}Teste de vulnerabilidade altas e críticas${NUL}"
    local result=$(nuclei -tags vuln -silent -c 50 -rl 150 -severity critical,high -u "${url}")

    if [[ -z "${result}" ]]; then
        echo -e "${RED}[ERROR] Não foi possível determinar as vulnerabilidade!${NUL}"
    else
        echo "${result}"
        vuln_count=$((vuln_count + 1))
    fi

    echo -e "${WHITE}[${BLUE}NUCLEI${WHITE}] ${RED}Teste de vulnerabilidade específicas${NUL}"
    local result=$(nuclei -tags sqli,xss,rce,lfi -silent -c 50 -rl 150 -severity critical,high -u "${url}")

    if [[ -z "${result}" ]]; then
        echo -e "${RED}[ERROR] Não foi possível determinar as vulnerabilidade!${NUL}"
    else
        echo "${result}"
        vuln_count=$((vuln_count + 1))
    fi

}

function vuln.javascript.scan(){

    echo -e "${WHITE}[${GREEN}+${WHITE}] Iniciando o exploit : javascript scan${NUL}"

    if [[ "${ssl_on}" -eq 1 ]]; then
        mapfile -t jsfiles < <(curl -sSL "https://${surl}/${path}" 2>/dev/null | grep -oE 'src="[^"]+\.js(\?[^"]*)?"'| sed 's/src="//; s/"//')
        
        if [[ -z "${jsfiles[*]}" ]]; then
            echo -e "${RED}[ERROR] Não foi possível extrair os aquirvos js!${NUL}"
        else
            for js in "${jsfiles[@]}"; do
                if [[ "$js" == \.* ]]; then
                    full_url="https://${surl}/${path}${js#\.}"
                elif [[ "${js}" == /* ]]; then
                    full_url="https://${surl}/${path}${js}"
                else
                    full_url="$js"
                fi
                
                echo "${WHITE}🔍 Baixando e analisando: ${RED}$full_url${NUL}"
                local result="$(semgrep scan -q --config=auto "$output_site/${surl}-file.js")"

                if curl -sSL "$full_url" -o "$output_site/${surl}-file.js"; then
                    if [[ "${result}" ]]; then
                        echo "${result}"
                        ((vuln_count++))
                    else
                        echo -e "${GREEN}[+] Url: ${WHITE}$full_url ${BLUE}| ${GREEN}Não Vulrável! ${NUL}"
                    fi
                else
                    echo -e "${RED}[+] Url: ${WHITE}$full_url ${BLUE}| ${RED}Não foi possível baixar! ${NUL}"
                fi
            done
        fi
    else 
        mapfile -t jsfiles < <(curl -sSL "http://${surl}/${path}" 2>/dev/null | grep -oE 'src="[^"]+\.js(\?[^"]*)?"' | sed 's/src="//; s/"//')

        if [[ -z "${jsfiles[*]}" ]]; then
            echo -e "${RED}[ERROR] Não foi possível extrair os aquirvos js!${NUL}"
        else  
            for js in "${jsfiles[@]}"; do
                if [[ "$js" == \.* ]]; then
                    full_url="http://${surl}/${path}${js#\.}"
                elif [[ "${js}" == /* ]]; then
                    full_url="http://${surl}/${path}${js}"
                else
                    full_url="$js"
                fi
                
                echo "${WHITE}🔍 Baixando e analisando: ${RED}$full_url${NUL}"
                if curl -sSL "$full_url" -o "$output_site/${surl}-file.js"; then
                    local result=$(semgrep scan -q --config=auto "$output_site/${surl}-file.js")

                    if [[ "${result}" ]]; then
                        echo "${result}"
                        ((vuln_count++))
                    else
                        echo -e "${GREEN}[+] Url: ${WHITE}$full_url ${BLUE}| ${GREEN}Não Vulrável! ${NUL}"
                    fi
                else
                    echo -e "${RED}[+] Url: ${WHITE}$full_url ${BLUE}| ${RED}Não foi possível baixar! ${NUL}"
                fi
            done
        fi
    fi
}

function vuln.subdomaintakeover.scan(){

    [[ "${dns_on}" == 0 ]] && { echo -e "${WHITE}[${BLUE}+${WHITE}] ${BLUE}Módulo dns desabalitado!${NUL}" ; return 1 ;}

    local subsfile="${rootdir}/src/exports/${surl}/subs.txt"

    echo -e "${WHITE}[${GREEN}+${WHITE}] Iniciando o exploit : subdomain.takeover${NUL}"

    if [ ! -f "${subsfile}" ]; then
        echo -e "${RED}[ERROR] O Arquivo ${WHITE}subs.txt ${RED}para ${WHITE}${surl} ${RED}nao foi criado!${NUL}"
        return 1
    fi

    if ! mapfile -t result < <(subzy r --hide_fails --vuln --targets "${subsfile}" | grep "VULNERABLE"); then
        echo -e "${RED}[ERROR] Falha ao executar o teste de subdomain takeover!${NUL}"
        return 1
    else
        for res in "${result[@]}";do
            local valid="$(echo "${res}" | awk '/VULNERABLE/ {print $2}')"
            local url="$(echo "${res}"   | awk '/VULNERABLE/ {print $5}')"
    
            if [[ "${valid}" && "${url}" ]]; then
                echo -e "${GREEN}[+] ${RED}${valid} ${YELLOW}|> ${WHITE}[ ${BLUEE}${url} ${WHITE}] ${NUL}"
                ((vuln_count++))
            fi
        done
    fi
}

function modat.cves.scan(){

    local fileenv="${rootdir}/.env"

    echo -e "${WHITE}[${GREEN}+${WHITE}] Iniciando o exploit : search.cves${NUL}"

    if [ ! -f "${fileenv}" ]; then
        echo -e "${RED}[ERROR] Arquivo ${fileenv} não existe!${NUL}"
        return 1
    fi

    local ip=$(host -t A "${surl}" | grep "has address" | head -n 1 | awk -F' ' '{print $4}')
    local apikeymodat="$(awk -F'=' '/APIKEY_MODAT/ {print $2}' "${fileenv}")"

    mapfile -t resultadojson < <(curl -s -X "GET" "https://api.magnify.modat.io/host/${ip}/v1" -H "accept: */*" -H "Authorization: Bearer ${apikeymodat}")

    for res in "${resultadojson[@]}"; do
        
        mapfile -t ports < <(echo "${res}" | jq -r '.data.services[].ports[]' | sort -u)

        for port in "${ports[@]}";do
            local protocol=$( echo "${res}" | jq -r ".data.services[]   | select(.ports[] == ${port}) | .protocol")
            local os=$( echo "${res}"       | jq -r ".data.services[]   | select(.ports[] == ${port}) | .fingerprints.os")
            mapfile -t cvesid  < <( echo "${res}"  | jq -r ".data.services[]   | select(.ports[] == ${port}) | .cves[].id" | sort -u)
            mapfile -t fingerprint < <(echo "${res}" | jq -r ".data.services[] | select(.ports[] == ${port}) | .fingerprints.technologies[].name" | sort -u)

            echo -e "
${WHITE}| Host: ${BLUE}${surl} ${WHITE}/ ${BLUE}${ip}
${WHITE}| Porta: ${GREEN}${port} ${WHITE}| Protocolo: ${CYAN}${protocol}
${WHITE}| OS: ${BLUE}${os}"
            echo -e "${WHITE}| Vulnerabilidades em potencial:"
            for id in "${cvesid[@]}"; do 
                echo -e "${WHITE}| ${RED}${id:-NULL}${NUL}"
                ((vuln_count++))
            done

            echo -e "${WHITE}| Fingerprint:"
            for id in "${fingerprint[@]}"; do 
                echo -e "${WHITE}| ${YELLOW}${id}${NUL}"
            done
        done
    done

}

function param.vuln.scan(){

    local count=0

    echo -e "${WHITE}[${GREEN}+${WHITE}] Iniciando o exploit : param.search${NUL}"

    if [[ "${ssl_on}" -eq 1 ]]; then
        local surl="https://${surl}"
    else
        local surl="http://${surl}"
    fi

    if ! mapfile -t params < <(parth -t "${surl}" 2>/dev/null | tail -n 30 ); then
        :
    fi

    for p in "${params[@]}"; do
        mapfile -t url < <(echo "${p}"      | awk -F' ' '/\+/ {print $2}')
        mapfile -t issue < <(echo "${p}"    | awk -F':' '/issues:/ {print $2}'   | tr -d '  ')
        mapfile -t location < <(echo "${p}" | awk -F':' '/location:/ {print $2}' | tr -d '  ')

        for u in "${url[@]}";do
            echo -e "+-----------------------------------------------------+"
            echo -e "${WHITE}| [${BLUE}${count}${WHITE}] Host: ${BLUE}${u}${NUL}"
        done
        
        for i in "${issue[@]}"; do
            echo -e "${WHITE}\ Vulnerabilidades em potencial: ${RED}${i}"
        done

        for l in "${location[@]}";do
            echo -e "${WHITE} | Local: ${CYAN}${l}${NUL}" 
            echo -e "+-----------------------------------------------------+"
        done

        ((count++))
    done

    mapfile -t param2 <  <(arjun -u "${surl}" | grep -v "Processing chunks" | grep "parameter detected")

    for p2 in "${param2[@]}"; do
        local param=$(echo "${p2}" | awk -F': ' '{print $2}' | awk -F', ' '{print $1}')
        local text=$(echo "${p2}" | awk -F': ' '{print $3}')

        case "${text}" in
            "param value reflection"|"param name reflection") text="Possível Vulnerabilidade de XSS!" ;;
            "redirection") text="Possível Open Redirect / SSRF!" ;;
            "http code") text="Possível Anomalia de Lógica ou Erro HTTP!" ;;
            "body length"|"text length"|"number of lines") text="Possível Injeção (SQLi / LFI) - Mudança no Corpo da Resposta!" ;;
        esac

        echo "${WHITE}[${GREEN}-${WHITE}] ${GREEN}?${param}= ${YELLOW}-> ${RED}${text}${NUL}"
    done
}

