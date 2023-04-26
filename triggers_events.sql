USE restaurant_management;

DROP TRIGGER IF EXISTS append_table_waiter;
DELIMITER |
CREATE TRIGGER append_table_waiter BEFORE INSERT ON reservations
FOR EACH ROW
BEGIN
    SET NEW.waiter_id = (SELECT worker_id
						 FROM (SELECT worker_id
								FROM workers_shifts
								JOIN shifts ON
								workers_shifts.shift_id = shifts.id
								JOIN workers ON
								workers_shifts.worker_id = workers.id
								JOIN worker_type ON
								workers.type_id = worker_type.id
								WHERE (NEW.date BETWEEN shifts.start_time AND shifts.end_time)
								AND (worker_type.type = 'waiter')) AS waiters_on_shift 
						 WHERE waiters_on_shift.num_of_tables = (SELECT MIN(num_of_tables) FROM waiters_on_shift));
                         
	UPDATE workers_shifts
    SET num_of_tables = num_of_tables + 1
    WHERE worker_id = (SELECT worker_id
						FROM workers_shifts
						JOIN shifts ON
						workers_shifts.shift_id = shifts.id
						WHERE (NEW.date BETWEEN shifts.start_time AND shifts.end_time)
						AND worker_id = NEW.waiter_id);
    
    SET NEW.table_id = (SELECT id
						FROM tables);#FINISH THE TRIGGER!!!
END
|
DELIMITER ;