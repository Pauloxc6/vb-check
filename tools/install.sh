#!/usr/bin/env bash

if [[ ! $UID == 0 ]];then
    echo "[!] O programa $0 deve ser executa como root!"
    exit 1
fi

#===================================
# Banner
#===================================

cat <<EOF
 ___           _        _ _ 
|_ _|_ __  ___| |_ __ _| | |
 | || '_ \/ __| __/ _' | | |
 | || | | \__ \ || (_| | | |
|___|_| |_|___/\__\__,_|_|_|
                            
By: @Pauloxc6

EOF

#==================================
# Tools
#==================================

list_tools=(
    "curl"
    "wget"
    "nmap"
    "httrack"
    "hping3"
    "bind-utils"
    "sslscan"
    "gobuster"
)

list_tools_pip=(
    "dnsrecon"
    "sslyze"
)

#===================================
# Check os
#===================================

os=$(lsb_release -a | grep "Distributor ID:" | cut -d ":" -f2 | tr -d '\t')  # Sistemas baseados em GNU/Linux
os_bsd=$(cat /etc/os-release | cut -d "=" -f2 | tr '\n' ' '| cut -d " " -f1) # Sistemas baseados em BSD

#===================================
# Main
#===================================

if [[ "${os,,}" == "debian" || "${os,,}" == "ubuntu" ]]; then
    for tool in "${list_tools[@]}";do
        [[ "$(command -v "${tool}")" ]] && {
            apt install -y "${tool}"
        } || echo "[!] Error ao instalar: ${tool}"
    done

    for tool in "${list_tools_pip[@]}";do
        [[ "$(command -v "${tool}")" ]] && {
            pip install "${tool}"
        } || echo "[!] Error ao instalar: ${tool}"
    done
fi

if [[ "${os,,}" == "voidlinux" ]]; then
    for tool in "${list_tools[@]}";do
        [[ "$(command -v "${tool}")" ]] && {
            xbps-install -Sy "${tool}"
        } || echo "[!] Error ao instalar: ${tool}"
    done

    for tool in "${list_tools_pip[@]}";do
        [[ "$(command -v "${tool}")" ]] && {
            pip install "${tool}"
        } || echo "[!] Error ao instalar: ${tool}"
    done
fi

if [[ "${os_bsd,,}" == "freebsd" ]]; then
    for tool in "${list_tools[@]}";do
        [[ "$(command -v "${tool}")" ]] && {
            pkg install "${tool}"
        } || echo "[!] Error ao instalar: ${tool}"
    done

    for tool in "${list_tools_pip[@]}";do
        [[ "$(command -v "${tool}")" ]] && {
            pip install "${tool}"
        } || echo "[!] Error ao instalar: ${tool}"
    done
fi