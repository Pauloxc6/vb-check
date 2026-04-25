#!/usr/bin/env bash
#========================================================
# Vars e Globais
#========================================================

export LC_ALL=C
export LANG=C

#========================================================
# Create Home Dir
#========================================================

function mdir(){
    # shellcheck disable=SC2154
    local host="${surl}"
    local dirhome="$PWD/src/exports"

    if [[ ! -d "$dirhome" ]]; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}O diretório não existe!${NUL}" >&2
        return 1
    fi

    local final_dir="$dirhome/$host"

    mkdir -p "$final_dir"

    if [[ "${verbose_on:-0}" == 1 ]]; then
        echo -e "${WHITE}[${PURPLE}VERBOSE${WHITE}] ${BLUE}Criando o diretório ${WHITE}${final_dir}${NUL}" >&2
    fi

    echo "$final_dir"   # 👈 retorna apenas o caminho
}