﻿-- Seed Countries (Including the Balkan region)
SET IDENTITY_INSERT Countries ON;

INSERT INTO Countries (CountryId, CountryName) VALUES
(1, 'United States'),
(2, 'Canada'),
(3, 'Bosnia and Herzegovina'),
(4, 'Serbia'),
(5, 'Croatia'),
(6, 'Montenegro'),
(7, 'Slovenia'),
(8, 'North Macedonia'),
(9, 'Albania');

SET IDENTITY_INSERT Countries OFF;

-- Seed States (Including key regions in the Balkan region)
SET IDENTITY_INSERT States ON;

INSERT INTO States (StateId, StateName, CountryId) VALUES
(1, 'California', 1),
(2, 'Ontario', 2),
(3, 'Federation of Bosnia and Herzegovina', 3),
(4, 'Republika Srpska', 3),
(5, 'Central Serbia', 4),
(6, 'Vojvodina', 4),
(7, 'Zagreb', 5),
(8, 'Dalmatia', 5),
(9, 'Podgorica', 6),
(10, 'Primorska', 7),
(11, 'Skopje', 8),
(12, 'Tirana', 9);

SET IDENTITY_INSERT States OFF;

-- Seed Cities (Including major cities in the Balkan region)
SET IDENTITY_INSERT Cities ON;

INSERT INTO Cities (CityId, CityName, StateId) VALUES
(1, 'Los Angeles', 1),
(2, 'Toronto', 2),
(3, 'Sarajevo', 3),
(4, 'Banja Luka', 4),
(5, 'Belgrade', 5),
(6, 'Novi Sad', 6),
(7, 'Zagreb', 7),
(8, 'Split', 8),
(9, 'Podgorica', 9),
(10, 'Ljubljana', 10),
(11, 'Skopje', 11),
(12, 'Tirana', 12);

SET IDENTITY_INSERT Cities OFF;

-- Seed Users (Including users from the Balkan region)
SET IDENTITY_INSERT Users ON;

INSERT INTO Users (UserId, Username, Email, PasswordHash, PasswordSalt, PhoneNumber, Address, City, ZipCode, StreetName, StreetNumber, DateOfBirth, UserType, Name, LastName, CreatedDate, UpdatedDate) VALUES
(1, 'johndoe', 'johndoe@example.com', 0x123456789ABCDEF, 0xFEDCBA987654321, '1234567890', '123 Main St', 'Los Angeles', '90001', 'Main St', '123', '1985-06-15', 'Tenant', 'John', 'Doe', GETDATE(), GETDATE()),
(2, 'janedoe', 'janedoe@example.com', 0x123456789ABCDEF, 0xFEDCBA987654321, '0987654321', '456 High St', 'Toronto', 'M5V3L9', 'High St', '456', '1990-09-25', 'Owner', 'Jane', 'Doe', GETDATE(), GETDATE()),
(3, 'amaric', 'amaric@example.com', 0x123456789ABCDEF, 0xFEDCBA987654321, '38761123456', 'Kralja Tomislava 12', 'Sarajevo', '71000', 'Kralja Tomislava', '12', '1985-04-15', 'Tenant', 'Amar', 'Ić', GETDATE(), GETDATE()),
(4, 'spavlovic', 'spavlovic@example.com', 0x123456789ABCDEF, 0xFEDCBA987654321, '38765123456', 'Vuka Karadžića 5', 'Banja Luka', '78000', 'Vuka Karadžića', '5', '1990-09-25', 'Owner', 'Sanja', 'Pavlović', GETDATE(), GETDATE()),
(5, 'mpetrovic', 'mpetrovic@example.com', 0x123456789ABCDEF, 0xFEDCBA987654321, '381641234567', 'Knez Mihailova 22', 'Belgrade', '11000', 'Knez Mihailova', '22', '1987-03-22', 'Tenant', 'Marko', 'Petrović', GETDATE(), GETDATE()),
(6, 'avukovic', 'avukovic@example.com', 0x123456789ABCDEF, 0xFEDCBA987654321, '381211234567', 'Bulevar Oslobođenja 100', 'Novi Sad', '21000', 'Bulevar Oslobođenja', '100', '1992-05-15', 'Owner', 'Ana', 'Vuković', GETDATE(), GETDATE()),
(7, 'tkovacevic', 'tkovacevic@example.com', 0x123456789ABCDEF, 0xFEDCBA987654321, '385981234567', 'Ilica 4', 'Zagreb', '10000', 'Ilica', '4', '1989-07-30', 'Tenant', 'Tomislav', 'Kovačević', GETDATE(), GETDATE()),
(8, 'vmaric', 'vmaric@example.com', 0x123456789ABCDEF, 0xFEDCBA987654321, '38267123456', 'Njegoševa 8', 'Podgorica', '81000', 'Njegoševa', '8', '1995-12-10', 'Owner', 'Vesna', 'Marić', GETDATE(), GETDATE());

