#!/usr/bin/env bash
#========================================================
# Vars e Globas
#========================================================

export LC_ALL=C
export LANG=C

export cookie1="$1"
export save_cookie="$PWD/src/configs/http.conf"
export get_cookie=""

#========================================================
# Menu de ajuda
#========================================================

function __help__(){

cat <<HELP
Menu de ajuda

Essa é uma ferramenta de analise de sites, feitos com i.a.
O intuito é coletar informações e fazer testes basicos de segurança em aplicações viber coder.

Argumentos:
    Padrão
    --help      - Mostra o menu de ajuda
    -d          - Ativa visualização do modo debugger
    -v          - Ativa o modo verbose

    Geral
    --url           - Utiliza a url passada (Ex: google.com)
    --ssl           - Ativa o modo ssl
    --ignore-icmp   - Utilize para ignorar o icmp, quando houver regras de firewall bloqueando o icmp
                      (Algumas funcionalidades podem não ficar muito precisas)
    --cookie        - Utilize para setar o cookie para dar bypass em firewalls
    --dns-wordlist, -dw  - Utilize para setar a wordlist para o brute force de subdomínios
    --dir-wordlist, -diw - Utilize para setar a wordlist para o brute force de diretórios
    
    Clonagem
    --clone      - Utilize para clonagem de um website (Ex: --url google.com --clone)
    --view-clone - Utilize para visualizar a clonagem de um website

    Remove
    --remove-all-exports, -rae    - Utilize para remover todas as exportações
    --remove-export               - Utilize para remover uma exportação específica

    Database
    --export-db, -eb              - Utilize para exporta todos dos dados do banco de dados

    Vulnerabilidade
    --vuln  - Ativa o escaneamento de vulnerabilidade para o host

    Outros:
    --disable <item>  Desativa escaneamento específico ou em lote.
                      Valores aceitos:
                        all, net, sec, org, recon, threat
                        lista: "dns,dirs,email,vuln,url"

Exemplos de uso:

bash $0 --url google.com
HELP

}

#========================================================
# Debugger
#========================================================

function debuger(){
    
    # shellcheck disable=SC2329
    function cleanup(){
        set +x
        echo -e "${WHITE}------------------------------
[D] Finalizando o modo debug!
------------------------------${NUL}"
    }

    echo -e "${WHITE}------------------------------
[D] Iniciando o modo debug!
------------------------------${NUL}
    "
    set -x

    trap cleanup EXIT
}

#========================================================
# Clean URI
#========================================================

function cleanuri(){

    if [[ ! "$surl" =~ ^https?://([a-zA-Z0-9.-]+)+(/[a-zA-Z0-9_.~%?&/=-]*)?$ ]]; then
        echo "${RED}[!] A url ${surl} não atende os padrões! Utilize http:// ou https:// ${NUL}"
        exit 1
    fi

    local source_formated="${surl//\:\/\// }"
    surl=$(echo "${source_formated}" | sed 's/\// /g' | cut -d " " -f2)
    path=$(echo "${source_formated}" | sed 's/\// /g' | cut -d " " -f3)
}

#========================================================
# FIltaer Disable
#========================================================

function disbalefunctions(){
    
    local filter="$1"
    mapfile -t pattern < <( echo -e "${filter//\,/\\n}" )

    case "${pattern[*]}" in
        all) export dirs_on=0 dns_on=0 email_on=0 url_on=0 vuln_on=0 ;;
        net) export dns_on=0 url_on=0 ;;
        sec) export dirs_on=0 vuln_on=0 ;;
        org) export email_on=0 ;;
        recon) export dirs_on=0 dns_on=0 email_on=0 url_on=0 ;;
        threat) export vuln_on=0 ;; 
    esac

    for disable in "${pattern[@]}"; do
        export "${disable}"_on=0
    done
}

#========================================================
# Check Connection
#========================================================

