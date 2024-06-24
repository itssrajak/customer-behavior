
USE proj;

CREATE TABLE sales(
	customer_id VARCHAR(1),
	order_date DATE,
	product_id INTEGER
);

INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', 1),
	('A', '2021-01-01', 2),
	('A', '2021-01-07', 2),
	('A', '2021-01-10', 3),
	('A', '2021-01-11', 3),
	('A', '2021-01-11', 3),
	('B', '2021-01-01', 2),
	('B', '2021-01-02', 2),
	('B', '2021-01-04', 1),
	('B', '2021-01-11', 1),
	('B', '2021-01-16', 3),
	('B', '2021-02-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-07', 3);

CREATE TABLE menu(
	product_id INTEGER,
	product_name VARCHAR(5),
	price INTEGER
);

INSERT INTO menu
	(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);

CREATE TABLE members(
	customer_id VARCHAR(1),
	join_date DATE
);

-- Still works without specifying the column names explicitly
INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09');

-- 1. What is the total amount each customer spent in the restaurant?

SELECT s.customer_id, sum(m.price) AS total_spent
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
GROUP BY 1;

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(distinct order_date) 
FROM sales
GROUP BY 1;

-- 3. What was the first item from the menu purchased by each customer?

WITH first_purchase as (
	SELECT customer_id, MIN(order_date) purchase_date
	FROM sales 
	GROUP BY 1)

SELECT fp.customer_id, fp.purchase_date, m.product_name
FROM first_purchase fp
JOIN sales s
	ON fp.purchase_date = s.order_date
    AND fp.customer_id = s.customer_id
JOIN menu m
	ON s.product_id = m.product_id
GROUP BY 1, 2, 3;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
 
SELECT m.product_name, COUNT(s.product_id) total_purchase
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
GROUP by 1
ORDER BY 2 DESC
LIMIT 1;

-- -- 5. Which item was the most popular for each customer?
WITH most_popular AS (
	SELECT s.customer_id, 
		m.product_name,
		COUNT(s.product_id) total_purchase,
		DENSE_RANK() OVER(
			PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC
		) as rk
	FROM sales s
	JOIN menu m
		ON s.product_id = m.product_id
	GROUP by 1, 2 )

SELECT customer_id, product_name, total_purchase
FROM most_popular
WHERE rk = 1;



-- -- 6. Which item was purchased first by the customer after they became a member?
WITH first_purchase_after_membership as (
	SELECT m.customer_id, MIN(s.order_date) purchase_date
	FROM sales s
    JOIN members m
		on s.customer_id = m.customer_id
	WHERE s.order_date >= m.join_date
	GROUP BY 1)
    
SELECT fp.customer_id, fp.purchase_date, m.product_name
FROM first_purchase_after_membership fp
JOIN sales s
	ON fp.purchase_date = s.order_date
	AND fp.customer_id = s.customer_id
JOIN menu m
	ON s.product_id = m.product_id
ORDER BY fp.customer_id;


-- 7. Which item was purchased just before the customer became a member?

WITH last_purchase_before_membership as (
	SELECT m.customer_id, MAX(s.order_date) purchase_date
	FROM sales s
    JOIN members m
		on s.customer_id = m.customer_id
	WHERE s.order_date < m.join_date
	GROUP BY 1)
    
SELECT lp.customer_id, lp.purchase_date, m.product_name
FROM last_purchase_before_membership lp
JOIN sales s
	ON lp.purchase_date = s.order_date
	AND lp.customer_id = s.customer_id
JOIN menu m
	ON s.product_id = m.product_id
ORDER BY lp.customer_id;


-- -- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(m.product_id) total_items, SUM(m.price) total_spent
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
JOIN members mb
	ON s.customer_id = mb.customer_id
    AND s.order_date < mb.join_date
GROUP BY 1
ORDER BY 1;


-- -- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id,
	SUM(CASE 
			WHEN product_name = 'sushi' then m.price * 20 ELSE m.price * 10 
		END) AS points
FROM menu m
JOIN sales s
	ON m.product_id = s.product_id
GROUP BY 1;


-- /* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January?*/

SELECT s.customer_id, 
	SUM(CASE 
			WHEN s.order_date BETWEEN mb.join_date AND DATE_ADD(mb.join_date, INTERVAL 7 DAY) 
            then m.price * 20
		END) AS points
FROM menu m
JOIN sales s
	ON m.product_id = s.product_id
JOIN members mb
	ON mb.customer_id = s.customer_id
    AND s.order_date <= '2021-01-31'
GROUP BY 1
ORDER BY 1; 


-- -- 11. Recreate the table output using the available data

SELECT s.customer_id, s.order_date, m.product_name, m.price, 
	CASE
		WHEN s.order_date >= mb.join_date then 'Y' else 'N'
	END AS members
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
LEFT JOIN members mb
	ON mb.customer_id = s.customer_id;
