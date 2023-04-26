USE restaurant_management;

DROP PROCEDURE IF EXISTS fill_shifts;
DELIMITER |
CREATE PROCEDURE fill_shifts (IN start_date DATETIME)
BEGIN
	DECLARE curr_date DATETIME;
    SET curr_date = start_date;
    
	WHILE (MONTH(curr_date) = MONTH(start_date))
    DO
		INSERT INTO restaurant_management.shifts (start_time, end_time)
        VALUES (curr_date, DATE_ADD(curr_date, INTERVAL 4 HOUR)),
        (DATE_ADD(curr_date, INTERVAL 4 HOUR), DATE_ADD(curr_date, INTERVAL 8 HOUR)),
        (DATE_ADD(curr_date, INTERVAL 8 HOUR), DATE_ADD(curr_date, INTERVAL 12 HOUR)),
        (curr_date, DATE_ADD(curr_date, INTERVAL 6 HOUR)),
        (DATE_ADD(curr_date, INTERVAL 6 HOUR), DATE_ADD(curr_date, INTERVAL 12 HOUR)),
        (curr_date, DATE_ADD(curr_date, INTERVAL 8 HOUR)),
        (DATE_ADD(curr_date, INTERVAL 4 HOUR), DATE_ADD(curr_date, INTERVAL 12 HOUR)),
        (curr_date, DATE_ADD(curr_date, INTERVAL 12 HOUR));
		SET curr_date = DATE_ADD(curr_date, INTERVAL 1 DAY);
	END WHILE;
END
|
DELIMITER ;

CALL fill_shifts('2023-02-01 10:00:00');

#..........................................................................................

DROP PROCEDURE IF EXISTS calculate_bill;
DELIMITER |
CREATE PROCEDURE calculate_bill (IN reservation_id INT, IN products_array JSON)
BEGIN
	DECLARE num_of_products INT;
    DECLARE curr_product INT;
    DECLARE bill FLOAT;
    
    DROP TABLE IF EXISTS temp_products;
	CREATE TEMPORARY TABLE temp_products(
	id INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	price FLOAT NOT NULL);
    
    SET num_of_products = JSON_LENGTH(products_array);
    SET curr_product = 0;
    WHILE (curr_product != num_of_products)
    DO
		INSERT INTO temp_products (name, price)
		SELECT name, price
		FROM products
		WHERE id = JSON_EXTRACT(products_array, CONCAT('$[', curr_product, ']'));
        SET curr_product = curr_product + 1;
    END WHILE;
    
    SELECT * FROM temp_products; #for test purposes
    SELECT SUM(price) INTO bill FROM temp_products;
    INSERT INTO bills (reservation_id, amount)
    VALUES (reservation_id, bill);
    
    DROP TABLE temp_products;

END
|
DELIMITER ;

CALL calculate_bill(1, '[1, 1, 2, 3]');

#..........................................................................................