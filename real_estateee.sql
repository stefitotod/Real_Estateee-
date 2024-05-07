DROP DATABASE IF EXISTS real_estate;
CREATE DATABASE real_estate;
USE real_estate;

CREATE TABLE employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    position VARCHAR(255) NOT NULL
);

CREATE TABLE salaryPayment (
    id INT AUTO_INCREMENT PRIMARY KEY,
    salaryAmount DOUBLE NOT NULL,
    monthlyBonus DOUBLE NOT NULL,
    yearOfPayment YEAR NOT NULL,
    monthlyOfPayment INT NOT NULL,
    dateOfPayment DATE NOT NULL,
    employee_id INT NOT NULL,
    CONSTRAINT FOREIGN KEY (employee_id) REFERENCES employees(id)    
);

CREATE TABLE actions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    actionType VARCHAR(255) NOT NULL
);

CREATE TABLE customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(13) NOT NULL,
    email VARCHAR(255) NOT NULL
);

CREATE TABLE properties (
    id INT AUTO_INCREMENT PRIMARY KEY,
    area DOUBLE NOT NULL,
    price DOUBLE NOT NULL,
    location VARCHAR(255) NOT NULL,
    customer_id INT NOT NULL,
    CONSTRAINT FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE ads (
    id INT AUTO_INCREMENT PRIMARY KEY,
    publicationDate DATE NOT NULL,
    isActual BOOLEAN NOT NULL,
    action_id INT NOT NULL,
    CONSTRAINT FOREIGN KEY (action_id) REFERENCES actions(id),
    property_id INT NOT NULL,
    CONSTRAINT FOREIGN KEY (property_id) REFERENCES properties(id)
);

CREATE TABLE deals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    dealDate DATE NOT NULL,
    paymentType ENUM('YARD', 'BUILDING_WITH_YARD', 'APARTMENT', 'HOUSE', 'MASIONETTE') NOT NULL,
    employee_id INT NOT NULL,
    CONSTRAINT FOREIGN KEY (employee_id) REFERENCES employees(id),
	ad_id INT NOT NULL,
    CONSTRAINT FOREIGN KEY (ad_id) REFERENCES ads(id)
);

INSERT INTO employees (name, position) VALUES 
('John Doe', 'Real Estate Agent'),
('Jane Smith', 'Administrative Staff'),
('Ivaylo Petrov', 'Administrative Staff'),
('Ivan Ivanov', 'Administrative Staff'),
('Michael Johnson', 'Manager');

INSERT INTO customers (name, phone, email) VALUES 
('George Georgev', '0888888888', 'george@example.com'),
('Anna Ivanova', '0999999999', 'anna@example.com'),
('Stefan Stefanov', '0777777777', 'stefan@example.com');

INSERT INTO properties (area, price, location, customer_id) VALUES 
(100, 120000.00, 'Sofia', 1),
(200, 250000.00, 'Plovdiv', 2),
(150, 180000.00, 'Varna', 3);

INSERT INTO actions (actionType) VALUES 
('SELL'),
('BUY'),
('RENT');

INSERT INTO ads (publicationDate, isActual, action_id, property_id) VALUES 
('2024-05-27', true, 1, 1),
('2024-05-27', true, 1, 2),
('2024-05-27', true, 1, 3);

INSERT INTO salaryPayment (salaryAmount, monthlyBonus, yearOfPayment, monthlyOfPayment, dateOfPayment, employee_id) VALUES 
(3000.00, 500.00, 2024, 4, '2024-05-27', 1),
(2500.00, 400.00, 2024, 4, '2024-05-27', 2),
(4000.00, 600.00, 2024, 4, '2024-05-27', 3);

INSERT INTO deals (dealDate, paymentType, employee_id, ad_id) VALUES 
('2024-05-26', 'APARTMENT', 1, 2),
('2024-05-24', 'BUILDING_WITH_YARD', 3, 3);

CREATE VIEW monthlyDeals
AS
SELECT c.name AS customerNAME, c.phone, p.location, p.area, p.price, e.name AS employeeNAME
FROM customers c
JOIN properties p ON c.id = p.customer_id
JOIN ads a ON p.id = a.property_id
JOIN actions act ON a.action_id = act.id
JOIN deals d ON a.id = d.ad_id
JOIN employees e ON d.employee_id = e.id
WHERE act.actionType = 'SELL'
AND MONTH(d.dealDate) = MONTH(CURDATE())
AND YEAR(d.dealDate) = YEAR(CURDATE())
AND p.area > 100
ORDER BY p.price;

