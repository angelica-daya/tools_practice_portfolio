
## script for sourcing sql-task1-courses.csv

SELECT
	i.course_id,
    i.course_title,
    CEILING(SUM(l.minutes_watched)) total_minutes_watched,
    CEILING(SUM(l.minutes_watched) / COUNT(DISTINCT(l.student_id))) average_minutes,
    COALESCE(number_of_ratings, 0) number_of_ratings,
    COALESCE(average_rating, 0) average_rating
FROM 365_course_info i
LEFT JOIN 365_student_learning l
	ON i.course_id = l.course_id
LEFT JOIN 
	(SELECT
		course_id,
		COUNT(course_rating) number_of_ratings,
		CEILING(AVG(course_rating)) average_rating
	FROM 365_course_ratings
	GROUP BY course_id) r
	ON i.course_id = r.course_id
GROUP BY i.course_id;


## script for creating view for purchases_info

SELECT 
	DISTINCT(purchase_type)
FROM 365_student_purchases;

CREATE VIEW purchases_info AS 
SELECT
	purchase_id,
    student_id,
    purchase_type,
    date_purchased date_start,
    CASE
		WHEN purchase_type = 'Annual' THEN date_add(date_purchased,INTERVAL 1 year)
        WHEN purchase_type = 'Monthly' THEN date_add(date_purchased,INTERVAL 1 month)
        WHEN purchase_type = 'Quarterly' THEN date_add(date_purchased,INTERVAL 3 month)
	END date_end
FROM 365_student_purchases;

## script for sourcing sql-task1-students.csv

SELECT
	i.student_id,
    student_country,
    date_registered,
	date_watched,
    COALESCE(minutes_watched, 0) minutes_watched,
    CASE
		WHEN i.student_id IN (SELECT l.student_id FROM 365_student_learning l) THEN 1
        ELSE 0
	END onboarded,
    CASE
		WHEN i.student_id IN (
					SELECT 
						l.student_id
					FROM 365_student_learning l
					LEFT JOIN purchases_info p
						ON l.student_id = p.student_id AND date_watched BETWEEN date_start and date_end
					WHERE date_watched BETWEEN date_start and date_end)
			THEN 1
        ELSE 0
	END paid
FROM 365_student_info i
LEFT JOIN 365_student_learning l
	ON i.student_id = l.student_id;


