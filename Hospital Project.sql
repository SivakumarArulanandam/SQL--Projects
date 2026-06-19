CREATE DATABASE Hospital;
USE Hospital;

# Patients
CREATE TABLE Patients (
    patient_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    dob DATE,
    gender ENUM('MALE','FEMALE','OTHER'),
    contact_info VARCHAR(100),
    address TEXT
);

# Doctors
CREATE TABLE Doctors (
    doctor_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    specialization VARCHAR(50),
    contact_info VARCHAR(100)
);

# Nurses
CREATE TABLE Nurses (
    nurse_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    shift ENUM('MORNING','EVENING','NIGHT'),
    contact_info VARCHAR(100)
);

# Staff Roster
CREATE TABLE StaffRoster (
    roster_id INT PRIMARY KEY AUTO_INCREMENT,
    nurse_id INT,
    shift ENUM('MORNING','EVENING','NIGHT'),
    FOREIGN KEY (nurse_id) REFERENCES Nurses(nurse_id)
);

# Appointments
CREATE TABLE Appointments (
    appointment_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT,
    doctor_id INT,
    appointment_date DATETIME,
    reason VARCHAR(250),
    status ENUM('Scheduled','Completed','Cancelled') DEFAULT 'Scheduled',
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id)
);

# Admission
CREATE TABLE Admission (
    admission_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT,
    admission_date DATETIME,
    status VARCHAR(50),
    reason TEXT,
    room_number VARCHAR(10),
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

# Discharge
CREATE TABLE Discharge (
    discharge_id INT PRIMARY KEY AUTO_INCREMENT,
    admission_id INT,
    discharge_date DATETIME,
    summary TEXT,
    FOREIGN KEY (admission_id) REFERENCES Admission(admission_id)
);

# Billing (after Admission exists)
CREATE TABLE Billing (
    bill_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT,
    appointment_id INT,
    admission_id INT,
    appointment_date DATETIME,
    admission_date DATETIME,
    total_amount DECIMAL(10,2),
    paid_amount DECIMAL(10,2),
    billing_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (appointment_id) REFERENCES Appointments(appointment_id),
    FOREIGN KEY (admission_id) REFERENCES Admission(admission_id)
);

# Patients
INSERT INTO Patients (first_name, last_name, dob, gender, contact_info, address)
VALUES ('John', 'Doe', '1985-06-15', 'MALE', '555-1234', '123 Main St');

INSERT INTO Patients (first_name, last_name, dob, gender, contact_info, address)
VALUES ('Jane', 'Smith', '1990-09-25', 'FEMALE', '555-5678', '456 Park Ave');

# Doctors
INSERT INTO Doctors (first_name, last_name, specialization, contact_info)
VALUES ('Alice', 'Brown', 'Cardiology', '555-1111'),
	('Bob', 'Johnson', 'Neurology', '555-2222');

# Nurses
INSERT INTO Nurses (first_name, last_name, shift, contact_info)
VALUES ('Mary', 'White', 'MORNING', '555-3333'),
('David', 'Green', 'NIGHT', '555-4444');

# Staff Roster
INSERT INTO StaffRoster (nurse_id, shift)
VALUES (1, 'MORNING'), (2, 'NIGHT');

# Appointments
INSERT INTO Appointments (patient_id, doctor_id, appointment_date, reason)
VALUES (1, 1, '2025-08-10 09:00:00', 'Regular checkup');

INSERT INTO Appointments (patient_id, doctor_id, appointment_date, reason)
VALUES (2, 2, '2025-08-11 10:30:00', 'Headache');

# Admission
INSERT INTO Admission (patient_id, admission_date, status, reason, room_number)
VALUES (1, '2025-08-09 14:00:00', 'Ongoing', 'Heart surgery', '101A');

# Discharge
INSERT INTO Discharge (admission_id, discharge_date, summary)
VALUES (1, '2025-08-15 10:00:00', 'Successful surgery, follow-up in 2 weeks');

# Billing
INSERT INTO Billing (patient_id, appointment_id, admission_id, appointment_date, admission_date, total_amount, paid_amount)
VALUES (1, 1, 1, '2025-08-10 09:00:00', '2025-08-09 14:00:00', 5000.00, 5000.00);

# See all patients
SELECT * FROM Patients;

# See upcoming appointments
SELECT a.appointment_id, p.first_name AS patient, d.first_name AS doctor, a.appointment_date, a.status
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
JOIN Doctors d ON a.doctor_id = d.doctor_id;

# See billing summary
SELECT b.bill_id, p.first_name, b.total_amount, b.paid_amount, b.billing_date
FROM Billing b
JOIN Patients p ON b.patient_id = p.patient_id;

DELIMITER $$

CREATE TRIGGER after_appointment_completed
AFTER UPDATE ON Appointments
FOR EACH ROW
BEGIN
    IF NEW.status = 'Completed' AND OLD.status <> 'Completed' THEN
        INSERT INTO Billing (patient_id, appointment_id, appointment_date, total_amount, paid_amount)
        VALUES (
            NEW.patient_id,
            NEW.Appointment_id,
            NEW.appointment_date,
            500.00,  -- Example flat fee
            0.00
        );
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER after_discharge_insert
AFTER INSERT ON Discharge
FOR EACH ROW
BEGIN
    UPDATE Admission
    SET status = 'Discharged'
    WHERE admission_id = NEW.admission_id;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER before_admission_insert
BEFORE INSERT ON Admission
FOR EACH ROW
BEGIN
    SET NEW.status = 'Admitted';
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER after_discharge_billing
AFTER INSERT ON Discharge
FOR EACH ROW
BEGIN
    DECLARE days_stayed INT;
    
    SELECT DATEDIFF(NEW.discharge_date, admission_date)
    INTO days_stayed
    FROM Admission
    WHERE admission_id = NEW.admission_id;

    INSERT INTO Billing (patient_id, admission_id, admission_date, total_amount, paid_amount)
    SELECT 
        patient_id,
        admission_id,
        admission_date,
        (days_stayed * 2000), -- ₹2000 per day
        0.00
    FROM Admission
    WHERE admission_id = NEW.admission_id;
END$$

DELIMITER ;

