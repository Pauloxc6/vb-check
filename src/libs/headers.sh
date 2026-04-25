#!/usr/bin/env bash
#========================================================
# Arquivo de configuração
#========================================================

libs=( "./global.sh" "./colors.sh" "./tech.sh" )
for lib in "${libs[@]}"; do
    if [[ -f "${lib}" ]]; then
        # shellcheck disable=SC1090
        source "${lib}" > /dev/null 2>&1
    else
        echo -e "${WHITE}[${GREEN}!${WHITE}] ${RED}Erro ao importar a lib: ${WHITE}$lib${NUL}"
    fi
done

#========================================================
# Vars
#========================================================
# ! Proteção de erro no código
set -euo pipefail

# Otimização
export LC_ALL=C
export LANG=C

#=======================================
# Main
#=======================================

function check_headers(){

    config_file="$PWD/src/configs/headers.conf"
    database_logs="$PWD/src/database/logs_database.db"
    output_site="$HOMEDIR"
    output_file="$output_site/site.temp"
    current_version=""
    current_status=""
    current_location=""
    serverType=""
    cookie_original=""
    langType=""

    # Testa se o arquivo existe
    if [[ -f "${config_file}" ]]; then
        echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}O arquivo ${YELLOW}${config_file} ${GREEN}existe!${NUL}"
    else
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}O arquivo de configuração ${WHITE}${config_file} ${RED}não existe!${NUL}"
        exit 1
    fi

    # Testa se o diretório existe
    if [[ -d "${output_site}" ]]; then
        echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}O diretório ${YELLOW}${output_site} ${GREEN}foi criado com sucesso!${NUL}"
    else
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}O diretório ${WHITE}${output_site} ${RED}não existe!${NUL}"
        exit 1
    fi

    # Testa se está ativado o SSL
    # shellcheck disable=SC2154
    if [[ "${ssl_on:-0}" == 1 ]]; then     
        if __check_ssl; then
            curl -s -I -L --max-time 10 "https://${surl}" > "$output_file"
        fi
    else
        curl -s -I -L --max-time 10 "http://${surl}" > "$output_file"
    fi

    cat <<EOF
 ____                                  
