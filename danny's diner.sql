--CASE STUDY QUESTIONS
--https://8weeksqlchallenge.com/case-study-1/

--1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price)
FROM sales, menu
WHERE sales.product_id=menu.product_id
GROUP BY customer_id;



--2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date)
FROM sales
GROUP BY customer_id;



--3. What was the first item from the menu purchased by each customer?
SELECT customer_id, product_name, order_date
FROM (
	SELECT s.customer_id, m.product_name, s.order_date,
		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
	FROM sales s
	JOIN menu m ON s.product_id=m.product_id)
WHERE rn=1;
	



--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(s.product_id) AS total_purchased
FROM sales s, menu m
WHERE s.product_id=m.product_id
GROUP BY m.product_name
ORDER BY total_purchased DESC
LIMIT 1;



--5. Which item was the most popular for each customer?
SELECT customer_id, product_name
FROM ( 
	SELECT s.customer_id, m.product_name, COUNT(s.product_id),
		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS rn
	FROM sales s
	JOIN menu m ON s.product_id=m.product_id
	GROUP BY s.customer_id, m.product_name)
WHERE rn =1;



--6. Which item was purchased first by the customer after they became a member?
WITH ranked_purchase AS(
  SELECT s.customer_id, s.order_date, m.product_name, b.join_date, 
  	ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
  FROM sales s
  JOIN menu m ON s.product_id=m.product_id
  JOIN members b ON s.customer_id=b.customer_id 
  WHERE s.order_date > b.join_date)
SELECT customer_id, product_name, order_date, join_date
FROM ranked_purchase
WHERE rn=1;



--7. Which item was purchased just before the customer became a member?
WITH ranked_purchase AS(
  SELECT s.customer_id, s.order_date, m.product_name, b.join_date, 
  	ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rn
  FROM sales s
  JOIN menu m ON s.product_id=m.product_id
  JOIN members b ON s.customer_id=b.customer_id 
  WHERE s.order_date < b.join_date)
SELECT customer_id, product_name, order_date, join_date
FROM ranked_purchase
WHERE rn=1;



--8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(s.product_id), SUM(m.price)
FROM sales s
JOIN menu m ON s.product_id=m.product_id
JOIN members b ON s.customer_id=b.customer_id 
WHERE s.order_date < b.join_date
GROUP BY s.customer_id;


  
--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, SUM(
	CASE
 	WHEN product_name = 'sushi' THEN price *20 
 	ELSE price*10 
 END) AS points
FROM sales
JOIN menu ON sales.product_id = menu.product_id
GROUP BY customer_id;




/*10. In the first week after a customer joins the program (including their join date) 
they earn 2x points on all items, not just sushi - how many points do customerA and B have at the end of January?*/


WITH joining_bonus AS(
	SELECT s.customer_id, SUM(
		CASE 
			WHEN s.order_date BETWEEN mb.join_date AND mb.join_date + INTERVAL '6 day'
			THEN m.price*20
			ELSE 0
		END) AS bonus
	FROM sales s
	JOIN menu m ON s.product_id=m.product_id
	LEFT JOIN members mb ON s.customer_id = mb.customer_id
	GROUP BY s.customer_id), 

purchase_point AS (
	SELECT a.customer_id, SUM(
		CASE
 			WHEN b.product_name = 'sushi' THEN b.price *20 
 			ELSE b.price*10 
 		END) AS points
	FROM sales a
	JOIN menu b ON a.product_id = b.product_id
	GROUP BY a.customer_id)

SELECT j.customer_id, j.bonus + p.points AS total_points
FROM joining_bonus j 
JOIN purchase_point p ON j.customer_id = p.customer_id
WHERE j.customer_id IN ('A', 'B');



--Bonus Question: Writing queries that output a similar table as the one given.

SELECT s.customer_id, s.order_date, m.product_name, m.price, (
	CASE 
		WHEN s.order_date < mb.join_date THEN 'N'
		ELSE 'Y'
	END) AS member, 
FROM sales s
LEFT JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mb ON s.customer_id = mb.customer_id
ORDER BY s.customer_id, s.order_date; 


--Bonus Question 2

WITH all_data AS(
	SELECT s.customer_id, s.order_date, m.product_name, m.price, 
		CASE 
			WHEN s.order_date < mb.join_date THEN 'N'
			ELSE 'Y'
		END AS member 
	FROM sales s
	LEFT JOIN menu m ON s.product_id = m.product_id
	LEFT JOIN members mb ON s.customer_id = mb.customer_id)

SELECT customer_id, order_date, product_name, price, member, 
	CASE 
			WHEN member = 'N' THEN Null
			ELSE DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date)
		END AS ranking	
FROM all_data
ORDER BY customer_id, order_date;
