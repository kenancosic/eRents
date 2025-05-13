-- Seed Locations
SET IDENTITY_INSERT Location ON;

INSERT INTO Location (location_id, City, State, Country, PostalCode, Latitude, Longitude) VALUES
(1, 'Sarajevo', 'Federation of Bosnia and Herzegovina', 'Bosnia and Herzegovina', '71000', 43.8563, 18.4131),
(2, 'Banja Luka', 'Republika Srpska', 'Bosnia and Herzegovina', '78000', 44.7722, 17.1910),
(3, 'Mostar', 'Federation of Bosnia and Herzegovina', 'Bosnia and Herzegovina', '88000', 43.3438, 17.8078),
(4, 'Tuzla', 'Federation of Bosnia and Herzegovina', 'Bosnia and Herzegovina', '75000', 44.5384, 18.6739),
(5, 'Zenica', 'Federation of Bosnia and Herzegovina', 'Bosnia and Herzegovina', '72000', 44.2039, 17.9077),
(6, 'Bihać', 'Federation of Bosnia and Herzegovina', 'Bosnia and Herzegovina', '77000', 44.8169, 15.8700),
(7, 'Trebinje', 'Republika Srpska', 'Bosnia and Herzegovina', '89000', 42.7116, 18.3436),
(8, 'Prijedor', 'Republika Srpska', 'Bosnia and Herzegovina', '79000', 44.9792, 16.7147);

SET IDENTITY_INSERT Location OFF;

-- Seed UserTypes
SET IDENTITY_INSERT UserType ON;

INSERT INTO UserType (UserTypeId, TypeName) VALUES
(1, 'Tenant'),
(2, 'Landlord'),
(3, 'Admin');

SET IDENTITY_INSERT UserType OFF;

-- Seed Users
SET IDENTITY_INSERT Users ON;

INSERT INTO Users (user_id, username, email, PasswordHash, PasswordSalt, phone_number, location_id, date_of_birth, UserTypeId, name, last_name, created_date, updated_date) VALUES
(1, 'amerhasic', 'amer.hasic@example.ba', 0x8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497, 0x4823C4041A2FD159B9E4F69D05495995, '38761123123', 1, '1990-05-15', 1, 'Amer', 'Hasić', GETDATE(), GETDATE()),
(2, 'lejlazukic', 'lejla.zukic@example.ba', 0x8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497, 0x4823C4041A2FD159B9E4F69D05495995, '38762321321', 2, '1988-11-20', 2, 'Lejla', 'Zukić', GETDATE(), GETDATE()),
(3, 'adnanSA', 'adnan.sa@example.ba', 0x8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497, 0x4823C4041A2FD159B9E4F69D05495995, '38761456456', 1, '1985-04-15', 1, 'Adnan', 'Sarajlić', GETDATE(), GETDATE()),
(4, 'ivanabL', 'ivana.bl@example.ba', 0x8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497, 0x4823C4041A2FD159B9E4F69D05495995, '38765789789', 2, '1992-09-25', 2, 'Ivana', 'Babić', GETDATE(), GETDATE()),
(5, 'markoMO', 'marko.mo@example.ba', 0x8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497, 0x4823C4041A2FD159B9E4F69D05495995, '38763123789', 3, '1987-03-22', 1, 'Marko', 'Marić', GETDATE(), GETDATE()),
(6, 'adminuser', 'admin@erents.ba', 0x8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497, 0x4823C4041A2FD159B9E4F69D05495995, '38760000000', 1, '1980-01-01', 3, 'Admin', 'User', GETDATE(), GETDATE()),
(7, 'tarikTZ', 'tarik.tz@example.ba', 0x8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497, 0x4823C4041A2FD159B9E4F69D05495995, '38761987654', 4, '1995-07-10', 1, 'Tarik', 'Hadžić', GETDATE(), GETDATE()),
(8, 'eminaBI', 'emina.bi@example.ba', 0x8D30241BCAC15B66F0AD1978AB51BE9442B64919C8CBD249AEA932BCD7FE2497, 0x4823C4041A2FD159B9E4F69D05495995, '38762876543', 6, '1993-02-28', 2, 'Emina', 'Kovačević', GETDATE(), GETDATE());

