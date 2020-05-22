select distinct key1, key2,
                (select sum(data1)) from t as t1
                where t1.key1 = t2.key1 and t1.key2 = t2.key2) as ssum,
                (select min(data2)) from t as t1
                where t1.key1 = t2.key1 and t1.key2 = t2.key2) as mmin
from t as t2