function ctest(){

    if [[ -z "$surl" ]]; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Erro! O conteúdo da variável parece estar vazio!${NUL}"
        return 1
    fi

    # shellcheck disable=SC2154
    if [[ "${ignore_icmp}" == 1 ]]; then
        echo -e "${WHITE}[${YELLOW}!${WHITE}] ${YELLOW}Teste de conexão ignorado${NUL}"
        return 0
    fi

    # Teste um
    echo -e "${WHITE}[${PURPLE}*${WHITE}] ${BLUE}Iniciando teste de conexão 1${NUL}"
    if ! wget -q --spider "http://${surl}" 2>/dev/null; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Conexão mau-sucedida!${NUL}"
        return 1
    fi

    # Teste dois
    echo -e "${WHITE}[${PURPLE}*${WHITE}] ${BLUE}Iniciando teste de conexão 2${NUL}"
    if ! ping -c 1 "${surl}" >/dev/null 2>&1; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}[-] Conexão mau-sucedida!${NUL}"
        return 1
    fi

}

#========================================================
# Check Connection Ssl
#========================================================

function __check_ssl(){

    local host="${surl}"

    status_port="$(nmap --open -p 443,8443,9443 "${host}" | grep "open" | cut -d " " -f 2)"

    if [[ "${status_port:-close}" == "open" ]]; then
        echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}SSL Ativado para o host: ${WHITE}${host}${NUL}"
    else
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Não foi possivel estabelecer uma conexão ssl!${NUL}"
    fi

}

#========================================================
# Removes
#========================================================

function __remove_all_exports(){
    local dirs="$PWD/src/exports"

    if [[ ! -d "$dirs" ]]; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}O diretório ${WHITE}${dirs} ${RED}não existe!${NUL}"
        return 1
    fi

    echo -e "${WHITE}[${BLUE}*${WHITE}] ${YELLOW}Conteúdo a ser removido: ${RED}${dirs}/*${NUL}"
    read -rp $'\033[31;1mDeseja remover todos? [s/n]: \033[0m' opt

    case "${opt,,}" in  # 👈 lowercase automático
        s|sim)
            # proteção extra
            if [[ "$dirs" == "/" || -z "$dirs" ]]; then
                echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Caminho inválido! Abortando...${NUL}"
                return 1
            fi

            rm -rf "${dirs:?}/"*   # 👈 proteção contra vazio
            echo -e "${WHITE}[${BLUE}+${WHITE}] ${GREEN}Conteúdo removido com sucesso!${NUL}"
            exit 0
        ;;
        *) echo -e "${WHITE}[${RED}*${WHITE}] ${RED}Operação cancelada.${NUL}" ; return 1 ;;
    esac
}

function __remove_export(){
    local dirs="$PWD/src/exports"

    if [[ ! -d "$dirs" ]]; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}O diretório ${WHITE}${dirs} ${RED}não existe!${NUL}"
        return 1
    fi

    echo -e "${WHITE}[${BLUE}*${WHITE}] ${YELLOW}Conteúdo a ser removido: ${RED}${dirs}/${surl}${NUL}"
    read -rp $'\033[31;1mDeseja remover? [s/n]: \033[0m' opt

    case "${opt,,}" in  # 👈 lowercase automático
        s|sim)
            # proteção extra
            if [[ "$dirs" == "/" || -z "$dirs" ]]; then
                echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Caminho inválido! Abortando...${NUL}"
                return 1
            fi

            rm -rf "${dirs:?}/${surl}"   # 👈 proteção contra vazio
            echo -e "${WHITE}[${BLUE}+${WHITE}] ${GREEN}Conteúdo removido com sucesso!${NUL}"
            exit 0
        ;;
        *) echo -e "${WHITE}[${RED}*${WHITE}] ${RED}Operação cancelada.${NUL}" ; return 1 ;;
    esac
}


#========================================================
# Clone website
#========================================================

function __clone_site(){

    local url="${surl}"
    local folder_clone="$PWD/src/exports/${url}"

    echo -e "${WHITE}[${GREEN}+${WHITE}] ${BLUE}Iniciando a clonagem do site: ${WHITE}${url}${WHITE}!${NUL}"    

    if [[ ! -d "${folder_clone}" ]]; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}O diretório ${WHITE}${folder_clone} ${RED}não existe!${NUL}"
        if mkdir -p "${folder_clone}"; then
            echo -e "${WHITE}[${GREEN}+${WHITE}] ${BLUE}O diretório ${WHITE}${folder_clone} ${BLUE}foi criado com sucesso!${NUL}"
        fi
    fi

    echo -e "${WHITE}[${GREEN}!${WHITE}] ${BLUE}Entrando no diretório: ${WHITE}${folder_clone}${NUL}"
    cd "${folder_clone}" || echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Não foi possivel entrar no diretório!${NUL}"
    
    if mkdir -p clone; then
        echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Diretório foi criado com sucesso!${NUL}"
    fi

    cd clone || echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Não foi possivel entrar no diretório!${NUL}"

    httrack --mirror "${url}" -r6

    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Finalizando a clonagem!${NUL}"

    exit 0

}