SET IDENTITY_INSERT Users OFF;

-- Seed PropertyTypes
SET IDENTITY_INSERT PropertyType ON;

INSERT INTO PropertyType (TypeId, TypeName) VALUES
(1, 'Apartment'),
(2, 'House'),
(3, 'Condo'),
(4, 'Villa');

SET IDENTITY_INSERT PropertyType OFF;

-- Seed RentingTypes
SET IDENTITY_INSERT RentingType ON;

INSERT INTO RentingType (RentingTypeId, TypeName) VALUES
(1, 'Long-term'),
(2, 'Short-term'),
(3, 'Vacation');

SET IDENTITY_INSERT RentingType OFF;

-- Seed Properties
SET IDENTITY_INSERT Properties ON;

INSERT INTO Properties (property_id, name, description, price, address, location_id, owner_id, date_added, PropertyTypeId, RentingTypeId) VALUES
(1, 'Stan u Centru Sarajeva', 'Prostran stan na odličnoj lokaciji u Sarajevu.', 800.00, 'Maršala Tita 15', 1, 2, GETDATE(), 1, 1), 
(2, 'Kuća s Pogledom u Banjaluci', 'Kuća sa prelijepim pogledom na grad.', 1200.00, 'Vidikovac 3', 2, 2, GETDATE(), 2, 1), 
(3, 'Apartman Stari Most Mostar', 'Moderan apartman blizu Starog Mosta.', 600.00, 'Kujundžiluk 5', 3, 4, GETDATE(), 1, 2), 
(4, 'Porodična Kuća Tuzla', 'Idealna kuća za porodicu u mirnom dijelu Tuzle.', 950.00, 'Hasana Kikića 10', 4, 4, GETDATE(), 2, 1), 
(5, 'Luksuzni Apartman Zenica', 'Luksuzno opremljen apartman u centru Zenice.', 700.00, 'Trg Alije Izetbegovića 1', 5, 2, GETDATE(), 1, 2),
(6, 'Vikendica na Uni Bihać', 'Prelijepa vikendica uz rijeku Unu.', 1500.00, 'Una bb', 6, 8, GETDATE(), 4, 3),
(7, 'Stan u Trebinju', 'Komforan stan u sunčanom Trebinju.', 550.00, 'Njegoševa 7', 7, 8, GETDATE(), 1, 1),
(8, 'Apartman Prijedor Centar', 'Novoopremljen apartman u centru Prijedora.', 450.00, 'Kralja Petra I Oslobodyjenja 22', 8, 4, GETDATE(), 1, 2);

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
(1, 1),  -- Property 1 (Sarajevo) has Wi-Fi
(1, 2),  -- Property 1 (Sarajevo) has Air Conditioning
(1, 5),  -- Property 1 (Sarajevo) has Balcony
(2, 1),  -- Property 2 (Banja Luka) has Wi-Fi
(2, 3),  -- Property 2 (Banja Luka) has Parking
(2, 4),  -- Property 2 (Banja Luka) has Heating
(3, 1),  -- Property 3 (Mostar) has Wi-Fi
(3, 2),  -- Property 3 (Mostar) has Air Conditioning
(4, 1),  -- Property 4 (Tuzla) has Wi-Fi
(4, 3),  -- Property 4 (Tuzla) has Parking
(4, 5),  -- Property 4 (Tuzla) has Balcony
(5, 1),  -- Property 5 (Zenica) has Wi-Fi
(5, 2),  -- Property 5 (Zenica) has Air Conditioning
(6, 1),  -- Property 6 (Bihać) has Wi-Fi
(6, 3),  -- Property 6 (Bihać) has Parking
(6, 5),  -- Property 6 (Bihać) has Balcony
(7, 1),  -- Property 7 (Trebinje) has Wi-Fi
(7, 2),  -- Property 7 (Trebinje) has Air Conditioning
(8, 1),  -- Property 8 (Prijedor) has Wi-Fi
(8, 4);  -- Property 8 (Prijedor) has Heating

-- Seed Tenants (Tenants residing in these properties)
SET IDENTITY_INSERT Tenants ON;

