CREATE TABLE IF NOT EXISTS logs_headers (
    id integer not null primary key AUTOINCREMENT,
    nome text not null,
    servidor text not null,
    linguagem text not null,
    http_version text not null,
    cookie text not null,
    waf text not null,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
