#!/usr/bin/env bash

function email(){

    local fileenv="${rootdir}/.env"

    if [ ! -f "${fileenv}" ]; then
        echo -e "${RED}[!] Arquivo ${fileenv} não existe!${NUL}"
        return 1
    fi

    mapfile -t getemail < <(curl -sSL "http://${surl}${path}" | grep -oE 'mailto:[^"]+(\?[^"]*)?' | awk -F: '{ print $2 }')

    local apikeyipqs="$(awk -F'=' '/APIKEY_IPQS/ {print $2}' "${fileenv}")"
    
    for mail in "${getemail[@]}"; do
    
        local resultadojson="$(curl -s -X GET "https://www.ipqualityscore.com/api/json/email/${apikeyipqs}/${getemail}")"

        STATUS=$(echo "${resultadojson}" | jq -r '.success')
        VALID=$(echo "${resultadojson}" | jq -r '.valid')
        UNSAFE=$(echo "${resultadojson}" | jq -r '.domain_trust')
        HONEYPOT=$(echo "${resultadojson}" | jq -r '.honeypot')
        LEAKED=$(echo "${resultadojson}" | jq -r '.phishing')
        SUSPICIOUS=$(echo "${resultadojson}" | jq -r '.suspect')
        MXRECORDS=$(echo "${resultadojson}" | jq -r '.mx_records[]')
        DISPOSABLE=$(echo "${resultadojson}" | jq -r '.disposable')
        DELIVERABILITY=$(echo "${resultadojson}" | jq -r '.deliverability')

        FRAUDESOCRE=$(echo "${resultadojson}" | jq -r '.fraud_score')
        OVERALLSOCRE=$(echo "${resultadojson}" | jq -r '.overall_score')

        echo -e "${CYAN}=========================================${NUL}"
        echo -e "${PURPLE}       RELATÓRIO DE ANÁLISE DE E-MAIL  ${NUL}"
        echo -e "${CYAN}=========================================${NUL}"
        echo -e "${WHITE} URL Analisada  :${NUL} ${BLUE}$surl${NUL}"
        echo -e "${WHITE} Email Analisado:${NUL} ${BLUE}$mail / ${FRAUDESOCRE} / ${OVERALLSOCRE} / ${DELIVERABILITY} ${NUL}"
        echo -e "${WHITE} Válido         :${NUL} ${BLUE}$VALID${NUL}"
        echo -e "${WHITE} Status do Scan :${NUL} ${GREEN}$STATUS${NUL}"
        echo -e "${CYAN}-----------------------------------------${NUL}"
        echo -e "${WHITE}🛡️ Seguros               :${NUL} ${GREEN}$UNSAFE${NUL}"
        echo -e "${WHITE}🚨 Hoenypot              :${NUL} ${RED}$HONEYPOT${NUL}"
        echo -e "${WHITE}🚨 Vazamento             :${NUL} ${RED}$LEAKED${NUL}"
        echo -e "${WHITE}🚨 Descartável           :${NUL} ${RED}$DISPOSABLE${NUL}"
        echo -e "${WHITE}🚨 Suspeito              :${NUL} ${RED}$SUSPICIOUS${NUL}"
        echo -e "${CYAN}-----------------------------------------${NUL}"
        echo -e "${WHITE} Servidores de e-mail :${NUL} ${BLUE}$MXRECORDS${NUL}"
        echo -e "${CYAN}=========================================${NUL}"
    done

    local apikeyleakcheck="$(awk -F'=' '/APIKEY_LEAKCHECK/ {print $2}' "${fileenv}")"

    for mail in "${getemail[@]}"; do

        local resultadojson="$(curl -s -X GET "https://leakcheck.io/api/v2/query/${mail}?key=${apikeyleakcheck}")"
        
        STATUS=$(echo "${resultadojson}" | jq -r '.success')
        FOUND=$(echo "${resultadojson}" | jq -r '.found')
        
        # Como .result é um array, pegamos o primeiro item ([0]) ou iteramos
        NAMELEAK=$(echo "${resultadojson}" | jq -r '.result[0].source.name // "N/A"')
        BREACHDATE=$(echo "${resultadojson}" | jq -r '.result[0].source.breach_date // "N/A"')
        PASSWORDLESS=$(echo "${resultadojson}" | jq -r '.result[0].source.passwordless // "N/A"')
        USERNAME=$(echo "${resultadojson}" | jq -r '.result[0].username // "N/A"')
        PASSWORD=$(echo "${resultadojson}" | jq -r '.result[0].password // "N/A"')

        FIRSTNAME=$(echo "${resultadojson}" | jq -r '.result[0].first_name // "N/A"')
        LASTNAME=$(echo "${resultadojson}" | jq -r '.result[0].last_name // "N/A"')
        FULLNAME="$FIRSTNAME $LASTNAME"
        DOB=$(echo "${resultadojson}" | jq -r '.result[0].dob // "N/A"')
        ADDRESS=$(echo "${resultadojson}" | jq -r '.result[0].address // "N/A"')
        ZIPCODE=$(echo "${resultadojson}" | jq -r '.result[0].zip // "N/A"')
        PHONE=$(echo "${resultadojson}" | jq -r '.result[0].phone // "N/A"')

        # Nota: LeakCheck foca em vazamentos. Se a sua API misturar dados de FraudScore de outro provedor, 
        # mantemos a busca segura com fallback caso não venham no JSON do LeakCheck:
        FRAUDESCORE=$(echo "${resultadojson}" | jq -r '.fraud_score // .result[0].fraud_score // "N/A"')
        OVERALLSCORE=$(echo "${resultadojson}" | jq -r '.overall_score // .result[0].overall_score // "N/A"')

        echo -e "${CYAN}=========================================${NUL}"
        echo -e "${PURPLE}       RELATÓRIO DE ANÁLISE DE VAZAMENTO  ${NUL}"
        echo -e "${CYAN}=========================================${NUL}"
        echo -e "${WHITE} URL Analisada  :${NUL} ${BLUE}$surl${NUL}"
        echo -e "${WHITE} Email Analisado:${NUL} ${BLUE}$mail${NUL}"
        echo -e "${WHITE} Status do Scan :${NUL} ${GREEN}$STATUS${NUL}"
        echo -e "${CYAN}-----------------------------------------${NUL}"
        echo -e "${WHITE}🛡️ Fraud Score          :${NUL} ${YELLOW}$FRAUDESCORE${NUL}"
        echo -e "${WHITE}📊 Overall Score        :${NUL} ${YELLOW}$OVERALLSCORE${NUL}"
        echo -e "${CYAN}-----------------------------------------${NUL}"
        echo -e "${WHITE}👤 Nome Completo       :${NUL} ${BLUE}$FULLNAME${NUL}"
        echo -e "${WHITE}🎂 Data de Nasc.       :${NUL} ${BLUE}$DOB${NUL}"
        echo -e "${WHITE}📞 Telefone            :${NUL} ${BLUE}$PHONE${NUL}"
        echo -e "${WHITE}🏠 Endereço            :${NUL} ${BLUE}$ADDRESS (CEP: $ZIPCODE)${NUL}"
        echo -e "${CYAN}-----------------------------------------${NUL}"
        echo -e "${WHITE}🔍 Vazamento (Fonte)   :${NUL} ${RED}$NAMELEAK${NUL}"
        echo -e "${WHITE}📅 Data do Vazamento   :${NUL} ${YELLOW}$BREACHDATE${NUL}"
        echo -e "${WHITE}👤 Username Encontrado :${NUL} ${BLUE}$USERNAME${NUL}"
        echo -e "${WHITE}🔑 Senha Encontrada    :${NUL} ${RED}$PASSWORD${NUL}"
        echo -e "${CYAN}-----------------------------------------${NUL}"
        echo -e "${WHITE} Registros Encontrados :${NUL} ${BLUE}$FOUND${NUL}"
        echo -e "${CYAN}=========================================${NUL}"
    done
}