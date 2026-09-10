create table clientes(
	id serial primary key,
	nome varchar(100) not null,
	email varchar(100) not null unique,
	telefone varchar(20) not null,
	cpf varchar(11) unique not null,
	data_cadastro TIMESTAMP default current_timestamp
);

create table mecanicos(
	id serial primary key,
	nome varchar(100) not null,
	especialidade varchar(100) not null,
	valor_hora NUMERIC(10, 2) NOT NULL CHECK (valor_hora > 0)
);

create table veiculos(
	id serial primary key,
	cliente_id int not null,
	placa varchar(7) unique not null,
	modelo varchar(100) not null,
	marca varchar(50) not null,
	ano int not null,

    CONSTRAINT fk_veiculo_cliente 
    	FOREIGN KEY (cliente_id) 
    	REFERENCES clientes(id) 
    	ON DELETE CASCADE
);

create table ordens_servico(
	id serial primary key,
	veiculo_id int not null,
	mecanico_id int not null,
	data_abertura TIMESTAMP default current_timestamp,
	valor_mao_obra NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (valor_mao_obra >= 0),
    status VARCHAR(20) DEFAULT 'Em Aberto' CHECK (status IN ('Em Aberto', 'Em Andamento', 'Concluida', 'Cancelada')),

    CONSTRAINT fk_os_veiculo 
        FOREIGN KEY (veiculo_id) 
        REFERENCES veiculos(id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_os_mecanico 
        FOREIGN KEY (mecanico_id) 
        REFERENCES mecanicos(id) 
        ON DELETE RESTRICT
);

create table pecas_os(
	id serial primary key,
	os_id int not null,
	nome_peca varchar(100) not null,
	quantidade int not null check (quantidade > 0),
	valor_unitario numeric(10,2) not null check (valor_unitario > 0),

	CONSTRAINT fk_peca_os
		FOREIGN key (os_id)
		REFERENCES ordens_servico(id)
		on delete cascade
);

INSERT INTO clientes (nome, email, telefone, cpf) VALUES 
('Fernanda Lima', 'fernanda.lima@email.com', '(48) 99911-2233', '11122233344'),
('Roberto Souza', 'roberto.souza@email.com', '(48) 98822-4455', '55566677788'),
('Amanda Martins', 'amanda.martins@email.com', '(48) 97733-6677', '99900011122');

INSERT INTO mecanicos (nome, especialidade, valor_hora) VALUES 
('Carlos Eduardo', 'Motor e Câmbio', 120.00),
('Marcos Vinicius', 'Suspensão e Freios', 85.00),
('João Pedro', 'Elétrica e Injeção', 100.00);

INSERT INTO veiculos (cliente_id, placa, modelo, marca, ano) VALUES 
(1, 'ABC1D23', 'Civic 2.0', 'Honda', 2020),       -- Veículo 1 (Fernanda)
(1, 'XYZ9K88', 'Fit 1.5', 'Honda', 2018),         -- Veículo 2 (Fernanda)
(2, 'KLR4M55', 'Corolla 2.0', 'Toyota', 2021),    -- Veículo 3 (Roberto)
(3, 'JHG8T77', 'Onix 1.0 Turbo', 'Chevrolet', 2022);-- Veículo 4 (Amanda)

INSERT INTO ordens_servico (veiculo_id, mecanico_id, valor_mao_obra, status) VALUES 
(1, 1, 350.00, 'Concluida'),   -- OS 1 (Civic da Fernanda com Carlos)
(2, 2, 180.00, 'Concluida'),   -- OS 2 (Fit da Fernanda com Marcos)
(3, 1, 500.00, 'Em Andamento'),-- OS 3 (Corolla do Roberto com Carlos)
(4, 3, 200.00, 'Concluida');   -- OS 4 (Onix da Amanda com João)

INSERT INTO pecas_os (os_id, nome_peca, quantidade, valor_unitario) VALUES 
(1, 'Jogo de Velas Iridium', 1, 240.00),
(1, 'Óleo Sintético 5W30 (Litro)', 4, 60.00),
(2, 'Pastilha de Freio Dianteira', 1, 150.00),
(4, 'Bateria 60Ah', 1, 420.00);


--Q1
select
	v.marca,
	v.modelo,
	v.placa,
	v.ano,
	c.nome as proprietario,
	c.telefone
from veiculos v
inner join clientes c on v.cliente_id = c.id
order by v.marca asc , v.modelo asc;

--Q2
select 
    os.id as os_id,
    v.placa,
    v.modelo,
    os.data_abertura,
    m.nome as mecanico,
    os.status
from ordens_servico os
inner join veiculos v on os.veiculo_id = v.id
inner join clientes c on v.cliente_id = c.id
inner join mecanicos m on os.mecanico_id = m.id
where c.nome = 'fernanda lima'
order by os.data_abertura desc;

--Q3
select 
    os.id as os_id,
    v.placa,
    m.nome as mecanico,
    os.valor_mao_obra,
    coalesce(sum(p.quantidade * p.valor_unitario), 0.00) as total_pecas,
    (os.valor_mao_obra + coalesce(sum(p.quantidade * p.valor_unitario), 0.00)) as valor_total_os
from ordens_servico os
inner join veiculos v on os.veiculo_id = v.id
inner join mecanicos m on os.mecanico_id = m.id
left join pecas_os p on os.id = p.os_id
group by os.id, v.placa, m.nome, os.valor_mao_obra
order by os.id;

--Q4
select 
    nome as mecanico,
    especialidade,
    valor_hora
from mecanicos
where valor_hora > 90.00
order by valor_hora desc;

--Q5
select 
    m.especialidade,
    count(os.id) as qtd_servicos_concluidos,
    coalesce(sum(os.valor_mao_obra), 0.00) as faturamento_mao_obra
from mecanicos m
left join ordens_servico os on m.id = os.mecanico_id and os.status = 'concluida'
group by m.especialidade
order by faturamento_mao_obra desc;