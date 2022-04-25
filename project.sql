/* Part 1: Explore the Database*/

SELECT 'Customers' AS table_name,
				  'customer data' AS description,
				 13 AS number_of_attributes, 
				 COUNT  (*)  AS number_of_rows
   FROM customers

UNION ALL

SELECT 'Products' AS table_name, 
				  'a list of scale model cars' AS description,
				  9 AS number_of_attributes,
				  COUNT (*) AS number_of_rows
    FROM products

UNION ALL

SELECT 'ProductLines' AS table_name, 
				  'a list of product line categories' AS description,
				  4 AS number_of_attributes, 
				  COUNT (*) AS number_of_rows
    FROM productlines
	
UNION ALL

SELECT 'Orders' AS table_name, 
				  'sales orders of the customers' AS description,
				  7 AS number_of_attributes, 
				  COUNT (*) AS number_of_rows
    FROM orders

UNION ALL

SELECT 'OrderDetails' AS table_name, 
				  'sales order line for each sales order' AS description,
				  5 AS number_of_attributes, 
				  COUNT (*) AS number_of_rows
    FROM orderdetails
	
UNION ALL

SELECT 'Payments' AS table_name, 
				  'payment records of the customers' AS description,
				  4 AS number_of_attributes, 
				  COUNT (*) AS number_of_rows
    FROM payments	
	
UNION ALL

SELECT 'Employees' AS table_name, 
				  'all employee information' AS description,
				  8 AS number_of_attributes, 
				  COUNT (*) AS number_of_rows
    FROM employees		

UNION ALL

SELECT 'Offices' AS table_name, 
				  'sales office information' AS description,
				  9 AS number_of_attributes, 
				  COUNT (*) AS number_of_rows
    FROM offices	;


/* Part 2: Analysis*/
/* Question 1: Which products should we order more of or less of?*/

/* Ans:  This question refers to inventory reports, including low stock and product performance. 
This will optimize the supply and the user experience by preventing the best-selling products from going out-of-stock.
The low stock represents the quantity of each product sold divided by the quantity of product in stock. 
We can consider the twenty highest low_stock rates. These will be the top twenty products that are (almost) out-of-stock.
The product performance represents the sum of sales per product.
Priority products for restocking are those with high product performance that are on the brink of being out of stock.

low_stock = SUM(quantityOrdered)/quantityInStock
product_performance = SUM(quantityOrdered * priceEach)

*/

-- Low stock
WITH 
low_stock_table AS (
SELECT productCode, 
                 productName, 
				 productLine, 
				 ROUND (sum_ordered*1.0/quantityInStock,2) AS low_stock
   FROM   ( SELECT p.productCode, 
                                       p.productName, 
									   p.productLine, 
									   p.quantityInStock, 
									   SUM(quantityOrdered)  AS sum_ordered
					     FROM products  p
					       JOIN orderdetails o
					           ON p.productCode = o.productCode
				      GROUP BY p.productCode) AS po
 ORDER BY low_stock DESC
  LIMIT 20
),

-- Product performance
p_perf_table AS(
SELECT productCode, SUM(quantityOrdered*priceEach) AS p_perf
   FROM orderdetails
 GROUP BY productCode
 ORDER BY p_perf DESC
  LIMIT 20
)
SELECT productCode, productName, productLine, low_stock
    FROM low_stock_table
WHERE productCode IN (SELECT productCode FROM p_perf_table);



/* Question 2: How should we tailor marketing and communication strategies to customer behaviors?*/
/*Ans: We could organize some events to drive loyalty for the VIPs and launch a campaign for the less engaged.*/

-- Top 5 VIP customers that bring in the most profit for the store.
WITH 
vip AS (
SELECT customerNumber , SUM(sum_profit) AS profit_per_cust
	FROM  (SELECT orderNumber, SUM(profit) AS sum_profit
					   FROM (SELECT o.orderNumber, o.quantityOrdered *(o.priceEach - p.buyPrice) AS profit
									      FROM orderdetails o
										    JOIN products p
											     ON p.productCode = o.productCode)
				    GROUP BY orderNumber) AS odp
     JOIN orders o
         ON o.orderNumber = odp.orderNumber
GROUP BY customerNumber
ORDER BY profit_per_cust DESC
LIMIT 5
)
SELECT c.contactLastName, c.contactFirstName, c.city, c.country, v.profit_per_cust AS profit
    FROM customers c
	  JOIN vip v
	      ON c.customerNumber = v.customerNumber;

-- Top 5 Least-engaged customers that bring in least profit.

WITH 
least_engaged AS (
SELECT customerNumber , SUM(sum_profit) AS profit_per_cust
	FROM  (SELECT orderNumber, SUM(profit) AS sum_profit
					   FROM (SELECT o.orderNumber, o.quantityOrdered *(o.priceEach - p.buyPrice) AS profit
									      FROM orderdetails o
										    JOIN products p
											     ON p.productCode = o.productCode)
				    GROUP BY orderNumber) AS odp
     JOIN orders o
         ON o.orderNumber = odp.orderNumber
GROUP BY customerNumber
ORDER BY profit_per_cust 
LIMIT 5
)

SELECT c.contactLastName, c.contactFirstName, c.city, c.country, l.profit_per_cust AS profit
    FROM customers c
	  JOIN least_engaged l
	      ON c.customerNumber = l.customerNumber
		  
   ORDER BY profit_per_cust;



/* Question 3: How much can we spend on acquiring new customers?*/
/*Ans: LTV tells us how much profit an average customer generates during their lifetime with our store. 
We can use it to predict our future profit. 
So, if we get ten new customers next month, we'll earn 390,395 dollars, 
and we can decide based on this prediction how much we can spend on acquiring new customers.*/
WITH 

money_in_by_customer_table AS (
SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
    FROM products p
      JOIN orderdetails od
           ON p.productCode = od.productCode
      JOIN orders o
           ON o.orderNumber = od.orderNumber
  GROUP BY o.customerNumber
)

SELECT AVG(mc.revenue) AS ltv
   FROM money_in_by_customer_table mc;
  
	
