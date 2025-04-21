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

--This makes the compiler interpret '$$' as the end of a statement instead of a semicolon
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


