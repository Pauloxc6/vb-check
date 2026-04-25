CREATE TABLE IF NOT EXISTS dns (
    id integer not null primary key AUTOINCREMENT,
    domain text not null,
    ip text not null,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    foreign key (domain) references logs_headers(nome) 
);

CREATE TABLE IF NOT EXISTS dns_ns (
    ns_id integer not null primary key AUTOINCREMENT,
    ns text not null,
    ip text not null,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    foreign key (ns_id) references dns(id) 
);

CREATE TABLE IF NOT EXISTS dns_mx (
    mx_id integer not null primary key AUTOINCREMENT,
    mx text not null,
    ip text not null,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    foreign key (mx_id) references dns(id) 
);

CREATE TABLE IF NOT EXISTS dns_text (
    text_id integer not null primary key AUTOINCREMENT,
    domain text not null,
    txt text not null,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    foreign key (text_id) references dns(id)
);
