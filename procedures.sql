USE restaurant_management;

#..........................................................................................

#Procedure to fill the shifts table with the default 4, 6, 8, 12 hour shifts
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

#Calculates the bill on certain reservation by taking an array of products' ids
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
    
    SET bill = bill - (SELECT avance_amount
						FROM reservations
                        WHERE reservations.id = reservation_id); #Substract the avance from the bill
    
    INSERT INTO bills (reservation_id, amount)
    VALUES (reservation_id, bill);
    
    DROP TABLE temp_products;

END
|
DELIMITER ;

CALL calculate_bill(1, '[1, 1, 2, 3]');

#..........................................................................................

#Procedure that associates the waiter with least amount of tables taken for a shift with a reservation
DROP PROCEDURE IF EXISTS add_waiter_to_reservation;
DELIMITER |
CREATE PROCEDURE add_waiter_to_reservation(IN reservation_date DATETIME, OUT worker_id INT)
BEGIN
	SELECT worker_shifts.worker_id INTO worker_id
    FROM (SELECT worker_id
			FROM workers_shifts
			JOIN shifts ON
			workers_shifts.shift_id = shifts.id
			JOIN workers ON
			workers_shifts.worker_id = workers.id
			JOIN worker_type ON
			workers.type_id = worker_type.id
			WHERE (reservation_date BETWEEN shifts.start_time AND shifts.end_time)
			AND (worker_type.type = 'waiter')) AS waiters_on_shift 
			WHERE waiters_on_shift.reservations_taken = (SELECT MIN(reservations_taken) FROM waiters_on_shift);
END
|
DELIMITER ;

#..........................................................................................

#Function that calculates the work hours of a worker by given month and year
#It's used in the following procedure that calculates salaries
DROP FUNCTION IF EXISTS calculate_work_hours;
DELIMITER |
CREATE FUNCTION calculate_work_hours(worker_id INT, month INT, year INT)
RETURNS INT
READS SQL DATA
BEGIN
	DECLARE work_hours INT;
    DECLARE temp_start_time DATETIME;
    DECLARE temp_end_time DATETIME;
    DECLARE finished INT;
    DECLARE shifts_taken_cursor CURSOR FOR
    SELECT start_time, end_time
    FROM shifts
    JOIN worker_shifts
    ON shifts.id = worker_shifts.shift_id
    WHERE worker_shifts.worker_id = worker_id
    AND MONTH(shifts.start_time) = month
    AND YEAR(shifts.start_time) = year;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
    
    SET work_hours = 0;
    SET finished = 0;
    
    OPEN shifts_taken_cursor;
    shifts_taken_loop: WHILE(finished = 0)
						DO
							FETCH shifts_taken_cursor INTO temp_start_time, temp_end_time;
                            IF (finished = 1)
                            THEN LEAVE shifts_taken_loop;
                            END IF;
                            SET work_hours = work_hours + (HOUR(temp_end_time)-HOUR(temp_start_time));
						END WHILE;
	CLOSE shifts_taken_cursor;
	SET finished = 0;
    RETURN work_hours;
    
END
|
DELIMITER ;

#Procedure that calculates salaries
DROP PROCEDURE IF EXISTS calculate_salaries;
DELIMITER |
CREATE PROCEDURE calculate_salaries (IN month INT, IN year INT)
BEGIN
	DECLARE temp_worker INT;
    DECLARE temp_hour_pay FLOAT;
    DECLARE temp_work_hours INT;
	DECLARE temp_salary FLOAT;
    DECLARE issue_date DATE;
    DECLARE finished INT;
    DECLARE worker_cursor CURSOR FOR
    SELECT id, hour_pay
    FROM workers;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
    
    SET temp_salary = 0;
    SET issue_date = STR_TO_DATE(CONCAT(year,'-',month,'-',01),'%Y-%m-%d');
    SET finished = 0;
    
    OPEN worker_cursor;
    worker_loop: WHILE (finished = 0)
				DO
                FETCH worker_cursor INTO temp_worker, temp_hour_pay;
                IF (finished = 1)
                THEN LEAVE worker_loop;
                END IF;
                SELECT calculate_work_hours(temp_worker, month, year) INTO temp_work_hours;
                SET temp_salary = temp_work_hours*temp_hour_pay;
                IF (work_hours < 120) #Check if the worker has met the norm for worked hours
                THEN SET temp_salary = temp_salary*0.5; #If not then pay them half the salary
                INSERT INTO salaries (issue_date, amount, worker_id)
                VALUES (issue_date, temp_salary, temp_worker)
                ON DUPLICATE KEY UPDATE
                amount = temp_salary;
                END IF;
                END WHILE;
	CLOSE worker_cursor;
    SET finished = 0;
END
|
DELIMITER ;

#..........................................................................................

