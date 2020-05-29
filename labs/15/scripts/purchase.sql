drop schema if exists purchase cascade;
create schema purchase;
set search_path = "purchase";

drop table if exists date cascade;
drop table if exists client cascade;
drop table if exists storage cascade;
drop table if exists goods cascade;
drop table if exists purchase cascade;

create table if not exists date (
    id serial primary key,
    date date
);

create table if not exists client (
    id serial primary key,
    city int,
    name text,
    address text
);

create table if not exists storage (
    id serial primary key,
    name text
);

create table if not exists goods (
    id serial primary key,
    goods_group int,
    item_weight int,
    item_volume int,
    name text
);

create table purchase (
    id serial primary key,
    date_id int references date (id),
    client_id int references client (id),
    goods_id int references goods (id),
    storage_id int references storage (id),
    purchase_price int,
    count int,
    sum int,
    volume int,
    weight int
);

insert into date (date)
select distinct public.income.ddate date from public.income
order by date;

insert into client (city, name, address)
select C.city, C.name, C.address from public.client C;

insert into goods (goods_group, item_weight, item_volume, name)
select G.g_group, G.weight, (G.weight * G.height * G.length), G.name from public.goods G;

insert into storage (name)
select S.name from public.storage S;

insert into purchase (date_id, client_id, goods_id, storage_id, purchase_price, sum, count, volume, weight)
select D.id, I1.client, I2.goods, I1.storage, I2.price, sum(I2.volume * I2.price),
        I2.volume, I2.volume * G.item_weight, sum(G.item_weight)
from public.income I1
    join public.incgoods I2 on I1.id = I2.id
    join goods G on G.id = I2.goods
    join date D on D.date = I1.ddate
group by D.id, I1.client, I2.goods, I1.storage, I2.price, I2.volume, I2.volume * G.item_weight;