function __view_clone(){

    local url="${surl}"
    local folder_clone="$PWD/src/exports/${url}"

    echo -e "${WHITE}[${GREEN}+${WHITE}] ${BLUE}Iniciando a visualização do site: ${WHITE}${url}${WHITE}!${NUL}"    

    if [[ ! -d "${folder_clone}" ]]; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}O diretório ${WHITE}${folder_clone} ${RED}não existe!${NUL}"
        exit 1
    fi

    echo -e "${WHITE}[${GREEN}!${WHITE}] ${BLUE}Entrando no diretório: ${WHITE}${folder_clone}${NUL}"
    cd "${folder_clone}" || echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Não foi possivel entrar no diretório!${NUL}"    

    sleep 2s

    firefox "clone/${url}/index.html" >/dev/null 2>&1

    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Finalizando a clonagem!${NUL}"

    exit 0
}

#========================================================
# Database
#========================================================

function __check_database(){
    
    local db_logs="$PWD/src/database/logs_database.db"
    declare -a db_schemas=(
        "$PWD/src/database/migrations/logs-schema.sql"
        "$PWD/src/database/migrations/dns-schema.sql"
    )

    # * Testa se o arquivo existe, caso não ele cria
    if [[ ! -f "${db_logs}" ]];then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Arquivo ${WHITE}${db_logs} ${RED}não exite!${NUL}"
        sleep 0.4
        echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Criando ${WHITE}${db_logs}${NUL}"
        for db_schema in "${db_schemas[@]}";do
            if sqlite3 "${db_logs}" < "${db_schema}"; then
                echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Arquivo [${WHITE}$db_schema${GREEN}] adicionado com sucesso!${NUL}"
                sqlite3 "${db_logs}" "PRAGMA foreign_keys = ON;"
            else
                echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Falha ao criar [${WHITE}$db_schema${RED}] arquivo!${NUL}"
                exit 1
            fi
        done
    else
        echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Banco de dados funcionando!${NUL}"
    fi

}

function dump_database(){
    
    local db_logs="$PWD/src/database/logs_database.db"

    gen_id=$(( 1000 + RANDOM % 9999))

    __check_database

    datetime=$(date +"%d-%m-%Y-%H-%M-%S")
    out_log="$PWD/src/database/exports/export-${gen_id}-${datetime}-db.sql"

    if sqlite3 "${db_logs}" ".dump" > "$out_log";then
        echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Arquivo [${WHITE}$out_log${GREEN}] foi exportado com sucesso!${NUL}"
    else
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Falha ao criar [${WHITE}$out_log${RED}]!${NUL}"
    fi

    return 1
}
    
#========================================================
# Cookie
#========================================================

function cookie_manager(){
    
    cookie1="$1"
    save_cookie="$PWD/src/configs/http.conf"

    sed -i "s/^cookie_gobuster=.*/cookie_gobuster=\"${cookie1}\"/" "$save_cookie"

    get_cookie="$(grep -i "^cookie_gobuster=" "$save_cookie" | cut -d "=" -f2- | tr -d '"')"

}

#========================================================
# Cleanup
#========================================================

function cleanup(){

    cat <<EOF
${CYAN}===========================================${NUL}
 ${YELLOW}[!]${NUL} SCAN FINALIZADO${NUL}
${CYAN}===========================================${NUL}
 ${GREEN}[+]${NUL} Vulnerabilidades  : ${WHITE}${vuln_count:-0}${NUL}
 ${GREEN}[+]${NUL} Subdomínios       : ${WHITE}${subdomains_count:-0}${NUL}
 ${GREEN}[+]${NUL} Diretórios/Arquivos achados: ${WHITE}${dirs_count:-0}${NUL}
 ${GREEN}[+]${NUL} Logs gravados em  : 
 ${BLUE}${output_site:-N/A}${NUL}
${CYAN}===========================================${NUL}
EOF
    if ! __remove_export "${surl}"; then : ; fi

    unset "${surl}"

}
