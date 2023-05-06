USE restaurant_management;

INSERT INTO reservators (name, telephone, email)
VALUES ('Ангел Ангелов', '0885802326' ,'anangelov@tu-sofia.bg'),
('Георги Георгиев', '0885912227' ,'ggeorgiev@tu-sofia.bg'),
('Петър Петров', '0885802326' ,'ptpetrov@tu-sofia.bg'),
('Тодор Тодоров', '0786713426' ,'ttodorov@tu-sofia.bg');

INSERT INTO products (name, price)
VALUES ('spaghetti bolognese', 10),
('spaghetti carbonara', 11),
('spaghetti arrabiata', 10),
('pizza napoletana', 14),
('pizza margherita', 9.5),
('pizza quattro formagie', 14),
('coca-cola', 3),
('fuzetea', 3),
('whiskey', 8),
('tiramisu', 6.5);

INSERT INTO tax_type (type)
VALUES ('electricity'),
('water'),
('salaries'),
('supply');

INSERT INTO taxes (issue_date, type_id, amount)
VALUES (DATE(NOW()), 1, 100),
(DATE(NOW()), 2, 150),
(DATE(NOW()), 3, 200),
(DATE(NOW()), 4, 250),
(DATE_SUB(DATE(NOW()), INTERVAL 1 MONTH), 1, 250),
(DATE_SUB(DATE(NOW()), INTERVAL 1 MONTH), 2, 200),
(DATE_SUB(DATE(NOW()), INTERVAL 1 MONTH), 3, 150),
(DATE_SUB(DATE(NOW()), INTERVAL 1 MONTH), 4, 100),
(DATE_SUB(DATE(NOW()), INTERVAL 2 MONTH), 1, 100),
(DATE_SUB(DATE(NOW()), INTERVAL 2 MONTH), 2, 150),
(DATE_SUB(DATE(NOW()), INTERVAL 2 MONTH), 3, 200),
(DATE_SUB(DATE(NOW()), INTERVAL 2 MONTH), 4, 250);

INSERT INTO table_type (type, min_num_of_people, max_num_of_people)
VALUES ('booth', 2, 5),
('high top', 2, 4),
('bar', 1, 1),
('two to four', 2, 4),
('family', 5, 8);

INSERT INTO tables (type_id, is_outdoor)
VALUES (1, TRUE),
(2, TRUE),
(3, TRUE),
(4, TRUE),
(5, TRUE),
(1, TRUE),
(2, TRUE),
(3, TRUE),
(4, TRUE),
(5, TRUE),
(1, FALSE),
(2, FALSE),
(3, FALSE),
(4, FALSE),
(5, FALSE),
(1, FALSE),
(2, FALSE),
(3, FALSE),
(4, FALSE),
(5, FALSE);

INSERT INTO worker_type (type)
VALUES ('barman'),
('waiter'),
('cooker'),
('cleaner');

INSERT INTO workers (name, type_id, hour_pay)
VALUES ('Тодор Петков', 1, 10),
('Петко Тодоров', 2, 9.5),
('Петко Яворов', 3, 15),
('Любомира Димитрова', 4, 8),
('Петра Симеонова', 1, 10),
('Надежда Илиева', 2, 9.5),
('Екатерина Балканджиева', 3, 15),
('Антония Стругарева', 4, 8);

CALL fill_shifts('2023-05-01 10:00:00');

INSERT INTO workers_shifts (worker_id, shift_id)
VALUES (1, 8),
(2, 1),
(2, 3),
(2, 10),
(3, 4),
(3, 12),
(3, 20),
(4, 1),
(4, 3),
(4, 14),
(5, 3),
(5, 12),
(5, 21),
(6, 2),
(6, 9),
(6, 11),
(6, 17),
(6, 19);

INSERT INTO reservations (date, is_smoking, num_of_people, num_of_chairs, avance_amount, reservator_id, worker_id)
VALUES ('2023-05-01 13:00:00', FALSE, 2, 2, 0.0, 1, 2),
('2023-05-01 13:00:00', FALSE,3, 3, 50.0, 2, 2),
('2023-05-02 13:00:00', FALSE, 3, 3, 25.0, 2, 6),
('2023-05-01 13:00:00', TRUE, 4, 0, 70.0, 3, 2),
('2023-05-01 20:00:00', TRUE, 4, 4, 100.0, 3, 2),
('2023-05-03 13:00:00', FALSE, 4, 0, 0.0, 3, 6),
('2023-05-01 15:00:00', TRUE, 5, 5, 30.0, 4, 6),
('2023-05-03 20:00:00', TRUE, 6, 0, 0.0, 4, 6);

CALL calculate_bill(1, '[1,2,7,10]');
CALL calculate_bill(2, '[3,4,6,8,8,10,10]');
CALL calculate_bill(3, '[5,6,7,8,10]');

CALL pay_taxes(3, 2023);

CALL calculate_income(5, 2023);