INSERT INTO Tenants (tenant_id, name, contact_info, date_of_birth, property_id, lease_start_date, tenant_status) VALUES
(1, 'Amer Hasić', 'amer.hasic@example.ba', '1990-05-15', 1, '2023-01-01', 'Active'), -- Linked to User 1
(2, 'Marko Marić', 'marko.mo@example.ba', '1987-03-22', 3, '2023-02-01', 'Active'), -- Linked to User 5
(3, 'Adnan Sarajlić', 'adnan.sa@example.ba', '1985-04-15', 4, '2023-03-01', 'Active'), -- Linked to User 3
(4, 'Tarik Hadžić', 'tarik.tz@example.ba', '1995-07-10', 7, '2023-08-15', 'Active'); -- Linked to User 7

SET IDENTITY_INSERT Tenants OFF;

-- Seed Bookings (Bookings made by users in Bosnia and Herzegovina)
SET IDENTITY_INSERT Bookings ON;

INSERT INTO Bookings (booking_id, property_id, user_id, start_date, end_date, total_price, booking_date, status) VALUES
(1, 1, 1, '2024-09-01', '2024-09-10', 250.00, GETDATE(), 'Confirmed'), -- Amer Hasić books Stan u Centru Sarajeva
(2, 3, 5, '2024-10-01', '2024-10-05', 100.00, GETDATE(), 'Pending'),   -- Marko Marić books Apartman Stari Most Mostar
(3, 2, 1, '2024-11-01', '2024-11-15', 500.00, GETDATE(), 'Confirmed'),  -- Amer Hasić books Kuća s Pogledom u Banjaluci
(4, 6, 7, '2024-07-20', '2024-07-27', 350.00, GETDATE(), 'Confirmed'), -- Tarik Hadžić books Vikendica na Uni Bihać
(5, 8, 3, '2024-08-05', '2024-08-10', 150.00, GETDATE(), 'Pending');    -- Adnan Sarajlić books Apartman Prijedor Centar

SET IDENTITY_INSERT Bookings OFF;

-- Seed Reviews (Reviews from users for properties in Bosnia and Herzegovina)
SET IDENTITY_INSERT Reviews ON;

-- Note: Review entity expects BookingId. Ensure these BookingIds exist from the Bookings seed data.
INSERT INTO Reviews (review_id, property_id, BookingId, description, StarRating, date_reported) VALUES
(1, 1, 1, 'Odličan stan, super lokacija!', 4.8, GETDATE()),
(2, 3, 2, 'Malo bučno, ali pogled je nevjerovatan.', 3.5, GETDATE()),
(3, 2, 3, 'Sve preporuke, kuća je predivna.', 5.0, GETDATE()),
(4, 6, 4, 'Vikendica iz snova, Una je čarobna.', 4.9, GETDATE()),
(5, 8, 5, 'Apartman je čist i uredan, preporuka.', 4.2, GETDATE());

SET IDENTITY_INSERT Reviews OFF;

-- Seed Payments (Payments made by tenants in Bosnia and Herzegovina)
SET IDENTITY_INSERT Payments ON;

INSERT INTO Payments (payment_id, tenant_id, property_id, amount, date_paid, payment_method, payment_status, payment_reference) VALUES
(1, 1, 1, 800.00, GETDATE(), 'PayPal', 'Completed', 'BH_XYZ123'), -- Payment for Amer Hasić
(2, 2, 3, 600.00, GETDATE(), 'PayPal', 'Pending', 'BH_ABC456'),       -- Payment for Marko Marić
(3, 3, 4, 950.00, GETDATE(), 'PayPal', 'Completed', 'BH_DEF789'), -- Payment for Adnan Sarajlić
(4, 4, 7, 550.00, GETDATE(), 'PayPal', 'Completed', 'BH_GHI012'); -- Payment for Tarik Hadžić

SET IDENTITY_INSERT Payments OFF;

-- Seed Messages (Messages exchanged between users in Bosnia and Herzegovina)
SET IDENTITY_INSERT Messages ON;

