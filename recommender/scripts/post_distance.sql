select
p.pid,
earth_distance(
ll_to_earth(u.last_location[1], u.last_location[2]),
ll_to_earth(p.location[1], p.location[2])
) AS post_distance
FROM posts p
JOIN users u on u.uid = :'current_uid'
ORDER BY post_distance ASC;
--use \set current_uid <user id> to input the user