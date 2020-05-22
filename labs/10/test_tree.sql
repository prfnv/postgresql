with RECURSIVE tmp as (
	select g1.id, g1.name, g1.parent, gp.name gp_name
	from goods_groups g
	    join goods_groups gp on gp.id = g.parent
	union all
	    select goods_groups.id, goods_groups.name, tmp.parent, gp.name
	    from goods_groups
            join tmp on tmp.id = goods_groups.parent
			join goods_groups gp on gp.id = tmp.parent)

select * from tmp;