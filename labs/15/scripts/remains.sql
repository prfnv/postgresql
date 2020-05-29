drop schema if exists remains cascade;
create schema remains;
set search_path = "remains";

drop table if exists date cascade;
drop table if exists storage cascade;
drop table if exists goods cascade;
drop table if exists remains cascade;


create table if not exists date (
    id serial primary key,
    date date
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

create table remains (
    id serial primary key,
    date_id int references date (id),
    goods_id int references goods (id),
    storage_id int references storage (id),
    sum int,
    count int,
    volume int,
    weight int
);

insert into date (date)
select distinct TEMP.date from (select public.income.ddate date
    from public.income union
    select public.recept.ddate date
    from public.recept
) as temp
order by TEMP.date;

insert into storage (name)
select S.name from public.storage S;

insert into goods (goods_group, item_weight, item_volume, name)
select G.g_group, G.weight, (G.weight * G.height * G.length), G.name
from public.goods G;

insert into remains(date_id, goods_id, storage_id, sum, count, volume, weight)
select TEMP.date_id, TEMP.goods_id, TEMP.storage_id, (
        coalesce((select sum(P.count)
                from purchase.purchase P
                where P.date_id <= TEMP.date_id
                and P.goods_id = TEMP.goods_id
                and P.storage_id = TEMP.storage_id), 0) -
        coalesce((select sum(S.count)
                from sale.sale S
                where S.date_id <= TEMP.date_id
                and S.goods_id = TEMP.goods_id
                and S.storage_id = TEMP.storage_id), 0)
    ) * (select P.purchase_price
        from purchase.purchase P
        where P.date_id <= TEMP.date_id
        and P.goods_id = TEMP.goods_id
        and P.storage_id = TEMP.storage_id
    order by p.date_id desc limit 1) sum,
    coalesce((select sum(P.count)
                from purchase.purchase P
                where P.date_id <= TEMP.date_id
                and P.goods_id = TEMP.goods_id
                and P.storage_id = TEMP.storage_id), 0) -
    coalesce((select sum(S.count)
                from sale.sale S
                where S.date_id <= TEMP.date_id
                and S.goods_id = TEMP.goods_id
                and S.storage_id = TEMP.storage_id), 0) count,
    (
        coalesce((select sum(P.count)
                from purchase.purchase P
                where P.date_id <= TEMP.date_id
                and P.goods_id = TEMP.goods_id
                and P.storage_id = TEMP.storage_id), 0) -
        coalesce((select sum(S.count)
                from sale.sale S
                where S.date_id <= TEMP.date_id
                and S.goods_id = TEMP.goods_id
                and S.storage_id = TEMP.storage_id), 0)
    ) * (select P.weight
        from purchase.purchase P
        where P.date_id <= TEMP.date_id
        and P.goods_id = TEMP.goods_id
        and P.storage_id = TEMP.storage_id
    order by TEMP.date_id desc
    limit 1) volume,
    (select P.weight
        from purchase.purchase P
        where P.date_id <= TEMP.date_id
        and P.goods_id = TEMP.goods_id
        and P.storage_id = TEMP.storage_id
    order by TEMP.date_id desc
    limit 1) weight
from (select S.date_id, S.goods_id, S.storage_id, S.sum, S.count
    from sale.sale S union
    select P.date_id, P.goods_id, P.storage_id, P.sum, P.count
    from purchase.purchase P
) as temp;