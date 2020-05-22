select ndoc, ddate, g.name, cl.name as client,
        recg.volume * recg.price as sum,
        avg(recg.volume * recg.price) over (partition by goods
            order by extract(month from ddate)) as avg_gmonth,
        sum(recg.volume * recg.price) over (partition by ddate
            order by recg.volume * recg.price) as sum_of_day
from recept rec
      join recgoods recg on rec.id = recg.id
      join clients cl on rec.clients = cl.id
      join goods g on recg.goods = g.id