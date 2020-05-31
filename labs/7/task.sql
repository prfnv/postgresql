drop function if exists moving_average(d1 date, d2 date);
create or replace function moving_average(d1 date, d2 date)
    returns table (goods_group int, date date, sum int, prediction double precision) as $$
declare
    cursor cursor for select goods.g_group, recept.ddate,
                             sum(recgoods.volume * goods.length * goods.height * goods.width)
        from goods
            join recgoods on goods.id = recgoods.goods
            join recept on recept.id = recgoods.subid
        where recept.ddate >= d1 and recept.ddate <= d2
        group by goods.g_group, recept.ddate
        order by goods.g_group, recept.ddate;

    cnt        int := 0;
    temp_cnt   int := 0;
    pred       double precision;
    prev_group int;
--
    g_group    int;
    date       date;
    sum        int;


begin
    create TEMP table tmp
    (
        goods_group int,
        date        date,
        sum         int
    );
    create TEMP table to_return
    (
        goods_group int,
        date        date,
        sum         int,
        prediction  double precision
    );
    open cursor;
    loop
        fetch cursor into goods_group, date, sum;
        exit when not found;

        if goods_group != prev_group then
            temp_cnt := 1;
            truncate tmp;
            insert into tmp values (goods_group, date, sum);
            insert into to_return (goods_group, date, sum, prediction)
            values (goods_group, date, sum, sum);
        else
            if temp_cnt < 2 then
                temp_cnt = temp_cnt + 1;
                insert into to_return (goods_group, date, sum, prediction)
                values (goods_group, date, sum, sum);
                insert into tmp values (goods_group, date, sum);
            else
                temp_cnt = temp_cnt + 1;
                insert into to_return (goods_group, date, sum, prediction)
                values (goods_group, date, sum, (select avg(tmp.sum) from tmp));
                delete from tmp where tmp.date in (select tmp.date from tmp order by tmp.date ASC limit 1);
                insert into tmp values (goods_group, date, sum);
            end if;
        end if;
        prev_group = goods_group;
        cnt := cnt + 1;
    end loop;

    close cursor;
    return query select * from to_return;
    drop table to_return;
    drop table tmp;
end
$$ language plpgsql;

select * from moving_average('2020-02-01', '2020-12-31');