SET IDENTITY_INSERT Users OFF;

-- Seed Properties (Including properties from the Balkan region)
SET IDENTITY_INSERT Properties ON;

INSERT INTO Properties (PropertyId, Name, Description, Price, Address, CityId, OwnerId, DateAdded) VALUES
(1, 'Beautiful Apartment', 'A lovely 2-bedroom apartment in downtown.', 2500.00, '789 Park Ave', 1, 2, GETDATE()),
(2, 'Cozy Cottage', 'A small cottage perfect for a getaway.', 1500.00, '123 Country Rd', 2, 2, GETDATE()),
(3, 'Modern Apartment in Sarajevo', 'A beautiful apartment located in the heart of Sarajevo.', 1500.00, 'Titova 10', 3, 2, GETDATE()),
(4, 'Cozy House in Banja Luka', 'A cozy house with a lovely garden.', 1200.00, 'Mladena Stojanovića 3', 4, 2, GETDATE()),
(5, 'Luxury Apartment in Belgrade', 'A luxury apartment with a stunning view of the city.', 2500.00, 'Beogradska 22', 5, 4, GETDATE()),
(6, 'Beachside Villa in Split', 'A beautiful villa near the beach.', 3500.00, 'Riva 1', 8, 2, GETDATE()),
(7, 'Charming Apartment in Zagreb', 'A charming apartment in the center of Zagreb.', 1400.00, 'Trg bana Jelačića 5', 7, 2, GETDATE());

SET IDENTITY_INSERT Properties OFF;

-- Seed Amenities (Common amenities in the Balkan region)
SET IDENTITY_INSERT Amenities ON;

INSERT INTO Amenities (AmenityId, AmenityName) VALUES
(1, 'Wi-Fi'),
(2, 'Air Conditioning'),
(3, 'Parking'),
(4, 'Heating'),
(5, 'Balcony');

SET IDENTITY_INSERT Amenities OFF;

-- Seed PropertyAmenities (Linking properties with their amenities)
INSERT INTO PropertyAmenities (PropertyId, AmenityId) VALUES
(1, 1),  -- Property 1 has Wi-Fi
(1, 2),  -- Property 1 has Air Conditioning
(2, 3),  -- Property 2 has Parking
(2, 4),  -- Property 2 has Heating
(3, 1),  -- Property 3 has Wi-Fi
(3, 5),  -- Property 3 has Balcony
(4, 1),  -- Property 4 has Wi-Fi
(4, 2),  -- Property 4 has Air Conditioning
(4, 5);  -- Property 4 has Balcony

-- Seed Tenants (Tenants residing in these properties)
SET IDENTITY_INSERT Tenants ON;

INSERT INTO Tenants (TenantId, Name, ContactInfo, DateOfBirth, PropertyId, LeaseStartDate, TenantStatus) VALUES
(1, 'John Smith', 'john.smith@example.com', '1987-03-22', 1, '2023-01-01', 'Active'),
(2, 'Emily Johnson', 'emily.johnson@example.com', '1992-05-15', 2, '2023-06-01', 'Active'),
(3, 'Amar Ić', 'amar.ic@example.com', '1985-04-15', 3, '2023-01-01', 'Active'),
(4, 'Marko Petrović', 'marko.p@example.com', '1987-03-22', 5, '2023-02-01', 'Active'),
(5, 'Tomislav Kovačević', 'tomislav.k@example.com', '1989-07-30', 7, '2023-03-01', 'Active');

SET IDENTITY_INSERT Tenants OFF;

-- Seed Bookings (Bookings made by tenants in the Balkan region)
SET IDENTITY_INSERT Bookings ON;

INSERT INTO Bookings (BookingId, PropertyId, UserId, StartDate, EndDate, TotalPrice, BookingDate, Status) VALUES
(1, 1, 1, '2024-09-01', '2024-09-10', 2500.00, GETDATE(), 'Confirmed'),
(2, 2, 1, '2024-10-01', '2024-10-15', 1500.00, GETDATE(), 'Pending'),
(3, 3, 3, '2024-09-01', '2024-09-10', 1500.00, GETDATE(), 'Confirmed'),
(4, 5, 5, '2024-10-01', '2024-10-15', 2500.00, GETDATE(), 'Pending'),
(5, 7, 7, '2024-11-01', '2024-11-20', 1400.00, GETDATE(), 'Confirmed');

