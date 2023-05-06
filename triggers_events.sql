USE restaurant_management;

#..........................................................................................

SET GLOBAL event_scheduler = ON;
DROP EVENT IF EXISTS fill_shifts_event;
DELIMITER |
CREATE EVENT fill_shifts_event
ON SCHEDULE EVERY 1 MONTH
STARTS '2023-05-01 07:15:00'
DO
BEGIN
CALL fill_shifts(CONCAT(DATE(NOW())+' 11:00:00'));
END |
DELIMITER ;

#..........................................................................................

DROP TRIGGER IF EXISTS check_reservation_info;
DELIMITER |
CREATE TRIGGER check_reservation_info BEFORE INSERT ON reservations
FOR EACH ROW
BEGIN

	DECLARE shift_for_reservation INT;
    
    SELECT shift_id INTO shift_for_reservation
	FROM workers_shifts
    JOIN shifts
    ON shifts.id = shift_id
    WHERE worker_id = NEW.worker_id
    AND NEW.date BETWEEN shifts.start_time AND shifts.end_time;

    IF ((SELECT id
		FROM worker_type
        WHERE type = 'waiter') = (SELECT type_id
								 FROM workers
                                 WHERE id = NEW.worker_id))
	THEN IF (ISNULL(shift_for_reservation))
		THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Selected waiter is not on shift!';
        ELSE UPDATE workers_shifts #Update the amount of taken tables by the choosen waiter
			 SET reservations_taken = reservations_taken + 1
			 WHERE worker_id = NEW.worker_id
             AND shift_id = shift_for_reservation;
        END IF;
    ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Selected worker is not a waiter!';
    END IF;
    
    #Check if there are more chairs than people
    IF (NEW.num_of_chairs > NEW.num_of_people)
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Number of chairs can't be bigger than the number of people";
    END IF;
    
END
|
DELIMITER ;

#..........................................................................................

DROP TRIGGER IF EXISTS check_table_outdoor;
DELIMITER |
CREATE TRIGGER check_table_outdoor BEFORE UPDATE ON tables_reservations
FOR EACH ROW
BEGIN
	IF (SELECT is_smoking
		FROM reservations
        WHERE reservations.id = OLD.reservation_id)
	THEN IF NOT (SELECT is_outdoor
			FROM tables
            WHERE tables.id = NEW.table_id)
		THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Table must be outdoors for smokers!';
        END IF;
	END IF;
END
|
DELIMITER ;

#..........................................................................................

DROP TRIGGER IF EXISTS add_salary_to_taxes;
DELIMITER |
CREATE TRIGGER add_salary_to_taxes AFTER INSERT ON salary_payments
FOR EACH ROW
BEGIN
	DECLARE salary_amount FLOAT;

	SET salary_amount = (SELECT amount
						FROM salaries
                        WHERE salaries.id = NEW.salary_id);

	INSERT INTO taxes (issue_date, amount, type_id)
    VALUES (NEW.date_payed, salary_amount, (SELECT id
									  FROM tax_type
                                      WHERE type = 'salaries'))
	ON DUPLICATE KEY UPDATE
    amount = amount + salary_amount;
END
|
DELIMITER ;

#..........................................................................................

DROP TRIGGER IF EXISTS check_worker_shift;
DELIMITER |
CREATE TRIGGER check_worker_shift BEFORE INSERT ON workers_shifts
FOR EACH ROW
BEGIN
	DECLARE shift_start_time DATETIME;
    
    SELECT start_time INTO shift_start_time
	FROM shifts
	WHERE shifts.id = NEW.shift_id;
   
	IF EXISTS (SELECT shift_id
				FROM workers_shifts
                JOIN shifts
                ON shifts.id = shift_id
                WHERE shift_start_time BETWEEN start_time AND end_time
                AND worker_id = NEW.worker_id)
	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Worker already is on shift at this time';
	END IF;
    
    IF ((SELECT id
		FROM worker_type
        WHERE type = 'waiter') = (SELECT type_id
								 FROM workers
                                 WHERE id = NEW.worker_id))
	THEN SET NEW.reservations_taken = 0;
    END IF;
    
END
|
DELIMITER ;