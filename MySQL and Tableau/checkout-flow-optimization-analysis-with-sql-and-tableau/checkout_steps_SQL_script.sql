WITH total_carts_created AS (
	SELECT 
		*
    FROM checkout_carts),
total_checkout_attempts AS (
	SELECT
		tc.user_id,
        a.action_name,
        a.action_date
	FROM total_carts_created tc
    LEFT JOIN checkout_actions a
		ON tc.user_id = a.user_id
	WHERE a.action_name LIKE 'checkout%'
		AND a.action_date BETWEEN '2022-07-01' AND '2023-01-31'),
total_successful_attempts AS (
	SELECT
		a.user_id,
        a.action_name,
        a.action_date
	FROM total_checkout_attempts a
    WHERE a.action_name LIKE '%success'
    GROUP BY a.user_id),
count_total_carts AS (	
	SELECT
		c.action_date,
        count(*) as count_total_carts
	FROM total_carts_created c
    GROUP BY c.action_date),
count_total_checkout_attempts AS (
    SELECT
		a.action_date,
        count(*) as count_total_checkout_attempts
	FROM total_checkout_attempts a
    GROUP BY a.action_date),
count_successful_checkout_attempts AS (
    SELECT
		s.action_date,
        count(*) as count_successful_checkout_attempts
	FROM total_successful_attempts s
    GROUP BY s.action_date)
SELECT
	c.action_date,
    count_total_carts,
    IFNULL(count_total_checkout_attempts, 0) count_total_checkout_attempts,
    IFNULL(count_successful_checkout_attempts, 0) count_successful_checkout_attempts
FROM count_total_carts c 
LEFT JOIN count_total_checkout_attempts a
	ON c.action_date = a.action_date
LEFT JOIN count_successful_checkout_attempts s
	ON c.action_date = s.action_date
WHERE c.action_date BETWEEN '2022-07-01' AND '2023-01-31'
ORDER BY c.action_date
;