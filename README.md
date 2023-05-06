# Restaurant_management_db
University project wich consists in creating a mysql database for restaurant management.

The database itself consists of 17 tables:
1. Products, which stores the different dishes and beverages the restaurant offers.
2. Income, for the profit of the restaurant.
3,4. Taxes, for tracking the expenses and a respective table for the different tax types.
5. Tax_payments, that stores which taxes are payed and when.
6,7. Workers, wich stores the information for the people working in the restaurant and a worker_type table for keeping track of the position wich a person occupies.
8. Salaries, for keeping track of the payments each month to the workers.
9. Salary payments, that stores which salaries are payed and when.
10. Shifts table for all the shifts that the people can take.
11. Worker_shift table for the realisation of M to M link between the workers and shifts tables.
12,13. Tables and table_type for storing all the available tables and their types in the restaurant.
14. Reservations table for all the reservations made.
15. Table_reservations that links tables and reservations in a M to M connection.
16. Reservators table wich keeps the information for the people that make reservations.
17. Bills table wich stores the bill of every reservation in numerical and possibly pdf version.

![image](https://user-images.githubusercontent.com/54374165/236259716-9a2c431e-941d-44b1-8e52-7fb90bd90f01.png)

Stored procedures:
1. The first one fill_shifts() is made to fill the shifts table with all the possible shifts for a day from the date that is passed in until the end of the month. There are 3 4-hour shifts, 2 6-hour shifts, 2 8-hour shifts and 1 12-hour shift. The procedure is then added to an event that is scheduled every month, so that at the start of the month the default shifts are available.
2. The second procedure calculate_bill() receives a reservation id and a JSON array full of integers that represent products' ids then adds the ids to a temporary table that represents the bill. After that it sums the prices of the products and inserts a row in bills table with the respective reservation id and amount.
3. The third procedure calculate_salaries() takes a month and an year and calculates the salary that a worker shall receive based on the hours worked that month.*
4, 5. The next two procedures pay_salaries() and pay_taxes() are identical. They receive a month and an year and pay all the accumalated salaries/taxes for that period.
6. The last procedure calculate_income() again takes a period of time in form of a month and an year and sums all the bills for it and substracts all the taxes. After that it makes a new record in the income table.

*To calculate the work hours there is a function that returns the worked hours by a worker for a given period. 

Triggers:
1. check_reservation_info does two things. First it checks if the associated worker is waiter and if he is a waiter, is he on shift for the reservation and throws the respective errors if the checks do not succeed. The second thing it checks is if the number of chairs is greater than the number of people for the reservation wich is not allowed so it throws error message if it doesn't succed;
2. Second trigger check_table_outdoor checks if the reservation is for smokers does the appointed table is outdoor or not.
3. Third trigger whenever a salary is payed inserts a new entry in the taxes table for the amount.
4. The last trigger is made to check that a worker doesn't take two shifts that overlap.
