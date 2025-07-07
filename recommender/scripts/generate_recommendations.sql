WITH post_distance AS (
    SELECT
        p.pid,
        earth_distance(
            ll_to_earth(u.last_location[1], u.last_location[2]),
            ll_to_earth(p.location[1], p.location[2])
        ) AS raw_distance
    FROM posts p
    JOIN users u ON u.uid = :'current_uid'
),
normalized_distance AS (
    SELECT
        pid,
        1 - (raw_distance / MAX(raw_distance) OVER ()) AS norm_distance
    FROM post_distance
),
vote_counts AS (
    SELECT
        p.pid,
        COALESCE(up.up_count, 0) AS positive,
        COALESCE(down.down_count, 0) AS negative
    FROM posts p
    LEFT JOIN (
        SELECT pid, COUNT(*) AS up_count FROM upvotes GROUP BY pid
    ) up ON p.pid = up.pid
    LEFT JOIN (
        SELECT pid, COUNT(*) AS down_count FROM downvotes GROUP BY pid
    ) down ON p.pid = down.pid
),
wilson_score AS (
    SELECT
        pid,
        (
            (positive + 0.5 * 1.9208) / (positive + negative) -
            1.96 * sqrt((positive * negative) / (positive + negative) + 0.9604) / (positive + negative)
        ) / (1 + 3.8416 / (positive + negative)) AS score
    FROM vote_counts
    WHERE (positive + negative) > 0
),
normalized_wilson AS (
    SELECT
        pid,
        score / MAX(score) OVER () AS norm_wilson
    FROM wilson_score
),
friends AS (
    SELECT
        p.pid,
        CASE WHEN f.friend IS NOT NULL THEN 1 ELSE 0 END AS is_friend
    FROM posts p
    LEFT JOIN friends f ON p.uid = f.friend AND f.uid = :'current_uid'
),
engagement_raw AS (
    WITH up AS (
        SELECT p.uid AS creator_id, COUNT(*) AS upvote_score
        FROM upvotes u JOIN posts p ON u.pid = p.pid
        WHERE u.uid = :'current_uid'
        GROUP BY p.uid
    ),
    down AS (
        SELECT p.uid AS creator_id, COUNT(*) AS downvote_score
        FROM downvotes d JOIN posts p ON d.pid = p.pid
        WHERE d.uid = :'current_uid'
        GROUP BY p.uid
    )
    SELECT
        p.pid,
        COALESCE(up.upvote_score, 0) - COALESCE(down.downvote_score, 0) AS raw_engagement
    FROM posts p
    LEFT JOIN up ON p.uid = up.creator_id
    LEFT JOIN down ON p.uid = down.creator_id
),
normalized_engagement AS (
    SELECT
        pid,
        (raw_engagement - MIN(raw_engagement) OVER ()) / 
        NULLIF((MAX(raw_engagement) OVER () - MIN(raw_engagement) OVER ()), 0) AS norm_engagement
    FROM engagement_raw
),
already_recommended AS (
    SELECT pid FROM recommendations WHERE uid = :'current_uid'
),
combined AS (
    SELECT
        p.pid,
        COALESCE(d.norm_distance, 0) AS distance_score,
        COALESCE(w.norm_wilson, 0) AS popularity_score,
        COALESCE(f.is_friend, 0) AS friend_score,
        COALESCE(e.norm_engagement, 0.5) AS engagement_score,
        CASE WHEN r.pid IS NOT NULL THEN 0.5 ELSE 0 END AS penalty
    FROM posts p
    LEFT JOIN normalized_distance d ON p.pid = d.pid
    LEFT JOIN normalized_wilson w ON p.pid = w.pid
    LEFT JOIN friends f ON p.pid = f.pid
    LEFT JOIN normalized_engagement e ON p.pid = e.pid
    LEFT JOIN already_recommended r ON p.pid = r.pid
),
scored AS (
    SELECT
        pid,
        ROUND((
            10 * (
                0.4 * distance_score +
                0.3 * popularity_score +
                0.2 * friend_score +
                0.1 * engagement_score
            ) - penalty
        ) ::numeric, 2) AS final_score
    FROM combined
)
-- Insert top 10 scores into recommendations table
INSERT INTO recommendations (uid, pid, score)
SELECT :'current_uid', pid, final_score
FROM scored
ORDER BY final_score DESC
LIMIT 10;
