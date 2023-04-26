DROP DATABASE IF EXISTS restaurant_management;
CREATE DATABASE restaurant_management;
USE restaurant_management;

DROP TABLE IF EXISTS products;
CREATE TABLE products(
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(255) NOT NULL UNIQUE,
price FLOAT NOT NULL);

DROP TABLE IF EXISTS income;
CREATE TABLE income(
issue_date DATE PRIMARY KEY,
amount FLOAT NOT NULL,
CONSTRAINT CHK_income_date CHECK (DAY(issue_date) = '01'));

DROP TABLE IF EXISTS tax_type;
CREATE TABLE tax_type(
id INT AUTO_INCREMENT PRIMARY KEY,
type ENUM('supply', 'electricity', 'water', 'salaries') NOT NULL UNIQUE);

DROP TABLE IF EXISTS taxes;
CREATE TABLE taxes(
id INT AUTO_INCREMENT PRIMARY KEY,
issue_date DATE NOT NULL UNIQUE,
type_id INT NOT NULL,
CONSTRAINT CHK_taxes_date CHECK (DAY(issue_date) = '01'),
CONSTRAINT FOREIGN KEY FK_type (type_id) REFERENCES tax_type(id) ON DELETE RESTRICT ON UPDATE CASCADE);

DROP TABLE IF EXISTS worker_type;
CREATE TABLE worker_type(
id INT AUTO_INCREMENT PRIMARY KEY,
type ENUM('barman', 'waiter', 'cooker', 'cleaner') NOT NULL UNIQUE);

DROP TABLE IF EXISTS workers;
CREATE TABLE workers(
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(255) NOT NULL,
hour_pay FLOAT NOT NULL,
type_id INT NOT NULL,
CONSTRAINT FOREIGN KEY FK_type (type_id) REFERENCES worker_type(id) ON DELETE RESTRICT ON UPDATE CASCADE);

DROP TABLE IF EXISTS salaries;
CREATE TABLE salaries(
issue_date DATE PRIMARY KEY,
amount FLOAT NOT NULL,
is_payed BOOLEAN NOT NULL,
worker_id INT NOT NULL,
CONSTRAINT CHK_date CHECK (DAY(issue_date) = '01'),
CONSTRAINT FOREIGN KEY FK_worker (worker_id) REFERENCES workers(id) ON DELETE RESTRICT ON UPDATE CASCADE);

DROP TABLE IF EXISTS shifts;
CREATE TABLE shifts(
id INT AUTO_INCREMENT PRIMARY KEY,
start_time DATETIME NOT NULL,
end_time DATETIME NOT NULL,
UNIQUE unique_shift(start_time, end_time),
CONSTRAINT CHK_shift CHECK (DATE(start_time) = DATE(end_time)));

DROP TABLE IF EXISTS workers_shifts;
CREATE TABLE workers_shifts(
worker_id INT NOT NULL,
shift_id INT NOT NULL,
num_of_tables INT NULL DEFAULT NULL,
CONSTRAINT FOREIGN KEY FK_worker (worker_id) REFERENCES workers(id) ON DELETE RESTRICT ON UPDATE CASCADE,
CONSTRAINT FOREIGN KEY FK_shift (shift_id) REFERENCES shifts(id) ON DELETE RESTRICT ON UPDATE CASCADE);

DROP TABLE IF EXISTS table_type;
CREATE TABLE table_type(
id INT AUTO_INCREMENT PRIMARY KEY,
type ENUM('booth', 'high top', 'bar', 'two to four', 'family') NOT NULL UNIQUE); #TODO ADD minimum and maximum number of people where min is default and aboce that you add chairs

DROP TABLE IF EXISTS tables;
CREATE TABLE tables(
id INT AUTO_INCREMENT PRIMARY KEY,
is_outdoor BOOLEAN NOT NULL,
type_id INT NOT NULL,
CONSTRAINT FOREIGN KEY FK_type (type_id) REFERENCES table_type(id) ON DELETE RESTRICT ON UPDATE CASCADE);

DROP TABLE IF EXISTS reservators;
CREATE TABLE reservators(
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(255) NOT NULL,
telephone VARCHAR(20) NOT NULL,
email VARCHAR(100) NOT NULL,
CONSTRAINT CHK_telephone CHECK (LENGTH(telephone) = 20));

DROP TABLE IF EXISTS reservations;
CREATE TABLE reservations(
id INT AUTO_INCREMENT PRIMARY KEY,
date DATETIME NOT NULL,
is_smoking BOOLEAN NOT NULL,
num_of_people INT NOT NULL,
num_of_chairs INT NOT NULL,
avance_sum FLOAT,
reservator_id INT NOT NULL,
table_id INT NOT NULL,
waiter_id INT NOT NULL,
CONSTRAINT FOREIGN KEY FK_reservator (reservator_id) REFERENCES reservators(id) ON DELETE RESTRICT ON UPDATE CASCADE,
CONSTRAINT FOREIGN KEY FK_table (table_id) REFERENCES tables(id) ON DELETE RESTRICT ON UPDATE CASCADE, #TODO Make the connection M to M aka add another table so that one reservation can take multiple tables
CONSTRAINT FOREIGN KEY FK_worker (waiter_id) REFERENCES workers(id) ON DELETE RESTRICT ON UPDATE CASCADE);

DROP TABLE IF EXISTS bills;
CREATE TABLE bills(
id INT AUTO_INCREMENT PRIMARY KEY,
amount FLOAT NOT NULL,
invoice VARCHAR(255) NULL DEFAULT NULL, #column for storing pdf copies of the bills
reservation_id INT NOT NULL UNIQUE,
CONSTRAINT FOREIGN KEY FK_reservation (reservation_id) REFERENCES reservations(id) ON DELETE RESTRICT ON UPDATE CASCADE);