INSERT INTO Messages (message_id, sender_id, receiver_id, message_text, date_sent, is_read) VALUES
(1, 1, 2, 'Poštovani, da li je stan u Sarajevu slobodan od septembra?', GETDATE(), 0), -- Amer to Lejla
(2, 2, 1, 'Jeste, slobodan je. Javite ako imate dodatnih pitanja.', GETDATE(), 0),    -- Lejla to Amer
(3, 5, 4, 'Interesuje me apartman u Mostaru, da li je dostupan za kratkoročni najam?', GETDATE(), 0), -- Marko to Ivana
(4, 4, 5, 'Dostupan je, izvolite rezervisati.', GETDATE(), 1),                                  -- Ivana to Marko
(5, 7, 8, 'Pozdrav, zanima me vikendica u Bihaću, je li slobodna za vikend?', GETDATE(), 0), -- Tarik to Emina
(6, 8, 7, 'Poštovani Tarik, vikendica je slobodna. Možete rezervisati.', GETDATE(), 0);    -- Emina to Tarik

SET IDENTITY_INSERT Messages OFF;

-- Seed Images (Property images for Bosnia and Herzegovina properties)
SET IDENTITY_INSERT Images ON;

INSERT INTO Images (ImageId, PropertyId, file_name, ImageData, DateUploaded) VALUES
(1, 1, 'sarajevo_stan_1.jpg',  0x89504E470D0A1A0A0000000D49484452000001000000010008060000005702F987000000097048597300000B1300000B1301009A9C180000001074494D4507E10711000D1733D7F2407F, GETDATE()),
(2, 2, 'banjaluka_kuca_1.jpg',  0x89504E470D0A1A0A0000000D49484452000001000000010008060000005702F987000000097048597300000B1300000B1301009A9C180000001074494D4507E10711000D1733D7F2407F, GETDATE()),
(3, 3, 'mostar_apartman_1.jpg',  0x89504E470D0A1A0A0000000D49484452000001000000010008060000005702F987000000097048597300000B1300000B1301009A9C180000001074494D4507E10711000D1733D7F2407F, GETDATE()),
(4, 4, 'tuzla_kuca_1.jpg',  0x89504E470D0A1A0A0000000D49484452000001000000010008060000005702F987000000097048597300000B1300000B1301009A9C180000001074494D4507E10711000D1733D7F2407F, GETDATE()),
(5, 5, 'zenica_apartman_1.jpg',  0x89504E470D0A1A0A0000000D49484452000001000000010008060000005702F987000000097048597300000B1300000B1301009A9C180000001074494D4507E10711000D1733D7F2407F, GETDATE());

SET IDENTITY_INSERT Images OFF;

-- Seed IssuePriority
SET IDENTITY_INSERT IssuePriority ON;

INSERT INTO IssuePriority (PriorityId, PriorityName) VALUES
(1, 'Low'),
(2, 'Medium'),
(3, 'High');

SET IDENTITY_INSERT IssuePriority OFF;

-- Seed IssueStatus
SET IDENTITY_INSERT IssueStatus ON;

INSERT INTO IssueStatus (StatusId, StatusName) VALUES
(1, 'Open'),
(2, 'In Progress'),
(3, 'Resolved'),
(4, 'Closed');

SET IDENTITY_INSERT IssueStatus OFF;

-- Seed PropertyStatus
SET IDENTITY_INSERT PropertyStatus ON;

INSERT INTO PropertyStatus (StatusId, StatusName) VALUES
(1, 'Available'),
(2, 'Rented'),
(3, 'Under Maintenance'),
(4, 'Unavailable');

SET IDENTITY_INSERT PropertyStatus OFF;

-- Seed MaintenanceIssues
SET IDENTITY_INSERT MaintenanceIssue ON;

