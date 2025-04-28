Create Schema HealthConnect;
USE HealthConnect;


CREATE TABLE IF NOT EXISTS HealthcareCenter (
    CenterID INT PRIMARY KEY,
    PhoneNumber VARCHAR(20),
    OperatingHours VARCHAR(100),
    Address VARCHAR(255),
    ZipCode VARCHAR(10),
    City VARCHAR(100),
    State VARCHAR(50),
    ServiceRating DECIMAL(3,2),
    AreasOfSpecialty TEXT,
    AppointmentAvailability BOOLEAN,
    AppointmentLink VARCHAR(255),
    SpecialServices TEXT,
    PatientEngagementStatistics TEXT
);

CREATE TABLE IF NOT EXISTS
 Hospital (
    CenterID INT PRIMARY KEY,
    InpatientBeds INT,
    FOREIGN KEY (CenterID) REFERENCES HealthcareCenter(CenterID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS
 Clinic (
    CenterID INT PRIMARY KEY,
    DaysPerWeek INT,
    WalkIn BOOLEAN,
    FOREIGN KEY (CenterID) REFERENCES HealthcareCenter(CenterID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS
 EmergencyCenter (
    CenterID INT PRIMARY KEY,
    ResponseTime INT,
    Availability BOOLEAN,
    FOREIGN KEY (CenterID) REFERENCES HealthcareCenter(CenterID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS
 WellnessCenter (
    CenterID INT PRIMARY KEY,
    StaffedDieticians BOOLEAN,
    PatientProgramParticipation TEXT,
    StaffedPreventativeCareTherapists BOOLEAN,
    StaffedPhysicalTherapists BOOLEAN,
    PatientsEnrolled INT,
    StaffedMentalHealthCounselors BOOLEAN,
    FOREIGN KEY (CenterID) REFERENCES HealthcareCenter(CenterID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS
 HealthcareProvider (
    EmployeeID INT PRIMARY KEY,
    Availability VARCHAR(50),
    Salary DECIMAL(10,2),
    Qualifications TEXT,
    AssociatedFacilities TEXT,
    Address VARCHAR(255),
    City VARCHAR(100),
    State VARCHAR(50),
    ZipCode VARCHAR(10),
    FirstName VARCHAR(100),
    LastName VARCHAR(100),
    PhoneNumber VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS
 Doctor (
    EmployeeID INT PRIMARY KEY,
    MedicalLicenseNumber VARCHAR(50) UNIQUE NOT NULL,
    SurgicalAuthority BOOLEAN,
    PrescriptionAuthority BOOLEAN,
    YearsOfResidency INT,
    Specialization VARCHAR(100),
    FOREIGN KEY (EmployeeID) REFERENCES HealthcareProvider(EmployeeID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS
 Nurse (
    EmployeeID INT PRIMARY KEY,
    Department VARCHAR(100),
    PatientCareResponsibilities TEXT,
    SupervisingPhysician VARCHAR(100),
    ShiftSchedule VARCHAR(100),
    NursingCertification TEXT,
    NursingLicenseNumber VARCHAR(50) UNIQUE NOT NULL,
    FOREIGN KEY (EmployeeID) REFERENCES HealthcareProvider(EmployeeID) ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS
 Invoice (
    InvoiceID INT PRIMARY KEY,
    InvoiceDate DATETIME,
    Amount DECIMAL(10,2),
    PatientID INT
);

CREATE TABLE IF NOT EXISTS
 Patient (
    PatientID INT PRIMARY KEY,
    FirstName VARCHAR(100),
    LastName VARCHAR(100),
    PhoneNumber VARCHAR(20),
    ZipCode VARCHAR(10),
    City VARCHAR(100),
    State VARCHAR(50),
    InsuranceProvider VARCHAR(100),
    Prescriptions TEXT,
    PreviousAppointments TEXT,
    PaymentAmounts TEXT,
    AmountOwed DECIMAL(10,2),
    Name VARCHAR(201) AS (CONCAT(FirstName, ' ', LastName)) STORED,
    Address VARCHAR(161) AS (CONCAT(City, ', ', State, ' ', ZipCode)) STORED
);

ALTER TABLE Invoice
ADD CONSTRAINT FK_Invoice_Patient FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE IF NOT EXISTS
 Payments (
    PaymentID INT PRIMARY KEY,
    PaymentDate DATETIME,
    Amount DECIMAL(10,2),
    PatientID INT,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- This makes the compiler interpret '$$' as the end of a statement instead of a semicolon
DELIMITER $$

CREATE TRIGGER UpdateAmountOwedAfterInvoiceInsert
AFTER INSERT ON Invoice
FOR EACH ROW
BEGIN
    UPDATE Patient
    SET AmountOwed = (
        (SELECT IFNULL(SUM(Amount), 0) FROM Invoice WHERE Invoice.PatientID = NEW.PatientID) -
        (SELECT IFNULL(SUM(Amount), 0) FROM Payments WHERE Payments.PatientID = NEW.PatientID)
    )
    WHERE PatientID = NEW.PatientID;

END$$

CREATE TRIGGER UpdateAmountOwedAfterPaymentInsert
AFTER INSERT ON Payments
FOR EACH ROW
BEGIN
    UPDATE Patient
    SET AmountOwed = (
        (SELECT IFNULL(SUM(Amount), 0) FROM Invoice WHERE Invoice.PatientID = NEW.PatientID) -
        (SELECT IFNULL(SUM(Amount), 0) FROM Payments WHERE Payments.PatientID = NEW.PatientID)
    )
    WHERE PatientID = NEW.PatientID;
END$$

--Sets the delimiter of a statement back to ;
DELIMITER ;


CREATE TABLE IF NOT EXISTS
 CommunityEvent (
    EventID INT PRIMARY KEY,
    EventName VARCHAR(255),
    EventType VARCHAR(100),
    EventDateTime DATETIME,
    Location VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS
 Attends (
    PatientID INT,
    EventID INT,
    PRIMARY KEY (PatientID, EventID),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE,
    FOREIGN KEY (EventID) REFERENCES CommunityEvent(EventID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS
 RegularMember (
    PatientID INT PRIMARY KEY UNIQUE,
    SubscriptionID VARCHAR(50) NOT NULL,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS
 PremiumMember (
    PatientID INT PRIMARY KEY UNIQUE,
    SubscriptionID VARCHAR(50) NOT NULL,
    ProgramsAttended TEXT,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE
);

DELIMITER $$

DELIMITER $$

-- These triggers prevent a patient from being inserted into the RegularMember table
-- if they are already in the PremiumMember table, and vice versa.
CREATE TRIGGER PreventRegularMemberInsert
BEFORE INSERT ON RegularMember
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM PremiumMember WHERE PremiumMember.PatientID = NEW.PatientID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A patient cannot be both a RegularMember and a PremiumMember.';
    END IF;
END$$

CREATE TRIGGER PreventPremiumMemberInsert
BEFORE INSERT ON PremiumMember
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM RegularMember WHERE RegularMember.PatientID = NEW.PatientID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A patient cannot be both a PremiumMember and a RegularMember.';
    END IF;
END$$

DELIMITER ;

-- Insert whole lotta data

INSERT INTO HealthcareCenter (CenterID, PhoneNumber, OperatingHours, Address, ZipCode, City, State, ServiceRating, AreasOfSpecialty, AppointmentAvailability, AppointmentLink, SpecialServices, PatientEngagementStatistics)
VALUES
(1, '123-486-2700', 'Mon-Fri 8am-5pm', '463 Stephanie Route Apt. 411', '91210', 'Austin', 'Oklahoma', 4.14, 'Orthopedics, Neurology', TRUE, 'http://bookhealth.com/1', 'this, include, might', 'Low'),
(2, '393-263-5701', 'Mon-Fri 8am-5pm', '5188 Joseph Station', '85116', 'Lubbock', 'Oklahoma', 4.47, 'Family Medicine, Pediatrics', TRUE, 'http://bookhealth.com/2', 'dinner, safe, begin', 'High'),
(3, '445-272-6827', '24/7', '995 Patterson Rue Suite 734', '03828', 'Lubbock', 'New Mexico', 4.1, 'Cardiology, Family Medicine', TRUE, 'http://bookhealth.com/3', 'market, poor, visit', 'High'),
(4, '803-851-5145', 'Mon-Fri 8am-5pm', '66451 Barnes Field Suite 609', '30402', 'San Antonio', 'New Mexico', 4.54, 'Oncology, Cardiology', TRUE, 'http://bookhealth.com/4', 'though, reach, collection', 'Medium'),
(5, '550-185-1631', 'Mon-Fri 8am-5pm', '61811 Benjamin Parkway Apt. 522', '34546', 'Dallas', 'Texas', 4.34, 'Neurology, Oncology', TRUE, 'http://bookhealth.com/5', 'get, rich, series', 'Low'),
(6, '897-093-4145', '24/7', '31203 Douglas Harbors', '33034', 'San Antonio', 'New Mexico', 4.4, 'Orthopedics, Family Medicine', TRUE, 'http://bookhealth.com/6', 'human, reach, leg', 'Low'),
(7, '938-170-6768', 'Mon-Fri 8am-5pm', '491 Gabriella Walk', '14820', 'Lubbock', 'Oklahoma', 3.7, 'Family Medicine, Cardiology', TRUE, 'http://bookhealth.com/7', 'foreign, image, listen', 'High'),
(8, '738-275-5204', 'Mon-Fri 8am-5pm', '733 Jessica Mill Suite 198', '85227', 'Lubbock', 'Oklahoma', 3.75, 'Family Medicine, Oncology', TRUE, 'http://bookhealth.com/8', 'traditional, central, use', 'Medium'),
(9, '958-216-4164', '24/7', '489 Bonnie Port Apt. 612', '50444', 'Dallas', 'New Mexico', 3.92, 'Oncology, Cardiology', TRUE, 'http://bookhealth.com/9', 'campaign, significant, contain', 'Medium'),
(10, '736-934-3459', 'Mon-Fri 8am-5pm', '5387 Roberson Flat', '33508', 'Houston', 'Oklahoma', 3.78, 'Family Medicine, Pediatrics', TRUE, 'http://bookhealth.com/10', 'adult, if, watch', 'Medium');

INSERT INTO HealthcareProvider (EmployeeID, FirstName, LastName, Salary, State, City, Availability, AssociatedFacilities)
VALUES
(101, 'Alice', 'Nguyen', 120000, 'Texas', 'Austin', 'Monday-Friday', '1,3'),
(102, 'Brian', 'Lee', 95000, 'Texas', 'Dallas', 'Saturday, Sunday', '2'),
(103, 'Carla', 'Martinez', 110000, 'Texas', 'Houston', 'Monday-Friday', '3'),
(104, 'David', 'Kim', 85000, 'Texas', 'San Antonio', 'Monday-Saturday', '4'),
(105, 'Emily', 'Zhao', 130000, 'Texas', 'El Paso', 'Weekends', NULL); -- unassigned #Nullable #Gang #AcingThisExam

INSERT INTO patient (PatientID, FirstName, LastName, PhoneNumber, ZipCode, City, State, InsuranceProvider, Prescriptions, PreviousAppointments, PaymentAmounts, AmountOwed)
VALUES
(1, 'John', 'Doe', '123-456-7890', '90210', 'Los Angeles', 'California', 'HealthCo', 'None', 'None', 'None', 0.00),
(2, 'Jane', 'Smith', '234-567-8901', '90211', 'Dallas', 'Texas', 'WellnessIns', 'None', 'None', 'None', 0.00),
(3, 'Emily', 'Johnson', '345-678-9012', '90212', 'San Antonio', 'Texas', 'Medicare', 'None', 'None', 'None', 0.00),
(4, 'Michael', 'Davis', '456-789-0123', '90213', 'Houston', 'Texas', 'HealthCo', 'None', 'None', 'None', 0.00),
(5, 'Sarah', 'Wilson', '567-890-1234', '90214', 'Austin', 'Texas', 'WellnessIns', 'None', 'None', 'None', 0.00),
(6, 'Sarah', 'Doe', '567-890-1234', '90214', 'Austin', 'Texas', 'WellnessIns', 'None', 'None', 'None', 0.00),
(7, 'David', 'Lee', '678-901-2345', '90215', 'Dallas', 'Texas', 'Medicare', 'None', 'None', 'None', 0.00);


INSERT INTO PremiumMember (PatientID, SubscriptionID, ProgramsAttended) -- Note that subID is varchar 
VALUES
(1, 'PREM123', 'Wellness Program A, Wellness Program B'),
(2, 'PREM124', 'Health Coaching, Fitness Program C'),
(4, 'PREM125', 'Yoga, Meditation, Health Coaching');


INSERT INTO RegularMember (PatientID, SubscriptionID)
VALUES
(5, 'REG123'),
(6, 'REG124'),
(7, 'REG125');

INSERT INTO Hospital (CenterID, InpatientBeds)
VALUES
(1, 160),
(2, 275),
(3, 203),
(4, 282),
(5, 223),
(6, 89),
(7, 165),
(8, 205),
(9, 185),
(10, 155);

INSERT INTO Clinic (CenterID, DaysPerWeek, WalkIn)
VALUES
(1, 3, TRUE),
(2, 3, FALSE),
(3, 5, FALSE),
(4, 7, FALSE),
(5, 7, FALSE),
(6, 7, TRUE),
(7, 7, TRUE),
(8, 7, FALSE),
(9, 7, TRUE),
(10, 3, TRUE);

INSERT INTO EmergencyCenter (CenterID, ResponseTime, Availability)
VALUES
(1, 11, TRUE),
(2, 30, TRUE),
(3, 7, TRUE),
(4, 22, TRUE),
(5, 14, TRUE),
(6, 13, TRUE),
(7, 26, TRUE),
(8, 17, TRUE),
(9, 23, TRUE),
(10, 8, TRUE);

INSERT INTO WellnessCenter (CenterID, StaffedDieticians, PatientProgramParticipation, StaffedPreventativeCareTherapists, StaffedPhysicalTherapists, PatientsEnrolled, StaffedMentalHealthCounselors)
VALUES
(1, FALSE, 'Bring say.', TRUE, FALSE, 36, TRUE),
(2, TRUE, 'Product I seem.', FALSE, FALSE, 71, TRUE),
(3, FALSE, 'Rest involve agreement.', FALSE, TRUE, 33, TRUE),
(4, TRUE, 'Management structure consider.', TRUE, FALSE, 55, FALSE),
(5, FALSE, 'Sell modern inside.', TRUE, TRUE, 90, FALSE),
(6, FALSE, 'Drop perhaps soldier half difference.', FALSE, TRUE, 36, FALSE),
(7, TRUE, 'Record with thousand author.', TRUE, TRUE, 45, TRUE),
(8, FALSE, 'Begin put amount card.', TRUE, FALSE, 71, FALSE),
(9, TRUE, 'Age sport training.', TRUE, FALSE, 18, FALSE),
(10, TRUE, 'Whatever baby investment work field.', TRUE, TRUE, 72, TRUE);

INSERT INTO Invoice (InvoiceID, InvoiceDate, Amount, PatientID)
VALUES
(1001, '2024-11-01', 200.00, 1),
(1002, '2024-11-03', 300.00, 2),
(1003, '2024-10-15', 100.00, 3),
(1004, '2024-12-20', 250.00, 1),
(1005, '2025-01-10', 400.00, 4),
(1006, '2025-02-01', 150.00, 5),
(1007, '2025-03-01', 220.00, 3);


-- VIEWS
-- Drizzy Drae

-- View #1 Patient Visit History
--  need a mapping between invoices -> patients -> providers -> facilities
CREATE VIEW PatientVisitHistory AS
SELECT 
    p.PatientID,
    p.FirstName AS Patient_FName,
    p.LastName AS Patient_LName,
    p.City AS Patient_City,
    p.State AS Patient_State,
    hc.Address AS FacilityAddress,
    hc.City AS HealthcareCenter_City,
    hc.State AS Facility_State,
    i.InvoiceDate
FROM Patient p
JOIN Invoice i ON p.PatientID = i.PatientID
JOIN HealthcareCenter hc ON p.City = hc.City AND p.State = hc.State;


-- View #2 Facility Services and Ratings
CREATE VIEW FacilityServicesRatings AS
SELECT 
    CenterID,
    City,
    State,
    ServiceRating,
    LENGTH(SpecialServices) - LENGTH(REPLACE(SpecialServices, ',', '')) + 1 AS NumberOfSpecialServices
FROM HealthcareCenter;

-- View #3 Comprehensive Provider Profiles
CREATE VIEW ProviderProfiles AS
SELECT 
    hp.EmployeeID,
    hp.FirstName,
    hp.LastName,
    hp.Qualifications,
    hp.AssociatedFacilities,
    hp.Availability,
    hp.Salary,
    COUNT(i.InvoiceID) AS AppointmentCount,
    MAX(i.InvoiceDate) AS LastAppointmentDate
FROM HealthcareProvider hp
LEFT JOIN Invoice i ON FIND_IN_SET(i.PatientID, hp.AssociatedFacilities) > 0
GROUP BY hp.EmployeeID;

-- View #4 Patient Enrollment in Wellness Programs, CHECK OVER THIS ONE, 
-- The join may be incorrect but output looks right.
-- patient -> wellnessCenter ??? Wat, how does this work. I'm cooked, it's 4:30AM on a Tuesday why am I up doing sql
CREATE VIEW PatientWellnessEnrollment AS
SELECT 
    p.PatientID,
    p.FirstName,
    p.LastName,
    wc.CenterID,
    wc.PatientProgramParticipation,
    wc.PatientsEnrolled
FROM Patient p
JOIN WellnessCenter wc ON wc.CenterID = p.PatientID;

-- display views
SELECT * FROM PatientVisitHistory;
SELECT * FROM FacilityServicesRatings;
SELECT * FROM ProviderProfiles;
SELECT * FROM PatientWellnessEnrollment;

-- Queries, I did all 14 for practice, feel free to use 2 of them as your own or wtvr for assignment. 
-- I just wanted to practice for exam.

-- Q1, three most facs in texas by visits.
SELECT 
    hc.CenterID,
    hc.Address,
    hc.City,
    hc.State,
    COUNT(i.InvoiceID) AS VisitCount
FROM HealthcareCenter hc
JOIN Patient p ON hc.City = p.City AND hc.State = p.State
JOIN Invoice i ON i.PatientID = p.PatientID
WHERE hc.State = 'Texas'
GROUP BY hc.CenterID
ORDER BY VisitCount DESC
LIMIT 3;


-- Q2 Top 5 facs based on ratings and visits
SELECT 
    hc.CenterID,
    hc.Address,
    hc.City,
    hc.State,
    COUNT(i.InvoiceID) AS PatientVolume,
    hc.ServiceRating
FROM HealthcareCenter hc
JOIN Patient p ON p.City = hc.City AND p.State = hc.State
JOIN Invoice i ON i.PatientID = p.PatientID
WHERE YEAR(i.InvoiceDate) = YEAR(CURDATE())
GROUP BY hc.CenterID
ORDER BY PatientVolume DESC, hc.ServiceRating DESC
LIMIT 5;




-- Q3 no apptments in the last month, ie Join Where invoiceDate is last month and 
-- Invoice is null.
SELECT hc.CenterID, hc.Address, hc.City, hc.State
FROM HealthcareCenter hc
LEFT JOIN Invoice i ON hc.City = (SELECT City FROM Patient WHERE PatientID = i.PatientID)
                    AND i.InvoiceDate >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
WHERE i.InvoiceID IS NULL;


-- Q4 Wellness program (note that this is eventID) from Dec 1, 2023 - Jan31, 2024
SELECT p.PatientID, p.FirstName, p.LastName
FROM Patient p
WHERE NOT EXISTS (
    SELECT 1
    FROM WellnessCenter wc
    JOIN HealthcareCenter hc ON hc.CenterID = wc.CenterID
    WHERE hc.City = p.City
    AND NOT EXISTS (
        SELECT 1
        FROM Attends a
        JOIN CommunityEvent ce ON a.EventID = ce.EventID
        WHERE a.PatientID = p.PatientID
        AND ce.Location = hc.Address
    )
);


-- Q5 most health entries regardless of member
SELECT 
    p.PatientID,
    p.Name,
    CASE 
        WHEN pm.PatientID IS NOT NULL THEN 'Premium'
        WHEN rm.PatientID IS NOT NULL THEN 'Regular'
        ELSE 'None'
    END AS MembershipStatus,
    LENGTH(p.PaymentAmounts) - LENGTH(REPLACE(p.PaymentAmounts, ',', '')) + 1 AS EntryCount
FROM Patient p
LEFT JOIN PremiumMember pm ON p.PatientID = pm.PatientID
LEFT JOIN RegularMember rm ON p.PatientID = rm.PatientID
ORDER BY EntryCount DESC
LIMIT 1;


-- Q6, prem members where they have not attended a fac, ie invoice == null
SELECT p.PatientID, p.FirstName, p.LastName
FROM Patient p
JOIN PremiumMember pm ON p.PatientID = pm.PatientID
LEFT JOIN Invoice i ON p.PatientID = i.PatientID
WHERE i.InvoiceID IS NULL;


-- Q7, 24/7 facs in tx in the last interval of one year. should be ez
SELECT COUNT(DISTINCT i.PatientID) AS NumPatients
FROM Invoice i
JOIN Patient p ON i.PatientID = p.PatientID
JOIN HealthcareCenter hc ON hc.State = 'Texas' AND hc.OperatingHours = '24/7'
    AND hc.City = p.City AND hc.State = p.State
WHERE i.InvoiceDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR);


-- Q8 erm Idk if this is right. Kind of need more data to make sure.
SELECT p.PatientID, p.FirstName, p.LastName
FROM Patient p
WHERE NOT EXISTS (
    SELECT 1
    FROM WellnessCenter wc
    JOIN HealthcareCenter hc ON hc.CenterID = wc.CenterID
    WHERE hc.City = p.City
    AND NOT EXISTS (
        SELECT 1
        FROM Attends a
        JOIN CommunityEvent ce ON a.EventID = ce.EventID
        WHERE a.PatientID = p.PatientID
        AND ce.Location = hc.Address
    )
);



-- Q9, sum billed, sum covered by insurance. Group by patient, ez
SELECT 
    p.PatientID,
    p.FirstName,
    p.LastName,
    p.InsuranceProvider,
    IFNULL(SUM(i.Amount), 0) AS TotalBilled,
    IFNULL(SUM(pay.Amount), 0) AS CoveredByInsurance
FROM Patient p
LEFT JOIN Invoice i ON i.PatientID = p.PatientID AND i.InvoiceDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
LEFT JOIN Payments pay ON pay.PatientID = p.PatientID AND pay.PaymentDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY p.PatientID;



-- Q10, Goat center, find the center who treated the most patients
-- Most Appointments
SELECT hp.EmployeeID, hp.FirstName, hp.LastName, hp.PhoneNumber
FROM HealthcareProvider hp
JOIN (
    SELECT 
        hp2.EmployeeID,
        COUNT(i.InvoiceID) AS AppointmentCount
    FROM HealthcareProvider hp2
    LEFT JOIN Invoice i ON FIND_IN_SET((SELECT hc.CenterID FROM HealthcareCenter hc WHERE hc.City = hp2.City LIMIT 1), hp2.AssociatedFacilities)
    GROUP BY hp2.EmployeeID
) sub ON hp.EmployeeID = sub.EmployeeID
ORDER BY sub.AppointmentCount DESC
LIMIT 1;

-- Most Unique Patients
SELECT hp.EmployeeID, hp.FirstName, hp.LastName, hp.PhoneNumber
FROM HealthcareProvider hp
JOIN (
    SELECT 
        hp2.EmployeeID,
        COUNT(DISTINCT i.PatientID) AS UniquePatients
    FROM HealthcareProvider hp2
    LEFT JOIN Invoice i ON FIND_IN_SET((SELECT hc.CenterID FROM HealthcareCenter hc WHERE hc.City = hp2.City LIMIT 1), hp2.AssociatedFacilities)
    GROUP BY hp2.EmployeeID
) sub ON hp.EmployeeID = sub.EmployeeID
ORDER BY sub.UniquePatients DESC
LIMIT 1;



-- Q11, easy, just find avg ratings where count > 5.
SELECT 
    d.Specialization,
    AVG(hc.ServiceRating) AS AvgRating,
    COUNT(*) AS NumCenters
FROM Doctor d
JOIN HealthcareProvider hp ON d.EmployeeID = hp.EmployeeID
JOIN HealthcareCenter hc ON FIND_IN_SET(hc.CenterID, hp.AssociatedFacilities)
GROUP BY d.Specialization
HAVING COUNT(*) > 5;



-- Q12 Need ratings between 4.5 and 5.0 AND never canceled an apptment
-- can do a JOIN to find the once that never cacela and filter with a where
SELECT hp.EmployeeID, hp.FirstName, hp.LastName
FROM HealthcareProvider hp
JOIN HealthcareCenter hc ON FIND_IN_SET(hc.CenterID, hp.AssociatedFacilities)
WHERE hc.ServiceRating BETWEEN 4.5 AND 5.0
  AND NOT EXISTS (
      SELECT 1 FROM Invoice i 
      WHERE i.PatientID IN (
          SELECT p.PatientID FROM Patient p
          WHERE p.City = hc.City AND p.State = hc.State
      )
      AND i.Amount IS NULL
  );


-- Q13, note that I tried using Rank but that no work in this version :(
SELECT wc.CenterID, hc.City, wc.PatientsEnrolled
FROM WellnessCenter wc
JOIN HealthcareCenter hc ON wc.CenterID = hc.CenterID
WHERE hc.State = 'Texas'
AND (
    SELECT COUNT(*)
    FROM WellnessCenter wc2
    JOIN HealthcareCenter hc2 ON wc2.CenterID = hc2.CenterID
    WHERE hc2.City = hc.City
      AND hc2.State = 'Texas'
      AND wc2.PatientsEnrolled > wc.PatientsEnrolled
) < 3
ORDER BY hc.City, wc.PatientsEnrolled DESC;




-- Q14, I think this is right? Kind of need more data to confirm.
SELECT 
    Service,
    COUNT(*) AS UtilizationCount,
    AVG(hc.ServiceRating) AS AvgSatisfaction
FROM PremiumMember pm
JOIN Patient p ON pm.PatientID = p.PatientID
JOIN HealthcareCenter hc ON p.City = hc.City AND p.State = hc.State
JOIN (
    SELECT 
        hc.CenterID,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(hc.SpecialServices, ',', numbers.n), ',', -1)) AS Service
    FROM HealthcareCenter hc
    JOIN ( -- this is probably a terrible way of doing this but I really cannot think of any other way.
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers
    ON numbers.n <= 1 + LENGTH(hc.SpecialServices) - LENGTH(REPLACE(hc.SpecialServices, ',', ''))
) AS ExplodedServices ON hc.CenterID = ExplodedServices.CenterID
GROUP BY Service
ORDER BY UtilizationCount DESC;