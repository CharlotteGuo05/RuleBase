with upvote_scores as(
    select p.uid as creator_id, count(*) as upvote_score from upvotes u
    join posts p
    on p.pid = u.pid
    where u.uid = :'current_uid'
    --use \set current_uid <user id> to input the user
    group by p.uid
),
downvote_scores as(
    select p.uid as creator_id, count(*) as downvote_score from downvotes d
    join posts p
    on p.pid = d.pid
    where d.uid = :'current_uid'
    group by p.uid
)
select p.uid, (coalesce(up.upvote_score, 0) - coalesce(dw.downvote_score, 0)) as score
from posts p
left join upvote_scores up ON p.uid = up.creator_id
left join downvote_scores dw ON p.uid = dw.creator_id
;

