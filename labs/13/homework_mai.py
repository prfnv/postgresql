def moving_average(dateFrom: str, dateTo: str, window_size: int) -> pd.DataFrame:
    SQL = '''
        SELECT goods.g_group goods_group,
             recept.ddate date,
             sum(recgoods.volume * goods.length * goods.height * goods.width) sum
        FROM goods
               JOIN recgoods ON goods.id = recgoods.goods
               JOIN recept ON recept.id = recgoods.subid
        WHERE recept.ddate >= %(mindate)s
        AND recept.ddate <= %(maxdate)s
        GROUP BY goods.g_group, recept.ddate
    '''

    df = pd.read_sql(
        SQL,
        engine,
        params={'mindate': dateFrom, 'maxdate': dateTo},
        parse_dates={'recept.ddate': dict(format='%Y%m%d')}
    )

    N = df.shape[0]
    if (N < window_size):
        raise ValueError(f'Invalid windows size > {N}')

    dfs = df.set_index(['goods_group'])
    dfs.drop('date', axis=1, inplace=True)
    dfs['sum'] = dfs['sum'].shift(1)
    dfs = dfs.groupby(level=['goods_group']).rolling(window=window_size).mean()
    dfs.reset_index(level=[1], inplace=True)
    dfs.reset_index(drop=True, inplace=True)
    names = ['goods_group', 'date', 'sum']
    df.columns = names
    df['prediction'] = dfs['sum']
    df.to_sql('prediction', engine, if_exists='replace')

    return df


result = moving_average('20200102', '20201231', 2)
print(result.head(30))