
# 📡 VB-CHECK

Ferramenta de análise automatizada de segurança e reconhecimento de aplicações web, desenvolvida em Bash com auxílio de IA.

O objetivo do projeto é automatizar a coleta de informações públicas de sistemas web e realizar análises básicas de segurança, auxiliando no processo de auditoria e estudo de exposição de serviços.

---
## 🎓 Contexto Acadêmico (TCC)

Este projeto foi desenvolvido como proposta de Trabalho de Conclusão de Curso (TCC), com foco em segurança da informação e automação de reconhecimento de aplicações web.

A ferramenta tem finalidade **educacional e defensiva**, sendo utilizada apenas em ambientes autorizados.

---
## ⚙️ Funcionalidades


### 🌐 Reconhecimento de Rede (DNS)

- Resolução de registros:

	- A
	- AAAA
	- MX
	- NS
	- TXT
	- SOA
	- Brute force de subdomínios
	- Identificação de IPs associados ao domínio

---
### 📡 Análise HTTP

- Captura de headers HTTP
- Identificação de:
- Server
- X-Powered-By
- Location (redirects)
- Cookies (Set-Cookie)
---
### 🍪 Análise de Cookies

- Detecção de atributos:

	- Secure
	- HttpOnly
	- SameSite
	- Identificação de cookies sensíveis (session, auth, token)
	- Análise de possíveis falhas de configuração  

---
### 🛡️ Detecção de WAF

Detecção baseada em múltiplas fontes:

- Headers HTTP
- Cookies de sessão
- Prefixo de IP

WAFs suportados:

- Cloudflare
- Akamai
- Imperva
- Sucuri
- AWS WAF
- F5 BigIP
- Barracuda
- Radware
- Fortinet

---
### 🔐 Análise SSL/TLS

- Verificação de protocolos suportados
- Análise de cifras criptográficas
- Inspeção de certificados
- Detecção de vulnerabilidade Heartbleed

---
### 📁 Enumeração de Diretórios

- Brute force de diretórios e arquivos
- Suporte a wordlists personalizadas
- Integração com `gobuster`

---
### 💾 Banco de Dados

- Armazenamento em SQLite
- Logs estruturados de:
- DNS
- Headers HTTP
- Cookies
- WAF detectado
- Sistema de exportação de dados

---
### 📦 Clonagem de Sites

- Clonagem de páginas com `httrack`
- Visualização local de conteúdo clonado

---
## 🚀 Uso


```bash

bash bin/main.sh --url exemplo.com

🔧 Argumentos

Argumento Descrição

--url Define o alvo
--ssl Ativa análise SSL
--dns-wordlist Wordlist para subdomínios
--dir-wordlist Wordlist para diretórios
--cookie Define cookie manual
--ignore-icmp Ignora ping ICMP
-v Modo verbose
-d Modo debug
--help Exibe ajuda

🧪 Exemplos

bash bin/main.sh --url google.com
bash bin/main.sh --url example.com --ssl
bash bin/main.sh --url site.com --dns-wordlist subdomains.txt
bash bin/main.sh --url site.com --dir-wordlist dirs.txt
```

---
### 🧠 Arquitetura do Projeto

```
VB-CHECK/
│
├── bin/
│   └── main.sh                 # Script principal de execução da ferramenta
│
├── src/
│   ├── libs/                  # Módulos principais (DNS, WAF, SSL, etc.)
│   ├── configs/               # Arquivos de configuração (headers, waf, cookies)
│   ├── database/              # Banco de dados SQLite e migrações
│   │   ├── exports/           # Dumps e exportações do banco
│   │   └── migrations/        # Estrutura inicial do banco
│   ├── exports/               # Resultados gerados por alvo analisado
│   └── wordlists/             # Listas para brute force (DNS, dirs, etc.)
│
├── teste/                    # Ambiente de testes da ferramenta
│   ├── bash/                 # Scripts de teste em Bash
│   ├── sql/                  # Testes relacionados ao banco de dados
│   └── temp/                 # Arquivos temporários de validação
│
├── tools/                   # Ferramentas auxiliares externas
    └── install.sh           # Script de instalação/configuração inicial
```
---
### ⚠️ Aviso Legal

Este software foi desenvolvido exclusivamente para fins educacionais e de pesquisa em segurança da informação.

O uso desta ferramenta em sistemas sem autorização explícita é de total responsabilidade do usuário.

---

🛠️ Tecnologias Utilizadas

```
Bash
SQLite
curl / wget
dig / host
sslscan / sslyze
gobuster
yq
```

---

📌 Melhorias Futuras

- Sistema de score de risco geral
- Geração de relatórios (JSON / Markdown / PDF)
- Sistema de plugins modulares
- Paralelização de tarefas
- Fingerprinting avançado de tecnologias web
- Modo de execução full scan automatizado

---
👨‍💻 Autor

> Projeto desenvolvido por @Pauloxc6

---

📚 Referências

OWASP Web Security Testing Guide
OWASP Top 10
Documentação de ferramentas de recon e análise web