SELECT
  p.pid,
  CASE 
    WHEN f.friend IS NOT NULL THEN 1
    ELSE 0
  END AS is_friend
FROM posts p


LEFT JOIN friends f
    ON p.uid = f.friend
    AND f.uid = :'current_uid'
-- use \set current_uid <user id> to input the user
;