#!/usr/bin/env bash

libs=( "./src/libs/headers.sh" "./src/libs/colors.sh" "./src/libs/global.sh" "./src/libs/gen_host.sh" "./src/libs/tech.sh" "./src/libs/dns.sh" "./src/libs/dirs.sh" "./src/libs/ssl.sh" "./src/libs/url.sh" "./src/libs/vuln.sh" "./src/libs/email.sh" )

for lib in "${libs[@]}"; do
    if [[ -f "${lib}" ]]; then
        # shellcheck disable=SC1090
        source "${lib}" > /dev/null 2>&1
    else
        echo -e "${WHITE}[${GREEN}!${WHITE}] ${RED}Erro ao importar a lib: ${WHITE}$lib${NUL}"
    fi
done