DELIMITER //
CREATE PROCEDURE addBonus(IN month_input INT, IN year_input INT, IN avr_commission DECIMAL(10, 2))
BEGIN 
	DECLARE employeeID INT;
    DECLARE done INT DEFAULT 0;
    DECLARE bonus_multi DECIMAL(3, 2);
    
    DECLARE top_three CURSOR FOR
    SELECT employee_id
    FROM salaryPayments
    WHERE YEAR(dateOfPaymnet) = year_input
    AND MONTH(dateOfPayment) = month_input
    ORDER BY monthlyBonus desc
    LIMIT 3;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    OPEN top_three;
    
    readLoop : LOOP
		FETCH top_three INTO employeeID;
        IF done THEN 
			LEAVE readLoop;
		END IF;
        
        IF employeeID = 1 THEN
			SET bonus_multi = avg_commission * 0.15;
		ELSEIF employeeID = 2 THEN
			SET bonus = avg_commission * 0.10;
		ELSEIF employeeID = 3 THEN
			SET bonus = avg_commission * 0.05;
		END IF;
        
        UPDATE salaryPayments
        SET monthlyBonus = monthlyBonus + bonus_multi
        WHERE employee_id = employeeID
		AND MONTH(monthlyPayment) = month_input
        AND YEAR(yearOfPayment) = year_input;
        
	END LOOP;
    CLOSE top_three;

END //
DELIMITER ;
    


DELIMITER //
CREATE PROCEDURE commissionPaymnet(IN month_input INT, IN year_input INT)
BEGIN
    DECLARE count_sells INT DEFAULT 0;
    DECLARE done INT DEFAULT 0;
    DECLARE commission DECIMAL(10, 2);
    DECLARE total_commission DECIMAL(10, 2);
    DECLARE avr_commission DECIMAL(10, 2);
    DECLARE dealAmount DECIMAL(10,2);
    DECLARE employeeID INT;
    
    DECLARE dealsCursor CURSOR FOR 
    SELECT d.employee_id, p.price 
    FROM deals d
    JOIN ads a ON d.ad_id = a.id
    JOIN properties p ON a.property_id = p.id
	WHERE MONTH(d.dealDate) = month_input
    AND YEAR(d.dealDate) = year_input;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    START TRANSACTION;
    OPEN dealsCursor;
    
    readLoop : LOOP
		FETCH dealsCursor INTO employeeID, dealAmount;
        IF done THEN 
			LEAVE readLoop;
		END IF;
    
		IF dealAmount < 100000 THEN
			SET commission = dealAmount * 0.02;
		ELSE 
			SET commission = dealAmount * 0.03;
		END IF;
        
        SET total_commission = total_commission + commission;
        SET count_sells = count_sells + 1;
        
        UPDATE salaryPayment
        SET monthlyBonus = monthlyBonus + commission
        WHERE employee_id = employeeID
        AND MONTH(monthlyPayment) = month_input
        AND YEAR(yearOfPayment) = year_input;
	END LOOP;
    CLOSE dealsCursor;
    
    SET avr_commission = total_commission / count_sells;
    
    CALL addBonus(month_input, year_input, avr_commission);
    
    COMMIT;
 END //
 DELIMITER ;
 
 DELIMITER //
 CREATE TRIGGER check_customer_discount
 AFTER INSERT ON ads
 FOR EACH ROW
 BEGIN 
     DECLARE customerID INT;
     DECLARE num_deals INT;
     DECLARE discount DECIMAL(5, 2) DEFAULT 0.0;
     DECLARE message TEXT DEFAULT '';
     
     SELECT customer_id INTO customerID 
     FROM properties 
     WHERE id = NEW.property_id;
     
     SELECT COUNT(*) INTO num_deals
     FROM deals d
     LEFT JOIN ads a ON a.id = d.ad_id
     LEFT JOIN properties p ON a.property_id = p.id
     JOIN actions act ON a.action_id = act.id
     WHERE act.actionType = 'SELL'
     AND p.customer_id = customerID;
     
     IF num_deals >= 1 AND num_deals <= 5 THEN
        SET discount = 0.005; -- 0.5% for 1 to 5 deals
     ELSEIF num_deals > 5 THEN
        SET discount = 0.01; -- 1% for more than 5 deals
     END IF;

     IF num_deals > 0 THEN
        -- Call the SendEMailToCustomer procedure
        CALL SendEMailToCustomer(customerID, NEW.property_id, discount, @message);
        -- Set the message returned by the procedure
        SELECT @message INTO message;
        -- Insert message into the ads_log table
        INSERT INTO ads_log (log_message) VALUES (message);
     END IF;
     
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER check_max_rental_ads
BEFORE INSERT ON ads
FOR EACH ROW
BEGIN
    DECLARE num_rental_ads INT;
    
    SELECT COUNT(*) INTO num_rental_ads
    FROM ads a
    JOIN properties p ON a.property_id = p.id
    JOIN actions act ON a.action_id = act.id
    WHERE act.actionType = 'RENT'
    AND a.is_actual = 1
    AND p.customer_id = NEW.property_id;

    IF num_rental_ads >= 2 and NEW.action_id = 3 THEN 
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Собственикът има вече 2 активни обяви за отдаване под наем.';
    END IF;
END //
DELIMITER ;


