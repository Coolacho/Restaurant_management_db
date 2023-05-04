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
	#Choose a worker that is a waiter and is on shift when the reservation starts and has the least amount of taken tables
    CALL add_waiter_to_reservation(NEW.date, NEW.waiter_id);
    
    #Check if there is no waiter selected and terminate the insert.
    IF (ISNULL(NEW.waiter_id))
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Can't associate waiter to the reservation. No waiters on shift.";
    END IF;
    
    #Update the amount of taken tables by the choosen waiter
	UPDATE workers_shifts
    SET reservations_taken = reservations_taken + 1
    WHERE worker_id = (SELECT worker_id
						FROM workers_shifts
						JOIN shifts ON
						workers_shifts.shift_id = shifts.id
						WHERE (NEW.date BETWEEN shifts.start_time AND shifts.end_time)
						AND worker_id = NEW.waiter_id);
    
    IF (NEW.num_of_chairs > NEW.num_of_people)
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Number of chairs can't be bigger than the number of people";
    END IF;
    
    #Insert the reservation with pending table to appoint
    INSERT INTO tables_reservations (reservation_id)
    VALUES (NEW.id);
    
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