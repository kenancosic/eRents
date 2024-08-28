-- Seed Locations
SET IDENTITY_INSERT Location ON;

INSERT INTO Location (location_id, City, State, Country, PostalCode, Latitude, Longitude) VALUES
(1, 'Los Angeles', 'California', 'United States', '90001', 34.0522, -118.2437),
(2, 'Toronto', 'Ontario', 'Canada', 'M5V3L9', 43.65107, -79.347015),
(3, 'Sarajevo', 'Federation of Bosnia and Herzegovina', 'Bosnia and Herzegovina', '71000', 43.8563, 18.4131),
(4, 'Banja Luka', 'Republika Srpska', 'Bosnia and Herzegovina', '78000', 44.7722, 17.1910),
(5, 'Belgrade', 'Central Serbia', 'Serbia', '11000', 44.7866, 20.4489),
(6, 'Novi Sad', 'Vojvodina', 'Serbia', '21000', 45.2671, 19.8335),
(7, 'Zagreb', 'Zagreb', 'Croatia', '10000', 45.8150, 15.9819),
(8, 'Split', 'Dalmatia', 'Croatia', '21000', 43.5081, 16.4402),
(9, 'Podgorica', 'Podgorica', 'Montenegro', '81000', 42.4304, 19.2594),
(10, 'Ljubljana', 'Primorska', 'Slovenia', '1000', 46.0569, 14.5058);

SET IDENTITY_INSERT Location OFF;

-- Seed Users
SET IDENTITY_INSERT Users ON;

INSERT INTO Users (user_id, username, email, PasswordHash, PasswordSalt, phone_number, address, location_id, date_of_birth, user_type, name, last_name, created_date, updated_date) VALUES
(1, 'johndoe', 'johndoe@example.com', 0x8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497, 0x4823C4041A2FD159B9E4F69D05495995, '1234567890', '123 Main St', 1, '1985-06-15', 'Tenant', 'John', 'Doe', GETDATE(), GETDATE()),
(2, 'janedoe', 'janedoe@example.com', 0x8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497, 0x4823C4041A2FD159B9E4F69D05495995, '0987654321', '456 High St', 2, '1990-09-25', 'Landlord', 'Jane', 'Doe', GETDATE(), GETDATE()),
(3, 'amaric', 'amaric@example.com', 0x8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497, 0x4823C4041A2FD159B9E4F69D05495995, '38761123456', 'Kralja Tomislava 12', 3, '1985-04-15', 'Tenant', 'Amar', 'Ić', GETDATE(), GETDATE()),
(4, 'spavlovic', 'spavlovic@example.com', 0x8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497, 0x4823C4041A2FD159B9E4F69D05495995, '38765123456', 'Vuka Karadžića 5', 4, '1990-09-25', 'Landlord', 'Sanja', 'Pavlović', GETDATE(), GETDATE()),
(5, 'mpetrovic', 'mpetrovic@example.com', 0x8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497, 0x4823C4041A2FD159B9E4F69D05495995, '381641234567', 'Knez Mihailova 22', 5, '1987-03-22', 'Tenant', 'Marko', 'Petrović', GETDATE(), GETDATE());

SET IDENTITY_INSERT Users OFF;

-- Seed Properties
SET IDENTITY_INSERT Properties ON;

INSERT INTO Properties (property_id, name, description, price, address, location_id, owner_id, date_added) VALUES
(1, 'Beautiful Apartment', 'A lovely 2-bedroom apartment in downtown.', 2500.00, '789 Park Ave', 1, 2, GETDATE()), 
(2, 'Cozy Cottage', 'A small cottage perfect for a getaway.', 1500.00, '123 Country Rd', 2, 2, GETDATE()), 
(3, 'Modern Apartment in Sarajevo', 'A beautiful apartment located in the heart of Sarajevo.', 1500.00, 'Titova 10', 3, 4, GETDATE()), 
(4, 'Cozy House in Banja Luka', 'A cozy house with a lovely garden.', 1200.00, 'Mladena Stojanovića 3', 4, 4, GETDATE()), 
(5, 'Luxury Apartment in Belgrade', 'A luxury apartment with a stunning view of the city.', 2500.00, 'Beogradska 22', 5, 5, GETDATE()), 
(6, 'Beachside Villa in Split', 'A beautiful villa near the beach.', 3500.00, 'Riva 1', 8, 2, GETDATE()), 
(7, 'Charming Apartment in Zagreb', 'A charming apartment in the center of Zagreb.', 1400.00, 'Trg bana Jelačića 5', 7, 6, GETDATE());

