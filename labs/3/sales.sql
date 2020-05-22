select client.address, recept.ddate, recept.ndoc, storage.name,
       goods.name, goods.weight, cassa_income.summ
from cassa_income
         inner join client on (cassa_income.client = client.id)
         inner join city on (client.city = city.id)
         inner join recept on (client.id = recept.client)
         inner join storage on (recept.storage = storage.id)
         inner join recgoods on (recept.id = recgoods.id)
         inner join goods on (recgoods.goods = goods.id)
WHERE recept.ddate > '01-02-2020'
  AND recept.ddate < '29-02-2020'
  AND city.name = 'Moscow'
  AND date_part('year', cassa_income.ddate) = '2019'