DROP PROCEDURE IF EXISTS pay_salaries;
DELIMITER |
CREATE PROCEDURE pay_salaries(IN month INT, IN year INT)
BEGIN
	DECLARE temp_salary_id INT;
	DECLARE salaries_to_be_payed INT;
    DECLARE salaries_payed INT;
    DECLARE finished INT;
    DECLARE salary_cursor CURSOR FOR
    SELECT id, amount
    FROM salaries
    WHERE MONTH(issue_date) = month
    AND YEAR(issue_date) = year
    AND is_payed = FALSE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
    
    SET finished = 0;
    
    SELECT COUNT(*) INTO salaries_to_be_payed
    FROM salaries
    WHERE MONTH(issue_date) = month
    AND YEAR(issue_date) = year
    AND is_payed = FALSE;

	OPEN salary_cursor;
	START TRANSACTION;
    salary_loop: WHILE (finished = 0)
					DO
                    FETCH salary_cursor INTO temp_salary_id;
                    IF (finished = 1)
                    THEN LEAVE salary_loop;
                    END IF;
                    INSERT INTO salary_payments (date_payed, salary_id)
                    VALUES (DATE(NOW()), temp_salary_id);
                    UPDATE salaries
                    SET is_payed = TRUE
                    WHERE salary.id = temp_salary_id;
					END WHILE;
	CLOSE salary_cursor;
    SET finished = 0;
    
	SELECT COUNT(*) INTO salaries_payed
    FROM salary_payments
    WHERE date_payed = DATE(NOW());
    
    IF (salaries_to_be_payed = salaries_payed)
    THEN COMMIT;
    ELSE ROLLBACK;
    END IF;
END
|
DELIMITER ;

#..........................................................................................

DROP PROCEDURE IF EXISTS pay_taxes;
DELIMITER |
CREATE PROCEDURE pay_taxes(IN month INT, IN year INT)
BEGIN
	DECLARE temp_tax_id INT;
	DECLARE taxes_to_be_payed INT;
    DECLARE taxes_payed INT;
    DECLARE finished INT;
    DECLARE tax_cursor CURSOR FOR
    SELECT id, amount
    FROM taxes
    WHERE MONTH(issue_date) = month
    AND YEAR(issue_date) = year
    AND is_payed = FALSE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
    
    SET finished = 0;
    
    SELECT COUNT(*) INTO taxes_to_be_payed
    FROM taxes
    WHERE MONTH(issue_date) = month
    AND YEAR(issue_date) = year
    AND is_payed = FALSE;

	OPEN tax_cursor;
	START TRANSACTION;
    tax_loop: WHILE (finished = 0)
					DO
                    FETCH tax_cursor INTO temp_tax_id;
                    IF (finished = 1)
                    THEN LEAVE tax_loop;
                    END IF;
                    INSERT INTO tax_payments (date_payed, tax_id)
                    VALUES (DATE(NOW()), temp_tax_id);
                    UPDATE taxes
                    SET is_payed = TRUE
                    WHERE tax.id = temp_tax_id;
					END WHILE;
	CLOSE tax_cursor;
    SET finished = 0;
    
	SELECT COUNT(*) INTO taxes_payed
    FROM tax_payments
    WHERE date_payed = DATE(NOW());
    
    IF (taxess_to_be_payed = taxes_payed)
    THEN COMMIT;
    ELSE ROLLBACK;
    END IF;
END
|
DELIMITER ;

#..........................................................................................

DROP PROCEDURE IF EXISTS calculate_income;
DELIMITER |
CREATE PROCEDURE calculate_income(IN month INT, IN year INT)
BEGIN
    DECLARE temp_amount FLOAT;
    DECLARE income FLOAT;
    DECLARE finished INT;
    
    DECLARE bill_cursor CURSOR FOR
    SELECT amount
    FROM bills
    JOIN reservations
    ON bills.reservation_id = reservations.id
    WHERE MONTH(reservations.date) = month
    AND YEAR(reservations.date) = year;
    
    DECLARE tax_cursor CURSOR FOR
    SELECT amount
    FROM taxes
    JOIN tax_payments
    ON taxes.id = tax_payments.tax_id
    WHERE MONTH(date_payed) = month
    AND YEAR(date_payed) = year;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
    
    SET income = 0;
    
    OPEN bill_cursor;
    bill_loop: WHILE (finished = 0)
				DO
                FETCH bill_cursor INTO temp_amount;
                IF (finished = 1)
                THEN LEAVE bill_loop;
                END IF;
                SET income = income + temp_amount;
                END WHILE;
	CLOSE bill_cursor;
    SET finished = 0;
    
    OPEN tax_cursor;
    tax_loop: WHILE (finished = 0)
				DO
                FETCH tax_cursor INTO temp_amount;
                IF (finished = 1)
                THEN LEAVE tax_loop;
                END IF;
                SET income = income - temp_amount;
                END WHILE;
	CLOSE tax_cursor;
    SET finished = 0;
    
    INSERT INTO income (issue_date, amount)
    VALUES(STR_TO_DATE(CONCAT(year,'-',month,'-',01),'%Y-%m-%d'), income);
    
END
|
DELIMITER ;