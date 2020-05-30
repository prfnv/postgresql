drop table if exists remains;
drop table if exists irlink;
create table remains(
  id int,
  subid int,
  goods int references goods(id),
  storage int references storage(id),
  ddate date,
  volume int,
  primary key(id, subid)
);

create table irlink(
  id serial,
  i_id int references income(id),
  i_subid int,
  r_id int references recept(id),
  r_subid int,
  goods int references goods(id),
  volume int,
  primary key(id)
);


create or replace function Deleted() returns trigger as
$$
declare
    income_storage int;
    income_date    date;
    item           record;
    remain         record;
    dif_value      int;
    remain_value   int;
    irlink_sum     int;
begin
    select storage, ddate
    into income_storage, income_date
    from income
    where id = old.id;

    delete from remains where id = old.id and subid = old.subid;

    create temp table irl
    (
        id      integer,
        i_id    integer,
        i_subid integer,
        r_id    integer,
        r_subid integer,
        r_date  date,
        goods   integer,
        volume  integer
    );

    insert into irl(id, i_id, i_subid, r_id, r_subid, r_date, goods, volume)
    select irlink.id,
           i_id,
           i_subid,
           r_id,
           r_subid,
           r.ddate,
           goods,
           volume
    from irlink
             join recept r on irlink.r_id = r.id
    where i_id = old.id
      and i_subid = old.subid
      and goods = old.goods;

    if ((select count(*) from irl) > 0) then
        select sum(volume)
        into irlink_sum
        from irl;
        dif_value = irlink_sum;
        for item in select * from irl
            loop
                create temp table rms
                (
                    id      integer,
                    subid   integer,
                    goods   integer,
                    storage integer,
                    ddate   date,
                    volume  integer
                );

                insert into rms (id, subid, goods, storage, ddate, volume)
                select id, subid, goods, storage, ddate, volume
                from remains
                where storage = income_storage
                  and goods = old.goods
                  and (ddate < item.r_date or ddate = item.r_date)
                order by ddate desc;

                if (item.volume < dif_value) then
                    for remain in select * from rms
                        loop
                            if (item.volume < remain.volume) then
                                update remains
                                set volume = (remain.volume - item.volume)
                                where id = remain.id
                                  and subid = remain.subid;
                                update irlink
                                set i_id    = remain.id,
                                    i_subid = remain.subid
                                where irlink.id = item.id;
                                item.volume = 0;
                            else
                                insert into irlink(i_id, i_subid, r_id, r_subid, goods, volume)
                                values (remain.id, remain.subid, item.r_id, item.r_subid, item.goods,
                                        remain.volume);

                                update irlink
                                set volume = (irlink.volume - remain.volume)
                                where id = item.id;
                                item.volume = item.volume - remain.volume;

                                delete from remains where id = remain.id and subid = remain.subid;
                            end if;
                            exit when item.volume = 0;
                        end loop;
                    dif_value = dif_value - item.volume;
                else
                    for remain in select * from rms
                        loop
                            if (dif_value < remain.volume) then
                                update remains
                                set volume = (remain.volume - dif_value)
                                where id = remain.id
                                and subid = remain.subid;

                                update irlink
                                set volume = (irlink.volume - dif_value)
                                where irlink.id = item.id;

                                insert into irlink(i_id, i_subid, r_id, r_subid, goods, volume)
                                values (remain.id, remain.subid, item.r_id, item.r_subid, remain.goods, dif_value);
                                dif_value = 0;
                            else
                                insert into irlink(i_id, i_subid, r_id, r_subid, goods, volume)
                                values (remain.id, remain.subid, item.r_id, item.r_subid, item.goods,
                                        remain.volume);

                                update irlink
                                set volume = (irlink.volume - remain.volume)
                                where id = item.id;

                                dif_value = dif_value - remain.volume;
                                delete from remains where id = remain.id and subid = remain.subid;
                            end if;
                            exit when dif_value = 0;
                        end loop;
                end if;
                delete from rms where true;
                exit when dif_value = 0;
            end loop;
        drop table if exists rms;
    end if;
    drop table irl;
    delete from irlink where volume = 0;
    return old;
end
$$ language plpgsql;

create or replace function Deleting() returns trigger as
$$
declare
    income_storage integer;
    income_date    date;
    sum            integer;
begin
    select recept.storage, recept.ddate
    into income_storage, income_date
    from recept
    where recept.id = new.id;

    sum = (
        select sum(volume)
        from remains
        where remains.goods = new.goods
          and remains.ddate < income_date
          and remains.storage = income_storage
    );

    return old;
end
$$ language plpgsql;

drop trigger if exists onDeleted on incgoods;
drop trigger if exists onDeleting on incgoods;
create trigger onDeleted
    after delete
    on incgoods
    for each row
execute procedure Deleted();

create trigger onDeleting
    before delete
    on incgoods
    for each row
execute procedure Deleting();