| __ )  __ _ _ __  _ __   ___ _ __ ___ 
|  _ \ / _' | '  \| '_ \ / _ \ '__/ __|
| |_) | (_| | | | | | | |  __/ |  \__ \\
|____/ \__,_|_| |_|_| |_|\___|_|  |___/

EOF
    echo -e "\n${WHITE}[${GREEN}+${WHITE}] Iniciando captura de banners${NUL}"

    while read -r line; do
        line=$(echo "$line" | tr -d '\r')

        if [[ "$line" =~ ^HTTP/ ]]; then
            if [[ -n "$current_version" ]]; then
                echo -e "${WHITE}[${BLUE}-${WHITE}] ${CYAN}HTTP: ${WHITE}${current_version:-NULL} ${CYAN}| Status: ${WHITE}${current_status:-NULL} ${CYAN}| Location: ${WHITE}${current_location:-NULL}${NUL}"
            fi

            current_version=$(echo "$line" | awk '{print $1}')
            current_status=$(echo "$line" | awk '{print $2}')
            current_location="NULL"

        elif [[ "$line" =~ ^[Ll]ocation: ]]; then
            current_location=$(echo "$line" | cut -d ":" -f2- | xargs)
        fi

    done < "$output_file"

    # imprime o último
    if [[ -n "$current_version" ]]; then
        echo -e "${WHITE}[${BLUE}-${WHITE}] ${CYAN}HTTP: ${WHITE}${current_version:-NULL} ${CYAN}| Status: ${WHITE}${current_status:-NULL} ${CYAN}| Location: ${WHITE}${current_location:-NULL}${NUL}"
    fi

    # Identifica o tipo de servidor
    while IFS= read -r serverType; do
        echo -e "${WHITE}[${BLUE}-${WHITE}] ${CYAN}Servidor: ${WHITE}${serverType:-NULL}${NUL}"
    done < <(grep -i "^server:" "${output_file}" | cut -d ' ' -f2)

    # Identifica a linguagem de programação
    while IFS= read -r langType; do 
        echo -e "${WHITE}[${BLUE}-${WHITE}] ${CYAN}Linguagem: ${WHITE}${langType:-NULL}${NUL}"
    done < <(grep -i "^x-powered-by:" "$output_file" | cut -d ":" -f2-)
    
    # Identifica o cookie
    grep -i "^set-cookie:" "$output_file" | while read -r line; do
        cookie=$(echo "$line" | tr -d '\r' | cut -d ":" -f2- | xargs)
        cookie_original="$cookie"
        cookie_formatted="${cookie,,}"

        [[ -z "${cookie}" ]] && continue

        echo -e "${WHITE}[${BLUE}-${WHITE}] ${CYAN}Cookie: ${WHITE}${cookie_original:-NULL}${NUL}"

        [[ "$cookie_formatted" == *"secure"* ]]   && echo -e "   ${WHITE}[${GREEN}+${WHITE}] ${GREEN}Secure${NUL}"
        [[ "$cookie_formatted" == *"httponly"* ]] && echo -e "   ${WHITE}[${GREEN}+${WHITE}] ${GREEN}HttpOnly${NUL}"
        [[ "$cookie_formatted" == *"samesite"* ]] && echo -e "   ${WHITE}[${GREEN}+${WHITE}] ${GREEN}SameSite${NUL}"

        [[ "$cookie_formatted" != *"secure"* ]]   && echo -e "   ${WHITE}[${RED}!${WHITE}] ${RED}Sem Secure${NUL}"
        [[ "$cookie_formatted" != *"httponly"* ]] && echo -e "   ${WHITE}[${RED}!${WHITE}] ${RED}Sem HttpOnly${NUL}"

    done || echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Cookie não encontrado!${NUL}"

    # WAF Check
    waf_check

    # Save logs in database
    # shellcheck disable=SC2154
    [[ "${verbose_on}" == 1 ]] && {
        echo -e "${WHITE}[${PURPLE}VERBOSE${WHITE}] ${BLUE}Salvando os logs no banco de dados...${NUL}"
    }

    sqlite3 -cmd ".parameter set @url '${surl}'" "${database_logs}" \
    "INSERT INTO logs_headers(nome, servidor, linguagem, http_version, cookie, waf) 
    VALUES ('@url', '${serverType:-NULL}', '${langType:-NULL}', '${current_version:-NULL}', '${cookie_original:-NULL}', '${detected_waf:-NULL}')"

    # Headers
    cat <<EOF

  ____            _             _     _   _                    _     
 / ___|___  _ __ | |_ ___ _ __ | |_  | | | | ___  __ _ _ __ __| |___ 
| |   / _ \| '_ \| __/ _ \ '_ \| __| | |_| |/ _ \/ _' | '__/ _' / __|
| |__| (_) | | | | ||  __/ | | | |_  |  _  |  __/ (_| | | | (_| \__ \\
 \____\___/|_| |_|\__\___|_| |_|\__| |_| |_|\___|\__,_|_|  \__,_|___/

EOF

    echo -e "\n${WHITE}[${GREEN}+${WHITE}] Iniciando a análise de headers HTTP${NUL}"

    while IFS= read -r head; do
        header_name="$(echo "$head" | cut -d ":" -f1 | tr -d '"')"
        header_desc="$(echo "$head" | cut -d ":" -f2 | tr -d '"')"

        if grep -iq "^$header_name:" "$output_file"; then
            echo -e "${WHITE}[${YELLOW}V${WHITE}] [ ${BLUE}$header_name ${WHITE}] -----> ${YELLOW}$header_desc${NUL}"
        else
            echo -e "${WHITE}[${RED}X${WHITE}] [ ${BLUE}$header_name ${WHITE}] -----> ${YELLOW}$header_desc${NUL}"
        fi
    done < "$config_file"

}
