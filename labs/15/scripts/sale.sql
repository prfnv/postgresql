drop schema if exists sale cascade;
create schema sale;
set search_path = "sale";

drop table if exists date cascade;
drop table if exists client cascade;
drop table if exists storage cascade;
drop table if exists goods cascade;
drop table if exists sale cascade;


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

create table sale (
    id serial primary key,
    date_id int references date (id),
    client_id int references client (id),
    goods_id int references goods (id),
    storage_id int references storage (id),
    sum int,
    count int,
    volume int,
    weight int,
    cost_price int,
    sell_price int
);

insert into date (date)
select distinct public.recept.ddate date from public.recept
order by date;

insert into client (city, name, address)
select C.city, C.name, C.address from public.client C;

insert into goods (goods_group, item_weight, item_volume, name)
select G.g_group, G.weight, (G.weight * G.height * G.length), G.name from public.goods G;

insert into storage (name)
select S.name from public.storage S;


insert into sale (date_id, client_id, goods_id, storage_id, sum, count, volume, weight, cost_price, sell_price)
select D.id as date_id, R1.client as client_id, R2.goods as goods_id, R1.storage as storage_id,
    sum(R2.volume * R2.price), R2.volume, R2.volume * G.item_weight, sum(G.item_weight),
    (select P.purchase_price from purchase.purchase P where p.date_id <= D.id and p.goods_id = R2.goods limit 1),
    R2.price
from public.recept R1
    join public.recgoods R2 on R1.id = R2.id
    join goods G on G.id = R2.goods
    join date D on D.date = R1.ddate
group by D.id, R1.client, R2.goods, R1.storage, R2.volume, R2.volume * G.item_weight,
    (select P.purchase_price from purchase.purchase P where p.date_id <= D.id and p.goods_id = R2.goods limit 1),
    R2.price;