INSERT INTO MaintenanceIssue (MaintenanceIssueId, PropertyId, Title, Description, Cost, Category, PriorityId, StatusId, ReportedByUserId, AssignedToUserId, CreatedAt) VALUES
(1, 1, 'Leaking Faucet in Kitchen', 'The kitchen faucet has a persistent drip.', 50.00, 'Plumbing', 2, 1, 1, 2, GETDATE()), -- Property 1, Reported by Amer (User 1), Assigned to Lejla (User 2)
(2, 3, 'Broken Window Pane', 'A window pane in the living room is cracked.', 120.00, 'Window Repair', 3, 1, 5, 4, GETDATE()), -- Property 3, Reported by Marko (User 5), Assigned to Ivana (User 4)
(3, 2, 'Heating System Malfunction', 'The central heating is not working correctly.', 250.00, 'HVAC', 3, 2, 1, 2, GETDATE()), -- Property 2, Reported by Amer (User 1), Assigned to Lejla (User 2), In Progress
(4, 7, 'Wi-Fi signal weak in bedroom', 'Internet connection is unstable in the master bedroom.', 30.00, 'Internet', 1, 1, 7, 8, GETDATE()), -- Property 7, Reported by Tarik (User 7), Assigned to Emina (User 8)
(5, 6, 'Loose door handle on bathroom', 'Bathroom door handle is loose and needs tightening.', 15.00, 'General Repair', 1, 3, 7, 8, GETDATE()); -- Property 6, Reported by Tarik (User 7), Assigned to Emina (User 8), Resolved

SET IDENTITY_INSERT MaintenanceIssue OFF;

-- Seed TenantPreferences
SET IDENTITY_INSERT TenantPreference ON;

INSERT INTO TenantPreference (TenantPreferenceId, UserId, City, MinPrice, MaxPrice, IsActive) VALUES
(1, 1, 'Sarajevo', 500.00, 900.00, 1), -- Amer Hasić (User 1)
(2, 3, 'Mostar', 400.00, 700.00, 1),   -- Adnan Sarajlić (User 3)
(3, 5, 'Banja Luka', 600.00, 1300.00, 1), -- Marko Marić (User 5)
(4, 7, 'Tuzla', 300.00, 600.00, 1); -- Tarik Hadžić (User 7)

SET IDENTITY_INSERT TenantPreference OFF;

-- Seed TenantPreferenceAmenities (Linking TenantPreferences with Amenities)
-- TenantPreferenceId 1 (Amer Hasić) prefers Wi-Fi (1) and Parking (3)
INSERT INTO TenantPreferenceAmenity (TenantPreferenceId, AmenityId) VALUES
(1, 1),
(1, 3);

-- TenantPreferenceId 2 (Adnan Sarajlić) prefers Air Conditioning (2) and Balcony (5)
INSERT INTO TenantPreferenceAmenity (TenantPreferenceId, AmenityId) VALUES
(2, 2),
(2, 5);

-- TenantPreferenceId 3 (Marko Marić) prefers Wi-Fi (1), Air Conditioning (2), and Heating (4)
INSERT INTO TenantPreferenceAmenity (TenantPreferenceId, AmenityId) VALUES
(3, 1),
(3, 2),
(3, 4);

-- TenantPreferenceId 4 (Tarik Hadžić) prefers Wi-Fi (1) and Parking (3)
INSERT INTO TenantPreferenceAmenity (TenantPreferenceId, AmenityId) VALUES
(4, 1),
(4, 3);

-- Seed UserSavedProperties
INSERT INTO UserSavedProperty (UserId, PropertyId, DateSaved) VALUES
(1, 2, GETDATE()), -- Amer Hasić (User 1) saved Property 2 (Kuća s Pogledom u Banjaluci)
(1, 3, GETDATE()), -- Amer Hasić (User 1) saved Property 3 (Apartman Stari Most Mostar)
(3, 1, GETDATE()), -- Adnan Sarajlić (User 3) saved Property 1 (Stan u Centru Sarajeva)
(5, 4, GETDATE()), -- Marko Marić (User 5) saved Property 4 (Porodična Kuća Tuzla)
(2, 5, GETDATE()), -- Lejla Zukić (User 2) saved Property 5 (Luksuzni Apartman Zenica)
(7, 6, GETDATE()), -- Tarik Hadžić (User 7) saved Property 6 (Vikendica na Uni Bihać)
(8, 7, GETDATE()), -- Emina Kovačević (User 8) saved Property 7 (Stan u Trebinju)
(1, 8, GETDATE()); -- Amer Hasić (User 1) saved Property 8 (Apartman Prijedor Centar)
