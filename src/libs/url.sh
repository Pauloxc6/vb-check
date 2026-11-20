#!/usr/bin/env bash

function virustotal(){

    cat <<EOF
__     ___                _        _        _ 
\ \   / (_)_ __ _   _ ___| |_ ___ | |_ __ _| |
 \ \ / /| | '__| | | / __| __/ _ \| __/ _' | |
  \ V / | | |  | |_| \__ \ || (_) | || (_| | |
   \_/  |_|_|   \__,_|___/\__\___/ \__\__,_|_|

EOF

    local fileenv="${rootdir}/.env"

    if [ ! -f "${fileenv}" ]; then
        echo "${RED}[!] Arquivo ${fileenv} não existe!${NUL}"
        return 1
    fi

    local apikey="$(awk -F'=' '/APIKEY_VIRUSTOTAL/ {print $2}' "${fileenv}")"
    local id=$(curl -s --request POST \
     --url https://www.virustotal.com/api/v3/urls \
     --header 'accept: application/json' \
     --header 'content-type: application/x-www-form-urlencoded' \
     --header "x-apikey: ${apikey}" \
     --data-urlencode url="http://${surl}${path}" | jq -r '.data.id')


    local resultadojson="$(curl -s -X GET https://www.virustotal.com/api/v3/analyses/"${id}" -H "x-apikey: ${apikey}")"

    URL=$(echo "${resultadojson}" | jq -r '.meta.url_info.url')
    STATUS=$(echo "${resultadojson}" | jq -r '.data.attributes.status')
    SERVER=$(echo "${resultadojson}" | jq -r '.data.attributes.response_headers.Server')
    HARMLESS=$(echo "${resultadojson}" | jq -r '.data.attributes.stats.harmless')
    MALICIOUS=$(echo "${resultadojson}" | jq -r '.data.attributes.stats.malicious')
    TITLE=$(echo "${resultadojson}" | jq -r '.data.attributes.title')
    IP=$(echo "${resultadojson}" | jq -r '.data.attributes.resources[0].serving_ip_address')

    echo -e "${CYAN}=========================================${NUL}"
    echo -e "${PURPLE}       RELATÓRIO DE ANÁLISE DE URL       ${NUL}"
    echo -e "${CYAN}=========================================${NUL}"
    echo -e "${WHITE}🔗 URL Analisada :${NUL} ${BLUE}$URL${NUL}"
    echo -e "${WHITE}📌 Título da Página:${NUL} ${YELLOW}$TITLE${NUL}"
    echo -e "${WHITE}🌐 Servidor IP   :${NUL} ${GREEN}$IP${NUL} (${CYAN}$SERVER${NUL})"
    echo -e "${WHITE}⚙️ Status do Scan:${NUL} ${GREEN}$STATUS${NUL}"
    echo -e "${CYAN}-----------------------------------------${NUL}"
    echo -e "${WHITE}🛡️ Seguros (Harmless)   :${NUL} ${GREEN}$HARMLESS${NUL}"
    echo -e "${WHITE}🚨 Maliciosos (Malicious):${NUL} ${RED}$MALICIOUS${NUL}"
    echo -e "${CYAN}=========================================${NUL}"

}
