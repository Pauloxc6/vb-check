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

libs=( "./src/libs/headers.sh" "./src/libs/colors.sh" "./src/libs/global.sh" "./src/libs/gen_host.sh" "./src/libs/tech.sh" "./src/libs/dns.sh" "./src/libs/dirs.sh" "./src/libs/ssl.sh")
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

export surl=""
export runvb=1
export ssl_on=0
export verbose_on=0
export ignore_icmp=0
export wordlist_dns=""
export wordlist_dirs=""
export cookie1=""

#========================================================
# Functions
#========================================================

function check(){

    # * Verifica a URL
    if [[ -z "${surl:-}" ]]; then
        echo "Uso: bash $0 --url dominio.com"
        exit 1
    fi

    # * Chama a função de teste de conexão
    ctest

    [[ "${verbose_on}" == 1 ]] && {
        echo -e "${WHITE}[${PURPLE}VERBOSE${WHITE}] Iniciando os testes no banco de dados!${NUL}"
    }
    __check_database

    # * Verifica e cria o diretório
    echo -e "${WHITE}[${GREEN}+${WHITE}] ${GREEN}Criando o diretório de trabalho${NUL}"
    sleep 2s

    # shellcheck disable=SC2155
    export HOMEDIR="$(mdir)"
    if [ "${verbose_on:=1}" == 1 ]; then
        echo -e "${WHITE}[${PURPLE}VERBOSE${WHITE}] ${GREEN}Criado em ${BLUE}${HOMEDIR}${GREEN}!${NUL}"
    fi

    # * Chama a função headers
    check_headers

    # * Análise DNS
    bruteDNS

    # * Análise de diretórios e arquivos
    dirs

    # * Análise SSL/TLS
    [[ "${ssl_on}" == 1 ]] && {
        sslc
    }
}

#========================================================
# Parser
#========================================================

while [[ $# -ne 0 ]]; do
    case "${1}" in
        --help|-h) 
            __help__
        ;;
        -d) debuger ;;
        --url)
            shift
            export surl="${1}"
        ;;
        --cookie) shift ; cookie_manager "$1" ;;
        --ignore-icmp) export ignore_icmp=1 ;;
        --dns-wordlist|-dw) shift ; export wordlist_dns="$1" ;;
        --dir-wordlist|-diw) shift ; export wordlist_dirs="$1" ;;
        --export-db|-eb) dump_database ;;
        --remove-all-exports|-rae) __remove_all_exports ;;
        --remove-export|-re) __remove_export ;;
        --clone) __clone_site ;;
        --view-clone) __view_clone ;;
        -v) export verbose_on=1 ;;
        --ssl) export ssl_on=1 ;;
        *) __help__
    esac
    shift
done

#========================================================
# Main
#========================================================

[[ "${runvb}" == 1 ]] && { check; }
