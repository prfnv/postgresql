-- creation
create table partners (
    id serial primary key,
    name text
);

create table goods_group (
    id serial primary key,
    name text
);

create table goods (
    id serial primary key,
    name text,
    id_group int references goods_group(id)
);

create table pricelist (
    id serial primary key,
    name text
);

create table pr_lists (
    id serial primary key,
    id_price int references pricelist(id),
    id_goods int references goods(id),
    price decimal(18, 4),
    ddate date
);

create table group_part (
    id serial primary key,
    name text
);

create table ggroup_part (
    id serial primary key ,
    id_ggroup_part int references group_part(id),
    id_goods_group int references goods_group(id)
);

create table price_ggroups (
    id serial primary key ,
    id_price int references pricelist(id),
    id_ggroup_part int references group_part(id),
    id_partner int references partners(id)
);

-- insertion
insert into partners(name)
select ('partner ' || t)::text
from generate_series(1, 20) t;

insert into goods_group(name)
select ('goods group ' || t)::text
from generate_series(1, 10) t;

insert into goods(name, id_group)
select ('goods ' || t)::text,
       (select id from goods_group
            where t > 0
        order by random() limit 1)
from generate_series(1, 50) t;

insert into pricelist(name)
select ('price_list ' || t)::text
from generate_series(1, 20) t;

insert into pr_lists(id_price, id_goods, price, ddate)
select (select id from pr_lists
            where t > 0
        order by random() limit 1),
       (select id from goods
            where t > 0
        order by random() limit 1),
        t * 2.5,
       '2020-03-01'::date + t
from generate_series(1, 30) t;

insert into group_part(name)
select ('group parts ' || t)::text
from generate_series(1, 10) t;

insert into ggroup_part(id_ggroup_part, id_goods_group)
select (select id from group_part
            where t > 0
        order by random() limit 1),
       (select id from goods_group
            where t > 0
        order by random() limit 1)
from generate_series(1, 30) t;

insert into price_ggroups(id_price, id_ggroup_part, id_partner)
select (select id from pricelist
            where t > 0
        order by random() limit 1),
       (select id from group_part
            where t > 0
        order by random() limit 1),
       (select id from partners
            where t > 0
        order by random() limit 1)
from generate_series(1, 30) t;


with tmp as
    (select tab.name, tab.id_goods, tab.ddate, tab.id_partner, count(*)
    from (select distinct g.name, plist.id_goods, plist.ddate,
                          pgg.id_partner, plist.id_price
    from pr_lists as plist
        join goods g on g.id = plist.id_goods
        join ggroup_part ggp on ggp.id_goods_group = g.id_group
        join price_ggroups pgg on plist.id_price = pgg.id_price
        and pgg.id_ggroup_part = ggp.id_ggroup_part) AS tab
    group by tab.name, tab.id_goods, tab.ddate, tab.id_partner
    having count(*) > 1)
select g.name, plist.id_goods, plist.ddate, pgg.id_partner,
       string_agg(plist.id_price::text, ',')
from pr_lists as plist
    join goods g on g.id = plist.id_goods
    join ggroup_part ggp on ggp.id_goods_group = g.id_group
    join price_ggroups pgg on plist.id_price = pgg.id_price
    and pgg.id_ggroup_part = ggp.id_ggroup_part
where plist.id_goods in (select id_goods from tmp)
and plist.ddate in (select ddate from tmp)
and pgg.id_partner in (select id_partner from tmp)
group by g.name, plist.id_goods, plist.ddate, pgg.id_partner;


with product as (select plist.id_goods, g.name, g.id_group, ggp.id_ggroup_part,
                        plist.price, plist.ddate, plist.id_price
    from pr_lists as plist
        join goods g on g.id = plist.id_goods
        join ggroup_part ggp on ggp.id_goods_group = g.id_group)
select distinct pr.name, pr.price
from price_ggroups as pgg
    join product pr on pr.id_price = pgg.id_price
    and pgg.id_ggroup_part = pr.id_ggroup_part
where pgg.id_partner = 4 and pr.ddate = '2020-03-04';