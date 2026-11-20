#!/usr/bin/env bash
#========================================================
# BANNER
#========================================================

cat <<EOF
__     ______         ____ _   _ _____ ____ _  __
\ \   / / __ )       / ___| | | | ____/ ___| |/ /
 \ \ / /|  _ \ _____| |   | |_| |  _|| |   | ' / 
  \ V / | |_) |_____| |___|  _  | |__| |___| . \ 
   \_/  |____/       \____|_| |_|_____\____|_|\_\ 
                                                 
By: @Pauloxc6

Utilize o parâmetro --help para visualizar o menu de ajuda!
EOF

#========================================================
# Imports
#========================================================

libs=( "./src/libs/call.sh" )
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

# Otimização
export LC_ALL=C
export LANG=C

surl=""
runvb=1
ssl_on=0
dirs_on=1
dns_on=1
email_on=1
url_on=1
verbose_on=0
ignore_icmp=0
wordlist_dns=""
wordlist_dirs=""
cookie1=""

rootdir="$( cd -- "$(basename -- "$(dirname "$0")" )" && pwd )"

#========================================================
# Functions
#========================================================

function check(){

    # * Verifica a URL
    if [[ -z "${surl:-}" ]]; then
        echo "Uso: bash $0 --url dominio.com"
        exit 1
    fi

    cleanuri

    # * Chama a função de teste de conexão
    ctest

    [[ "${verbose_on}" == 1 ]] && { echo -e "${WHITE}[${PURPLE}VERBOSE${WHITE}] Iniciando os testes no banco de dados!${NUL}" ;}

    __check_database

    # * Verifica e cria o diretório
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Criando o diretório de trabalho${NUL}"
    sleep 2s

    # shellcheck disable=SC2155
    export HOMEDIR="$(mdir)"
    if [ "${verbose_on:=1}" == 1 ]; then echo -e "${WHITE}[${PURPLE}VERBOSE${WHITE}] ${GREEN}Criado em ${BLUE}${HOMEDIR}${GREEN}!${NUL}" ; fi

    # * Chama a função headers
    check_headers

    # * Análise DNS
    [[ "${dns_on}" == 1 ]] && { bruteDNS ;}

    # * Análise de diretórios e arquivos
    [[ "${dirs_on}" == 1 ]] && { dirs ;}

    # * Análise SSL/TLS
    [[ "${ssl_on}" == 1 ]] && { sslc ;}

    # * Validando virus na url
    [[ "${url_on}" == 1 ]] && { virustotal ;}

    # * Confiabilidade da email
    [[ "${email_on}" == 1 ]] && { email ;}

    # * Análise SSL/TLS
    [[ "${vuln_on}" == 1 ]] && {
        #vuln.smtp.userenum 
        #vuln.nuclei.scan
        vuln.javascript.scan
        #vuln.subdomaintakeover.scan
        #modat.cves.scan
        #param.vuln.scan
    }
}

#========================================================
# Parser
#========================================================

while [[ $# -ne 0 ]]; do
    case "${1}" in
        --help|-h)  __help__ ; exit 0 ;;
        -d) debuger ;;
        --url) shift ; export surl="${1}" ;;
        --cookie) shift ; cookie_manager "$1" ;;
        --ignore-icmp) export ignore_icmp=1 ;;
        --dns-wordlist|-dw) shift ; export wordlist_dns="$1" ;;
        --dir-wordlist|-diw) shift ; export wordlist_dirs="$1" ;;
        --export-db|-eb) dump_database ;;
        --remove-all-exports|-rae) __remove_all_exports ;;
        --remove-export|-re) __remove_export ;;
        --clone) __clone_site ;;
        --view-clone) __view_clone ;;
        -v|--verbose) export verbose_on=1 ;;
        --ssl) export ssl_on=1 ;;
        --vuln) export vuln_on=1 ;;
        --disable) shift ; disbalefunctions "$1" ;;
        *) __help__ ; exit 0 ;;
    esac
    shift
done

#========================================================
# Main
#========================================================

[[ "${runvb}" == 1 ]] && { check; }

#========================================================
# Exit
#========================================================

trap cleanup EXIT