with date_t as
   (select ('2020-03-01')::date + day as ddate
    from generate_series(0, 13) day)
select incs.ddate,
       incs.storage,
       incs.goods,
       incs.inc_vol,
       recs.rec_vol,
case when recs.rec_vol is null then incs.inc_vol
     when incs.inc_vol is null then - recs.rec_vol
else (incs.inc_vol - recs.rec_vol)
end as remnants
from (select date_t.ddate, inc.storage, incgoods.goods, sum(incgoods.volume) inc_vol
    from income inc
    join incgoods on incgoods.id = inc.id
    join date_t on date_t.ddate >= inc.ddate
    group by date_t.ddate, inc.storage, incgoods.goods) as incs
full join
   (select date_t.ddate, rec.storage, recgoods.goods, sum(recgoods.volume) rec_vol
    from recept rec
    join recgoods on recgoods.id=rec.id
    join date_t on rec.ddate<= date_t.ddate
    group by date_t.ddate, rec.storage, recgoods.goods) AS recs
on recs.storage = incs.storage
and recs.goods = incs.goods
and recs.ddate = incs.ddate
order by incs.ddate, incs.storage