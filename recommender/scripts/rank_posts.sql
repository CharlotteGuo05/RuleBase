-- scripts/rank_posts.sql
-- Calculate the 95% Wilson score lower bound per post and list the top 20.

WITH vote_counts AS (
  SELECT
    p.pid AS post_id,
    COALESCE(u.up_count, 0) AS positive,
    COALESCE(d.down_count, 0) AS negative
  FROM posts p


  LEFT JOIN (
    SELECT pid, COUNT(*) AS up_count
    FROM upvotes
    GROUP BY pid
  ) u ON u.pid = p.pid


  LEFT JOIN (
    SELECT pid, COUNT(*) AS down_count
    FROM downvotes
    GROUP BY pid
  ) d ON d.pid = p.pid
)

SELECT
  vc.post_id,
  vc.positive,
  vc.negative,
  (
    (vc.positive + 0.5 * 1.9208) /
    (vc.positive + vc.negative)
    -
    1.96 * SQRT(
      (vc.positive * vc.negative) /
      (vc.positive + vc.negative)
      + 0.9604
    ) / (vc.positive + vc.negative)
  ) / (1 + 3.8416 / (vc.positive + vc.negative)) AS ci_lower_bound
FROM vote_counts vc
WHERE (vc.positive + vc.negative) > 0
ORDER BY ci_lower_bound DESC
LIMIT 30;
