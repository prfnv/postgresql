import pandas as pd
from sqlalchemy import create_engine

base = 'localhost:5432/postgres'
name_pass = 'login:password'
pref = 'postgresql'
engine = create_engine(f"{pref}://{name_pass}@{base}")


def moving_average(d1: str, d2: str, window_size: int) -> pd.DataFrame:
    SQL = '''
        SELECT
            goods.g_group, sum(recgoods.volume * goods.length * goods.height * goods.width) s, recept.ddate
        FROM goods 
            JOIN recgoods on goods.id = recgoods.goods
            JOIN recept on recept.id = recgoods.subid
        WHERE 
            recept.ddate >= %(mindate)s
        AND 
            recept.ddate <= %(maxdate)s
        GROUP BY 
            goods.g_group, recept.ddate
        '''

    df = pd.read_sql(SQL,
                     engine,
                     params={'mindate': d1, 'maxdate': d2},
                     parse_dates={'recept.ddate': dict(format='%Y%m%d'), })

    N = df.shape[0]
    if (N < window_size):
        raise ValueError(f"Invalid windows size > {N}")

    moving_average = df.s.rolling(window=window_size).mean()
    names = ['goods', 'sum', 'recept']
    df.columns = names
    df['prediction'] = moving_average
    df.to_sql('prediction', engine, if_exists='replace')

    return df


result = moving_average('20200102', '20201231', 2)
print(result.head(30))
