#!/usr/bin/env bash

function waf_check(){

    function add_score(){
        score_waf=$(( score_waf + "$1" ))
    }

    local tpl_waf="$PWD/src/configs/waf.yaml"
    local output_file="$HOMEDIR/site.temp"

    local check1_ok=""
    local check2_ok=""
    local check3_ok=""
    detected_waf=""

    score_waf=0

    declare -a list_fws=(cloudflare akamai imperva sucuri fastly f5_bigip aws_waf barracuda radware fortinet citrix)

    # =========================
    # CACHE (carrega tudo 1x)
    # =========================
    declare -A waf_servers
    declare -A waf_ips
    declare -A waf_cookies

    for fw in "${list_fws[@]}"; do
        waf_servers["$fw"]="$(yq -r ".wafs.name.${fw}.server" "$tpl_waf")"
        waf_ips["$fw"]="$(yq -r ".wafs.name.${fw}.ips[]" "$tpl_waf" 2>/dev/null | tr '\n' ' ')"
        waf_cookies["$fw"]="$(yq -r ".wafs.name.${fw}.ips[]" "$tpl_waf" 2>/dev/null | tr '\n' ' ')"
    done

    # ====


    # =========================
    # CHECK 1 - Servidor
    # =========================
    while read -r line; do
        serverType=$(printf '%s' "$line" | tr -d '\r' | sed 's/^[^:]*:[[:space:]]*//')

        for fw in "${list_fws[@]}"; do
            if [[ "${waf_servers[$fw]}" == "$serverType" ]]; then
                check1_ok=1
                detected_waf="$fw"
                add_score 40
            fi
        done
    done < <(grep -i '^server:' "$output_file")

    # =========================
    # CHECK 2 - Cookie
    # =========================

    while read -r line; do
        cookie=$(echo "$line" | tr -d '\r' | cut -d ":" -f2- | xargs)
        cookie_lower="${cookie,,}"

        for fw in "${list_fws[@]}"; do
            for sig in ${waf_cookies[$fw]}; do
                if [[ "$cookie_lower" == *"${sig,,}"* ]]; then
                    check2_ok=1
                    detected_waf="$fw"
                    add_score 50
                fi
            done
        done

    done < <(grep -i "^set-cookie:" "$output_file")

    # =========================
    # CHECK 3 - IP
    # =========================
    # shellcheck disable=SC2154
    if [[ "${ignore_icmp}" == 1 ]]; then
        echo -e "${WHITE}[${YELLOW}!${WHITE}] ${YELLOW}Ping ignorado${NUL}"
        return 0
    fi

    ip=$(ping -c 1 -4 "${surl}" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1)
    [[ -z "$ip" ]] && return 0

    ip_prefix=$(cut -d '.' -f1,2 <<< "$ip")

    for fw in "${list_fws[@]}"; do
        for ips in ${waf_ips[$fw]}; do
            if [[ "$ip_prefix" == "$ips" ]]; then
                check3_ok=1
                detected_waf="$fw"
                add_score 10
            fi
        done
    done

    # Saída final
    if [[ "${check1_ok:-0}" -eq 1 || "${check2_ok:-0}" -eq 1 || "${check3_ok:-0}" -eq 1 ]]; then
        echo -e "${WHITE}[${BLUE}-${WHITE}] ${CYAN}WAF: ${WHITE}${detected_waf:-NULL} | ${CYAN}Probalidade: ${WHITE}${score_waf}%${NUL}"
    fi
}