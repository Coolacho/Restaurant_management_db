# Restaurant_management_db
University project wich consists in creating a mysql database for restaurant management.

The database itself consists of 14 tables:
1. Products, which stores the different dishes and beverages the restaurant offers
2. Income, for the profit of the restaurant.
3. Taxes, for tracking the expenses and a respective table for the different tax types
4. Workers, wich stores the information for the people working in the restaurant and a worker_type table for keeping track of the position wich a person occupies
5. Salaries, for keeping track of the payments each month to the workers
6. Shifts table for all the shifts that the people can take
7. Worker_shift table for the realisation of M to M link between the workers and shifts tables
8. Tables and table_type for storing all the available tables and their types in the restaurant
9. Reservations table for all the reservations made
10. Reservators table wich keeps the information for the people that make reservations
11. Bills table wich stores the bill of every reservation in numerical and possibly pdf version.

*ER-diagram of the database will be uploaded soon*

Stored procedures:
1. The first one is made to fill the shifts table with all the possible shifts for a day from the date that is passed in until the end of the month. There are 3 4-hour shifts, 2 6-hour shifts, 2 8-hour shifts and 1 12-hour shift. There's a test call for the procedure after the declaration to test it.
2. The second procedures receives a reservation id and a JSON array full of integers that represent products' ids then adds the ids to a temporary table that represents the bill. After that it sums the prices of the products and inserts a row in bills table with the respective reservation id and amount.

Triggers:
1. The first trigger is made to associate a table and a waiter to each reservation when its added.
  It chooses the waiter that works in a shift and has taken/ is associated with the least amount of tables for that shift, after that it updates the number of taken    tables by 1.
  *The choice of table is yet to be completed*

*Additional information about the triggers, stored procedures and events will be uploaded when the respective code is uploaded*