SET IDENTITY_INSERT Bookings OFF;

-- Seed Reviews (Reviews from tenants in the Balkan region)
SET IDENTITY_INSERT Reviews ON;

INSERT INTO Reviews (ReviewId, TenantId, PropertyId, Description, StarRating, DateReported, Status, IsComplaint, IsFlagged) VALUES
(1, 1, 1, 'Great place, very comfortable!', 4.5, GETDATE(), 'Published', 0, 0),
(2, 2, 2, 'Had a few issues, but overall okay.', 3.0, GETDATE(), 'Published', 1, 0),
(3, 3, 3, 'Great apartment, very well located!', 4.5, GETDATE(), 'Published', 0, 0),
(4, 4, 5, 'Amazing view, but noisy at night.', 3.5, GETDATE(), 'Published', 1, 0),
(5, 5, 7, 'Charming place, would stay again.', 4.0, GETDATE(), 'Published', 0, 0);

SET IDENTITY_INSERT Reviews OFF;

-- Seed Payments (Payments made by tenants in the Balkan region)
SET IDENTITY_INSERT Payments ON;

INSERT INTO Payments (PaymentId, TenantId, PropertyId, Amount, DatePaid, PaymentMethod, PaymentStatus, PaymentReference) VALUES
(1, 1, 1, 2500.00, GETDATE(), 'Credit Card', 'Completed', 'XYZ12345'),
(2, 2, 2, 1500.00, GETDATE(), 'PayPal', 'Pending', 'ABC67890'),
(3, 3, 3, 1500.00, GETDATE(), 'Credit Card', 'Completed', 'BA12345'),
(4, 4, 5, 2500.00, GETDATE(), 'Bank Transfer', 'Completed', 'RS67890'),
(5, 5, 7, 1400.00, GETDATE(), 'Credit Card', 'Completed', 'HR11223');

SET IDENTITY_INSERT Payments OFF;

-- Seed Messages (Messages exchanged between users in the Balkan region)
SET IDENTITY_INSERT Messages ON;

INSERT INTO Messages (MessageId, SenderId, ReceiverId, MessageText, DateSent, IsRead) VALUES
(1, 1, 2, 'Hello! Is the property still available?', GETDATE(), 0),
(2, 2, 1, 'Yes, it is available. Let me know if you have any questions.', GETDATE(), 0),
(3, 3, 4, 'Is the apartment in Sarajevo still available?', GETDATE(), 0),
(4, 4, 3, 'Yes, it is available.', GETDATE(), 1),
(5, 5, 6, 'Could I get a discount for the booking in Belgrade?', GETDATE(), 0);

SET IDENTITY_INSERT Messages OFF;

-- Seed Reports (Generated reports for the Balkan region properties)
SET IDENTITY_INSERT Reports ON;

INSERT INTO Reports (ReportId, GeneratedBy, DateGenerated, ReportType, FilePath, Summary) VALUES
(1, 2, GETDATE(), 'Monthly', '/reports/monthly_report_2024_08.pdf', 'Summary of August 2024'),
(2, 4, GETDATE(), 'Annual', '/reports/annual_report_2023.pdf', 'Summary of the year 2023');

SET IDENTITY_INSERT Reports OFF;

-- Seed Images (Property images for the Balkan region)
SET IDENTITY_INSERT Images ON;

INSERT INTO Images (ImageId, PropertyId, FileName, ImageData, DateUploaded) VALUES
(1, 1, 'apartment_1.jpg', 0x123456789ABCDEF, GETDATE()),
(2, 2, 'cottage_1.jpg', 0x123456789ABCDEF, GETDATE()),
(3, 3, 'sarajevo_apartment.jpg', 0x123456789ABCDEF, GETDATE()),
(4, 4, 'banja_luka_house.jpg', 0x123456789ABCDEF, GETDATE()),
(5, 5, 'belgrade_apartment.jpg', 0x123456789ABCDEF, GETDATE()),
(6, 6, 'split_villa.jpg', 0x123456789ABCDEF, GETDATE()),
(7, 7, 'zagreb_apartment.jpg', 0x123456789ABCDEF, GETDATE());

SET IDENTITY_INSERT Images OFF;