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
