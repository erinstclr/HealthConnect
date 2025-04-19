CREATE TABLE HealthcareCenter (
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

CREATE TABLE Hospital (
    CenterID INT PRIMARY KEY,
    InpatientBeds INT,
    FOREIGN KEY (CenterID) REFERENCES HealthcareCenter(CenterID) ON DELETE CASCADE
);

CREATE TABLE Clinic (
    CenterID INT PRIMARY KEY,
    DaysPerWeek INT,
    WalkIn BOOLEAN,
    FOREIGN KEY (CenterID) REFERENCES HealthcareCenter(CenterID) ON DELETE CASCADE
);

CREATE TABLE EmergencyCenter (
    CenterID INT PRIMARY KEY,
    ResponseTime INT,
    Availability BOOLEAN,
    FOREIGN KEY (CenterID) REFERENCES HealthcareCenter(CenterID) ON DELETE CASCADE
);

CREATE TABLE WellnessCenter (
    CenterID INT PRIMARY KEY,
    StaffedDieticians BOOLEAN,
    PatientProgramParticipation TEXT,
    StaffedPreventativeCareTherapists BOOLEAN,
    StaffedPhysicalTherapists BOOLEAN,
    PatientsEnrolled INT,
    StaffedMentalHealthCounselors BOOLEAN,
    FOREIGN KEY (CenterID) REFERENCES HealthcareCenter(CenterID) ON DELETE CASCADE
);

CREATE TABLE HealthcareProvider (
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

CREATE TABLE Doctor (
    EmployeeID INT PRIMARY KEY,
    MedicalLicenseNumber VARCHAR(50) UNIQUE NOT NULL,
    SurgicalAuthority BOOLEAN,
    PrescriptionAuthority BOOLEAN,
    YearsOfResidency INT,
    Specialization VARCHAR(100),
    FOREIGN KEY (EmployeeID) REFERENCES HealthcareProvider(EmployeeID) ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Nurse (
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

CREATE TABLE Invoice (
    InvoiceID INT PRIMARY KEY,
    InvoiceDate DATETIME,
    Amount DECIMAL(10,2),
    PatientID INT,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Payments (
    PaymentID INT PRIMARY KEY,
    PaymentDate DATETIME,
    Amount DECIMAL(10,2),
    PatientID INT,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Patient (
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
    AmountOwed AS (
        (SELECT COALESCE(SUM(InvoiceAmount), 0) FROM Invoice WHERE Invoice.PatientID = Patient.PatientID) -
        (SELECT COALESCE(SUM(PaymentAmount), 0) FROM Payments WHERE Payments.PatientID = Patient.PatientID)
    ) PERSISTED,
    Name AS (FirstName + ' ' + LastName) PERSISTED,
    Address AS (City + ', ' + State + ' ' + ZipCode) PERSISTED
);

CREATE TABLE Appointment (
    AppointmentID INT PRIMARY KEY,
    AppointmentDate DATETIME,
    ReviewRating DECIMAL(3,2),
    FollowUpAppointments TEXT,
    IsTelehealthConsultation BOOLEAN,
    ReviewComments TEXT,
    PatientID INT,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE CommunityEvent (
    EventID INT PRIMARY KEY,
    EventName VARCHAR(255),
    EventType VARCHAR(100),
    EventDateTime DATETIME,
    Location VARCHAR(255)
);

CREATE TABLE Attends (
    PatientID INT,
    EventID INT,
    PRIMARY KEY (PatientID, EventID),
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE,
    FOREIGN KEY (EventID) REFERENCES CommunityEvent(EventID) ON DELETE CASCADE
);

CREATE TABLE RegularMember (
    PatientID INT PRIMARY KEY,
    SubscriptionID VARCHAR(50) NOT NULL,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE
);

CREATE TABLE PremiumMember (
    PatientID INT PRIMARY KEY,
    SubscriptionID VARCHAR(50) NOT NULL,
    ProgramsAttended TEXT,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID) ON DELETE CASCADE
);

ALTER TABLE RegularMember
ADD CONSTRAINT CK_RegularMember_Disjoint CHECK (
    PatientID NOT IN (
        SELECT PatientID FROM PremiumMember
    )
);

ALTER TABLE PremiumMember
ADD CONSTRAINT CK_PremiumMember_Disjoint CHECK (
    PatientID NOT IN (
        SELECT PatientID FROM RegularMember
    )
);