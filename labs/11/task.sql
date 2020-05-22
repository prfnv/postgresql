with recursive temp as (
    select g1.id, g1.name, g1.parent, g2.name parent_name
    from client_groups g1
        join client_groups g2 on g2.id = g1.parent
    union all
    select g3.id, g3.name, temp.parent, g4.name
    from client_groups as g3
        join temp on temp.id = g3.parent
        join client_groups g4 on g4.id = temp.parent)


select distinct client.id, client.name, client.client_groups, client_groups.name
from client
    join client_groups on client.client_groups = client_groups.id
union all
select client.id, client.name, temp.parent, temp.parent_name
from client
    join temp on temp.id = client.client_groups
order by id;