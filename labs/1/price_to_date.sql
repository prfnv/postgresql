create table products
(
    id serial PRIMARY KEY,
    id_product int NOT NULL,
    price int NOT NULL,
    date date NOT NULL
);

insert into products(id_product, price, date)
values (1, 120, '2018-06-06'),
       (2, 130, '2018-07-06'),
       (3, 140, '2018-02-04'),
       (4, 150, '2019-06-06'),
       (2, 160, '2018-10-05'),
       (3, 170, '2018-12-06'),
       (1, 180, '2019-01-10'),
       (5, 190, '2018-12-06'),
       (1, 200, '2018-10-12'),
       (2, 210, '2019-02-06'),
       (3, 220, '2019-03-15');

select price from products as p1
where p1.id_product = 2 and date <= '2018-10-04'
and not EXISTS(
    select id_product, price, date from products as p2
    where p2.id_product = p1.id_product
    and p1.date < p2.date and p2.date <= '2018-10-04'
);

-- Реализация с помощью LIMIT
select price from products
where id_product = 2 and date <= '2018-10-04'
order by date desc
limit 1;
