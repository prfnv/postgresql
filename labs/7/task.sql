drop function if exists my_f(date, date, int);
create or replace function my_f(d1 date, d2 date, window_size int)
returns table (ggroup int, ddate date, ssum int, pred double precision) as $$
declare
    curs cursor for select sum(recgoods.volume * goods.length * goods.height * goods.width),
                            goods.g_group, recept.ddate
        from goods
            join recgoods on goods.id = recgoods.goods
            join recept on recept.id = recgoods.subid
        where recept.ddate >= '2019-01-02' and recept.ddate <= '2019-12-31'
        group by goods.g_group, recept.ddate;

    N int := (select count(1)
        from recept
            join recgoods on (recept.id = recgoods.subid)
        where recept.ddate >= d1 and recept.ddate <= d2
        group by recept.client, recgoods.goods, recept.ddate);
    pred double precision;
    cnt  int;
--     cursor
    gg   int;
    dd   date;
    ss   int;


begin
    create temp table t (
        ggroup int,
        ddate  date,
        ssum   int,
        pred   double precision
    );

    if N < window_size then
        insert into t values (Null, Null, Null, Null);
        return query select * from t;
        drop table t;
    end if;
    open curs;
    cnt = 0;
    loop
        fetch curs into gg, dd, ss;
        exit when not found;
        if cnt < window_size then
            insert into t values (gg, dd, ss, null);
        else
            pred = (select sum(t.ssum)
                    from (select ssum, row_number() over () as row_n from t) as t
                    where row_n >= cnt - window_size
                      and row_n <= cnt) / window_size;
            insert into t values (gg, dd, ss, pred);
        end if;
        cnt = cnt + 1;

    end loop;

    close curs;
    return query select * from t;
    drop table t;
end;
$$ language plpgsql;

select * from my_f('2019-01-02', '2019-12-31', 2);