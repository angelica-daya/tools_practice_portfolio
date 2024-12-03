SELECT * FROM checkout_actions;

SELECT 
    user_id, 
    action_date, 
    action_name,
    error_message,
    device
FROM
    checkout_actions
WHERE action_date BETWEEN '2022-07-01' and '2023-01-31' 
	and action_name like '%checkout%'
    and error_message IS NOT NULL
GROUP BY user_id
ORDER BY action_date;