SET IDENTITY_INSERT Properties OFF;

-- Seed Amenities (Common amenities in the Balkan region)
SET IDENTITY_INSERT Amenities ON;

INSERT INTO Amenities (amenity_id, amenity_name) VALUES
(1, 'Wi-Fi'),
(2, 'Air Conditioning'),
(3, 'Parking'),
(4, 'Heating'),
(5, 'Balcony');

SET IDENTITY_INSERT Amenities OFF;

-- Seed PropertyAmenities (Linking properties with their amenities)
INSERT INTO PropertyAmenities (property_id, amenity_id) VALUES
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

INSERT INTO Tenants (tenant_id, name, contact_info, date_of_birth, property_id, lease_start_date, tenant_status) VALUES
(1, 'John Smith', 'john.smith@example.com', '1987-03-22', 1, '2023-01-01', 'Active'),
(2, 'Emily Johnson', 'emily.johnson@example.com', '1992-05-15', 2, '2023-06-01', 'Active'),
(3, 'Amar Ić', 'amar.ic@example.com', '1985-04-15', 3, '2023-01-01', 'Active'),
(4, 'Marko Petrović', 'marko.p@example.com', '1987-03-22', 5, '2023-02-01', 'Active'),
(5, 'Tomislav Kovačević', 'tomislav.k@example.com', '1989-07-30', 7, '2023-03-01', 'Active');

SET IDENTITY_INSERT Tenants OFF;

-- Seed Bookings (Bookings made by tenants in the Balkan region)
SET IDENTITY_INSERT Bookings ON;

INSERT INTO Bookings (booking_id, property_id, user_id, start_date, end_date, total_price, booking_date, status) VALUES
(1, 1, 1, '2024-09-01', '2024-09-10', 2500.00, GETDATE(), 'Confirmed'),
(2, 2, 1, '2024-10-01', '2024-10-15', 1500.00, GETDATE(), 'Pending'),
(3, 3, 3, '2024-09-01', '2024-09-10', 1500.00, GETDATE(), 'Confirmed'),
(4, 5, 5, '2024-10-01', '2024-10-15', 2500.00, GETDATE(), 'Pending'),
(5, 7, 7, '2024-11-01', '2024-11-20', 1400.00, GETDATE(), 'Confirmed');

SET IDENTITY_INSERT Bookings OFF;

-- Seed Reviews (Reviews from tenants in the Balkan region)
SET IDENTITY_INSERT Reviews ON;

INSERT INTO Reviews (review_id, tenant_id, property_id, description, StarRating, date_reported, status, IsComplaint, is_flagged) VALUES
(1, 1, 1, 'Great place, very comfortable!', 4.5, GETDATE(), 'Resolved', 0, 0),
(2, 2, 2, 'Had a few issues, but overall okay.', 3.0, GETDATE(), 'Resolved', 1, 0),
(3, 3, 3, 'Great apartment, very well located!', 4.5, GETDATE(), 'Resolved', 0, 0),
(4, 4, 5, 'Amazing view, but noisy at night.', 3.5, GETDATE(), 'Resolved', 1, 0),
(5, 5, 7, 'Charming place, would stay again.', 4.0, GETDATE(), 'Resolved', 0, 0);

SET IDENTITY_INSERT Reviews OFF;

-- Seed Payments (Payments made by tenants in the Balkan region)
SET IDENTITY_INSERT Payments ON;

