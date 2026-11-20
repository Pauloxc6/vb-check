#!/usr/bin/env bash

function dirs(){

    function loading() {
        printf "\r\e[K${BLUE}[${PURPLE}TESTANDO] Diretório: ${WHITE}%s${NUL}" "$1"
        sleep 0.02s
    }

    declare -A alertsfiles
    # ---------------------------------
    # CRITICAL (Dados de acesso total / Chaves privadas / Credenciais mestre)
    # ---------------------------------
    alertsfiles[crit_id_rsa]="critical,id_rsa,Chave privada SSH (Acesso root/shell)"
    alertsfiles[crit_id_dsa]="critical,id_dsa,Chave privada DSA legada"
    alertsfiles[crit_id_ed25519]="critical,id_ed25519,Chave privada SSH moderna"
    alertsfiles[crit_id_ecdsa]="critical,id_ecdsa,Chave privada SSH ECDSA"
    alertsfiles[crit_aws_creds]="critical,.aws/credentials,Credenciais de acesso AWS (Access/Secret Key)"
    alertsfiles[crit_kube_config]="critical,.kube/config,Configuração de cluster Kubernetes"
    alertsfiles[crit_npmrc]="critical,.npmrc,Tokens de autenticação do NPM"
    alertsfiles[crit_pypirc]="critical,.pypirc,Credenciais de publicação do PyPI"
    alertsfiles[crit_docker_cfg]="critical,.docker/config.json,Credenciais de login em registries Docker"
    alertsfiles[crit_root_bash_history]="critical,.bash_history,Histórico de comandos root"

    # ---------------------------------
    # HIGH (Arquivos de configuração com senhas, tokens ou bancos de dados)
    # ---------------------------------
    alertsfiles[high_env]="high,.env,Arquivo de variáveis de ambiente com credenciais"
    alertsfiles[high_env_local]="high,.env.local,Ambiente local customizado"
    alertsfiles[high_env_prod]="high,.env.production,Variáveis de ambiente de produção"
    alertsfiles[high_htpasswd]="high,.htpasswd,Credenciais de autenticação web (Apache/Nginx)"
    alertsfiles[high_sql_dump]="high,database.sql,Dump completo de banco de dados"
    alertsfiles[high_db_sqlite]="high,database.sqlite,Arquivo de banco de dados SQLite"
    alertsfiles[high_config_json]="high,config.json,Configurações gerais da aplicação"
    alertsfiles[high_settings_py]="high,settings.py,Configurações do Django com chaves secretas"
    alertsfiles[high_wp_config]="high,wp-config.php,Configuração do WordPress com dados do MySQL"
    alertsfiles[high_id_rsa_pub]="high,id_rsa.pub,Chave pública SSH (Auxilia no mapeamento)"

    # ---------------------------------
    # MEDIUM (Informações sensíveis de infraestrutura, logs e dependências)
    # ---------------------------------
    alertsfiles[med_docker_compose]="medium,docker-compose.yml,Orquestração de containers e serviços"
    alertsfiles[med_dockerfile]="medium,Dockerfile,Instruções de construção do container"
    alertsfiles[med_composer_lock]="medium,composer.lock,Versões exatas de dependências PHP"
    alertsfiles[med_package_lock]="medium,package-lock.json,Versões exatas de dependências Node.js"
    alertsfiles[med_error_log]="medium,error.log,Log de erros do servidor web/aplicação"
    alertsfiles[med_access_log]="medium,access.log,Log de acessos e tráfego"
    alertsfiles[med_git_config]="medium,.git/config,Configuração do repositório Git com URLs remotas"
    alertsfiles[med_htaccess]="medium,.htaccess,Regras de reescrita e segurança Apache"
    alertsfiles[med_nginx_conf]="medium,nginx.conf,Configuração do servidor web Nginx"
    alertsfiles[med_php_ini]="medium,php.ini,Configurações globais do PHP"

    # ---------------------------------
    # LOW (Metadados públicos, documentação e arquivos auxiliares)
    # ---------------------------------
    alertsfiles[low_readme]="low,README.md,Documentação pública do projeto"
    alertsfiles[low_gitignore]="low,.gitignore,Lista de exclusões do controle de versão"
    alertsfiles[low_license]="low,LICENSE,Termos de licença de uso do software"
    alertsfiles[low_editorconfig]="low,.editorconfig,Padrões de formatação de código"
    alertsfiles[low_prettierrc]="low,.prettierrc,Configuração de estilo de código"
    alertsfiles[low_eslintrc]="low,.eslintrc.json,Regras de linting de JavaScript"
    alertsfiles[low_changelog]="low,CHANGELOG.md,Histórico de alterações e versões"
    alertsfiles[low_robots]="low,robots.txt,Regras de rastreamento para motores de busca"
    alertsfiles[low_sitemap]="low,sitemap.xml,Lista de estrutura de pagínas para motores de busca";
    alertsfiles[low_favicon]="low,favicon.ico,Ícone do site"
    alertsfiles[low_index_html]="low,index.html,Página inicial padrão"

    # shellcheck disable=SC2154
    local wordlist="${wordlist_dirs}"

    cat <<EOF
    _                    _                
   / \   _ __ __ _ _   _(_)_   _____  ___ 
  / _ \ | '__/ _' | | | | \ \ / / _ \/ __|
 / ___ \| | | (_| | |_| | |\ V / (_) \__ \ 
/_/   \_\_|  \__, |\__,_|_| \_/ \___/|___/
                |_|                       
EOF

    if [[ ! -e "${wordlist}" ]]; then
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}O caminho da wordlist não foi especificado!${NUL}" >&2
        echo -e "${WHITE}[${RED}!${WHITE}] ${RED}Utilizando a wordlist padrão...${NUL}" >&2
        wordlist="${rootdir}/src/wordlists/vbcheck.txt"
    fi

    local total_linhas="$( wc -l < "${wordlist}" )"
    tempo_estimado=$(echo "scale=2; ($total_linhas * 0.52) / 60" | bc)

    local minutos_inteiros=$(echo "$tempo_estimado" | cut -d'.' -f1)
    minutos_inteiros=${minutos_inteiros:-0}

    if [[ "$minutos_inteiros" -ge 60 ]]; then
        local horas=$(echo "scale=1; $minutos_inteiros / 60" | bc)
        messagem_tempo="~${horas}h"
    elif [[ "$minutos_inteiros" -ge 1 ]]; then
        messagem_tempo="~${minutos_inteiros}m"
    else
        local segundos=$(echo "$total_linhas * 0.52" | bc | cut -d'.' -f1)
        messagem_tempo="~${segundos}s"
    fi

    if [[ "${ssl_on}" -eq 1 ]]; then
        local url="https://${surl}${path}"
    else
        local url="http://${surl}${path}"
    fi

    # shellcheck disable=SC2154
    echo -e "${WHITE}[${BLUE}DIRS${WHITE}] ${BLUE}Testando: ${WHITE}${url} ${WHITE}-> { ${GREEN}${wordlist} ${WHITE}}${NUL}"
    echo -e "${WHITE}[${BLUE}DIRS${WHITE}] ${BLUE}Carregando os dados! ${WHITE}| ${RED}Wordlist com ${total_linhas} linhas (${messagem_tempo}). Essa etapa pode demorar alguns minutos!${NUL}"

    start_time=$(date +'%s')

    # shellcheck disable=SC2154
    mapfile -t files < <(gobuster dir -r -u "${url}" -w "${wordlist}" -H "Cookie: $get_cookie" -x "asp,php,txt,html,js,css,json,xml,sql,bak,backup,bkp,old,log,db,ini,conf,config" --random-agent --delay 500ms --no-tls-validation --status-codes-blacklist "404,403" --exclude-length 0 --threads 30 --quiet 2>/dev/null) 

    while IFS= read -r line; do loading "${line}"; done < "${wordlist}"

    echo
    for gfile in "${files[@]}"; do

        local gfile="${gfile%% *}"

        # Validação de segurança do formato do arquivo/diretório
        if [[ ! "${gfile}" =~ ^[a-zA-Z0-9_./-]+$ ]]; then
            continue
        fi

        found=0

        for alert in "${alertsfiles[@]}"; do
        
            local typealert=$(echo "${alert}" | cut -d "," -f1)
            local file=$(echo "${alert}" | cut -d "," -f2)
            local message=$(echo "${alert}" | cut -d "," -f3)
        
            if [[ "${file}" == "${gfile}" ]]; then
                status_dirs=$(httpx -u "${url}/${file}" -fc 403,404 -status-code -silent </dev/null | awk -F' ' '{print $2}')
                echo -e "${BLUE}[${WHITE}+${BLUE}] Alerta: ${YELLOW}${typealert} ${WHITE}| ${BLUE}Arquivo Sensíveis ${status_dirs:-[301]}: ${GREEN}${url}/${file} ${WHITE}| ${PURPLE}${message}${NUL}"
                found=1
                dirs_count=$(( dirs_count + 1 ))
                break
            fi

        done

        [[ "${found}" -eq 0 ]] && { 
            status_dirs=$(httpx -u "${url}/${file}" -fc 403,404 -status-code -silent </dev/null | awk -F' ' '{print $2}')
            echo -e "${BLUE}[${WHITE}+${BLUE}] Diretório/Arquivo não listado ${status_dirs:-[301]}: ${WHITE}${url}/${gfile}${NUL}"
            dirs_count=$(( dirs_count + 1))
        }
    done

    end_time=$(date +'%s')
    finish_time=$( bc <<< "(${end_time} - ${start_time}) / 60")

    echo -e "\n${WHITE}[${BLUE}DIRS${WHITE}] Finalizando o teste (${GREEN}${finish_time}m/${RED}${messagem_tempo})${NUL}"

    # ! Reseta o cookie depois que finaliza
    # shellcheck disable=SC2154
    sed -i "s/^cookie_gobuster=.*/cookie_gobuster=\"\"/" "$save_cookie"
}
