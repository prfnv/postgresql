drop table if exists g;
drop table if exists test;
drop table if exists goods_groups cascade;
drop table if exists storage cascade;
drop table if exists recept cascade;
drop table if exists recgoods cascade;
drop table if exists region cascade;
drop table if exists income cascade;
drop table if exists incgoods cascade;
drop table if exists client cascade;
drop table if exists client_groups cascade;
drop table if exists cassa_income cascade;
drop table if exists city cascade;
drop table if exists goods cascade;
drop table if exists cassa_recept cascade;
drop table if exists bank_recept cascade;
drop table if exists bank_income cascade;
drop table if exists temp cascade;

drop schema if exists purchase cascade;
drop schema if exists remains cascade;
drop schema if exists sale cascade;

create table region (
    id serial primary key,
    name text
);

create table city (
    id serial primary key,
    name text,
    region int references region (id)
);

create table storage (
    id serial primary key,
    name text
);

create table client (
    id serial primary key,
    name text,
    address text,
    city int references city (id)
);

create table recept (
    id serial primary key,
    ddate date,
    ndoc int,
    client int references client (id),
    storage int references storage (id)
);

create table income (
    id serial primary key,
    ddate date,
    ndoc int,
    client int references client (id),
    storage int references storage (id)
);

create table goods_groups (
    id serial primary key,
    name text,
    parent int references goods_groups (id)
);


create table goods (
    id serial primary key,
    g_group int references goods_groups (id),
    name text,
    weight decimal(18, 4),
    length decimal(18, 4),
    height decimal(18, 4),
    width decimal(18, 4)
);

create table recgoods (
    id int references recept (id),
    subid int,
    goods int references goods (id),
    volume int,
    price decimal(18, 4),
    primary key (id, subid)
);

create table incgoods (
    id int references income (id),
    subid int,
    goods int references goods (id),
    volume int,
    price decimal(18, 4),
    primary key (id, subid)
);

create table cassa_income (
    id serial primary key,
    ddate date,
    summ int,
    client int references client (id)
);

create table bank_income (
    id serial primary key,
    ddate date,
    summ int,
    client int references client (id)
);

create table cassa_recept (
    id serial primary key,
    ddate date,
    summ int,
    client int references client (id)
);

create table bank_recept (
    id serial primary key,
    ddate date,
    summ int,
    client int references client (id)
);


insert into region(name)
select ('Регион ' || t)::text from generate_series(1, 5) t;

insert into city(name, region)
select ('Город ' || t)::text,
       (select id from region where t > 0 order by random() limit 1)
from generate_series(1, 100) t;

insert into client(name, address, city)
select ('Клиент ' || t)::text,
       ('Address: Улица - ' || (select * from generate_series(1, 227) where t > 0 order by random() limit 1))::text,
       (select id from city where t > 0 order by random() limit 1)
from generate_series(1, 100) t;

insert into storage(name)
select ('warehouse: ' || t)::text from generate_series(1, 10) t;

insert into goods_groups(name, parent)
select ('Group: ' || t)::text, (t)::int from generate_series(1, 5) t;

insert into goods_groups(name, parent)
select ('Subgroup: ' || t)::text,
       (select id from goods_groups where t > 0 order by random() limit 1)
from generate_series(1, 5) t;

insert into goods(g_group, name, weight, length, height, width)
select (select id from goods_groups where t > 0 order by random() limit 1),
       ('Good: ' || t)::text,
       (select * from generate_series(1, 10) where t > 0 order by random() limit 1),
       (select * from generate_series(1, 14) where t > 0 order by random() limit 1),
       (select * from generate_series(1, 5) where t > 0 order by random() limit 1),
       (select * from generate_series(1, 4) where t > 0 order by random() limit 1)
from generate_series(1, 15) t;

create or replace function generate_dates(dt1 date, dt2 date, n int) returns setof date as $$
select $1 + i from generate_series(0, $2 - $1, $3) i;
$$ language sql immutable ;

insert into recept(ddate, ndoc, client, storage)
select (select * from generate_dates('2020-01-01', '2020-03-31', 1) where t > 0 order by random() limit 1) d, t,
       (select client.id from client where t > 0 order by random() limit 1),
       (select storage.id from storage where t > 0 order by random() limit 1)
from generate_series(1, 10000) t
order by d;

insert into income(ddate, ndoc, client, storage)
select (select * from generate_dates('2020-04-01', '2020-12-31', 1) where t > 0 order by random() limit 1) d, t,
       (select client.id from client where t > 0 order by random() limit 1),
       (select storage.id from storage where t > 0 order by random() limit 1)
from generate_series(1, 10000) t
order by d;

insert into incgoods(id, subid, goods, volume, price)
select t, t, (select goods.id from goods where t > 0 order by random() limit 1),
             (select * from generate_series(500, 1500) where t > 0 order by random() limit 1),
             (select * from generate_series(100, 300) where t > 0 order by random() limit 1)
from generate_series(1, 10000) t;

insert into recgoods(id, subid, goods, volume, price)
select t, t, (select goods.id from goods where t > 0 order by random() limit 1),
             (select * from generate_series(100, 500) where t > 0 order by random() limit 1),
             (select * from generate_series(350, 1500) where t > 0 order by random() limit 1)
from generate_series(1, 10000) t;

insert into bank_income(ddate, summ, client)
select R.ddate, (R2.volume * R2.price) sum, R.client from recept R
    join recgoods R2 on R.id = R2.id limit 5000;

insert into cassa_income(ddate, summ, client)
select R.ddate, (R2.volume * R2.price) sum, R.client from recept R
    join recgoods R2 on R.id = R2.id limit 5000 offset 5000;

insert into bank_recept(ddate, summ, client)
select I.ddate, (I2.volume * I2.price) sum, I.client from income I
    join incgoods I2 on I.id = I2.id limit 5000;

insert into cassa_recept(ddate, summ, client)
select I.ddate, (I2.volume * I2.price) sum, I.client from income I
    join incgoods I2 on I.id = I2.id limit 5000 offset 5000;