INSERT INTO Payments (payment_id, tenant_id, property_id, amount, date_paid, payment_method, payment_status, payment_reference) VALUES
(1, 1, 1, 2500.00, GETDATE(), 'Credit Card', 'Completed', 'XYZ12345'),
(2, 2, 2, 1500.00, GETDATE(), 'PayPal', 'Pending', 'ABC67890'),
(3, 3, 3, 1500.00, GETDATE(), 'Credit Card', 'Completed', 'BA12345'),
(4, 4, 5, 2500.00, GETDATE(), 'Bank Transfer', 'Completed', 'RS67890'),
(5, 5, 7, 1400.00, GETDATE(), 'Credit Card', 'Completed', 'HR11223');

SET IDENTITY_INSERT Payments OFF;

-- Seed Messages (Messages exchanged between users in the Balkan region)
SET IDENTITY_INSERT Messages ON;

INSERT INTO Messages (message_id, sender_id, receiver_id, message_text, date_sent, is_read) VALUES
(1, 1, 2, 'Hello! Is the property still available?', GETDATE(), 0),
(2, 2, 1, 'Yes, it is available. Let me know if you have any questions.', GETDATE(), 0),
(3, 3, 4, 'Is the apartment in Sarajevo still available?', GETDATE(), 0),
(4, 4, 3, 'Yes, it is available.', GETDATE(), 1),
(5, 5, 6, 'Could I get a discount for the booking in Belgrade?', GETDATE(), 0);

SET IDENTITY_INSERT Messages OFF;

-- Seed Reports (Generated reports for the Balkan region properties)
SET IDENTITY_INSERT Reports ON;

INSERT INTO Reports (report_id, generated_by, date_generated, report_type, file_path, summary) VALUES
(1, 2, GETDATE(), 'Monthly', '/reports/monthly_report_2024_08.pdf', 'Summary of August 2024'),
(2, 4, GETDATE(), 'Annual', '/reports/annual_report_2023.pdf', 'Summary of the year 2023');

SET IDENTITY_INSERT Reports OFF;

-- Seed Images (Property images for the Balkan region)
SET IDENTITY_INSERT Images ON;

INSERT INTO Images (ImageId, PropertyId, file_name, ImageData, DateUploaded) VALUES
(1, 1, 'apartment_1.jpg',  0x89504E470D0A1A0A0000000D49484452000001000000010008060000005702F987000000097048597300000B1300000B1301009A9C180000001074494D4507E10711000D1733D7F2407F, GETDATE()),
(2, 2, 'cottage_1.jpg',  0x89504E470D0A1A0A0000000D49484452000001000000010008060000005702F987000000097048597300000B1300000B1301009A9C180000001074494D4507E10711000D1733D7F2407F, GETDATE()),
(3, 3, 'sarajevo_apartment.jpg',  0x89504E470D0A1A0A0000000D49484452000001000000010008060000005702F987000000097048597300000B1300000B1301009A9C180000001074494D4507E10711000D1733D7F2407F, GETDATE()),
(4, 4, 'banja_luka_house.jpg',  0x89504E470D0A1A0A0000000D49484452000001000000010008060000005702F987000000097048597300000B1300000B1301009A9C180000001074494D4507E10711000D1733D7F2407F, GETDATE()),
(5, 5, 'belgrade_apartment.jpg',  0x89504E470D0A1A0A0000000D49484452000001000000010008060000005702F987000000097048597300000B1300000B1301009A9C180000001074494D4507E10711000D1733D7F2407F, GETDATE()),
(6, 6, 'split_villa.jpg',  0x89504E470D0A1A0A0000000D49484452000001000000010008060000005702F987000000097048597300000B1300000B1301009A9C180000001074494D4507E10711000D1733D7F2407F, GETDATE()),
(7, 7, 'zagreb_apartment.jpg',  0x89504E470D0A1A0A0000000D49484452000001000000010008060000005702F987000000097048597300000B1300000B1301009A9C180000001074494D4507E10711000D1733D7F2407F, GETDATE());

SET IDENTITY_INSERT Images OFF;
