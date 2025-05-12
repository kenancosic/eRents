using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Amenities",
                columns: table => new
                {
                    amenity_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    amenity_name = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Amenitie__E908452DD87B33D9", x => x.amenity_id);
                });

            migrationBuilder.CreateTable(
                name: "IssuePriorities",
                columns: table => new
                {
                    PriorityId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PriorityName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_IssuePriorities", x => x.PriorityId);
                });

            migrationBuilder.CreateTable(
                name: "IssueStatuses",
                columns: table => new
                {
                    StatusId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    StatusName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_IssueStatuses", x => x.StatusId);
                });

            migrationBuilder.CreateTable(
                name: "Location",
                columns: table => new
                {
                    location_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    City = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    State = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    Country = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    PostalCode = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    Latitude = table.Column<decimal>(type: "decimal(9,6)", nullable: true),
                    Longitude = table.Column<decimal>(type: "decimal(9,6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Location__E7FEA47700C11F68", x => x.location_id);
                });

            migrationBuilder.CreateTable(
                name: "PropertyStatuses",
                columns: table => new
                {
                    StatusId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    StatusName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyStatuses", x => x.StatusId);
                });

            migrationBuilder.CreateTable(
                name: "PropertyTypes",
                columns: table => new
                {
                    TypeId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TypeName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyTypes", x => x.TypeId);
                });

            migrationBuilder.CreateTable(
                name: "RentingTypes",
                columns: table => new
                {
                    RentingTypeId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TypeName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RentingTypes", x => x.RentingTypeId);
                });

            migrationBuilder.CreateTable(
                name: "UserTypes",
                columns: table => new
                {
                    UserTypeId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TypeName = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserTypes", x => x.UserTypeId);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    user_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    username = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: false),
                    email = table.Column<string>(type: "varchar(100)", unicode: false, maxLength: 100, nullable: false),
                    phone_number = table.Column<string>(type: "varchar(20)", unicode: false, maxLength: 20, nullable: true),
                    date_of_birth = table.Column<DateOnly>(type: "date", nullable: true),
                    user_type = table.Column<string>(type: "varchar(20)", unicode: false, maxLength: 20, nullable: true),
                    profile_picture = table.Column<byte[]>(type: "varbinary(max)", nullable: true),
                    created_date = table.Column<DateTime>(type: "datetime", nullable: true, defaultValueSql: "(getdate())"),
                    updated_date = table.Column<DateTime>(type: "datetime", nullable: true, defaultValueSql: "(getdate())"),
                    PasswordSalt = table.Column<byte[]>(type: "varbinary(64)", maxLength: 64, nullable: false),
                    PasswordHash = table.Column<byte[]>(type: "varbinary(64)", maxLength: 64, nullable: false),
                    name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    last_name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    reset_token = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    reset_token_expiration = table.Column<DateTime>(type: "datetime", nullable: true),
                    location_id = table.Column<int>(type: "int", nullable: true),
                    UserTypeId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Users__B9BE370FCB53D7B9", x => x.user_id);
                    table.ForeignKey(
                        name: "FK_User_LocationID",
                        column: x => x.location_id,
                        principalTable: "Location",
                        principalColumn: "location_id");
                    table.ForeignKey(
                        name: "FK_Users_UserTypes_UserTypeId",
                        column: x => x.UserTypeId,
                        principalTable: "UserTypes",
                        principalColumn: "UserTypeId");
                });

            migrationBuilder.CreateTable(
                name: "Messages",
                columns: table => new
                {
                    message_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    sender_id = table.Column<int>(type: "int", nullable: false),
                    receiver_id = table.Column<int>(type: "int", nullable: false),
                    message_text = table.Column<string>(type: "text", nullable: false),
                    date_sent = table.Column<DateTime>(type: "datetime", nullable: true, defaultValueSql: "(getdate())"),
                    is_read = table.Column<bool>(type: "bit", nullable: true, defaultValue: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Messages__0BBF6EE695058BE7", x => x.message_id);
                    table.ForeignKey(
                        name: "FK__Messages__receiv__6EF57B66",
                        column: x => x.receiver_id,
                        principalTable: "Users",
                        principalColumn: "user_id");
                    table.ForeignKey(
                        name: "FK__Messages__sender__6E01572D",
                        column: x => x.sender_id,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "Properties",
                columns: table => new
                {
                    property_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    owner_id = table.Column<int>(type: "int", nullable: false),
                    address = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: false),
                    description = table.Column<string>(type: "text", nullable: true),
                    price = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    facilities = table.Column<string>(type: "varchar(max)", unicode: false, nullable: true),
                    status = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: true),
                    date_added = table.Column<DateTime>(type: "datetime", nullable: true, defaultValueSql: "(getdate())"),
                    name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    location_id = table.Column<int>(type: "int", nullable: true),
                    PropertyTypeId = table.Column<int>(type: "int", nullable: true),
                    RentingTypeId = table.Column<int>(type: "int", nullable: true),
                    Bedrooms = table.Column<int>(type: "int", nullable: true),
                    Bathrooms = table.Column<int>(type: "int", nullable: true),
                    Area = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    YearBuilt = table.Column<int>(type: "int", nullable: true),
                    LastInspectionDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    NextInspectionDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    PropertyStatusStatusId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Properti__735BA4633A94E7C3", x => x.property_id);
                    table.ForeignKey(
                        name: "FK_Properties_PropertyStatuses_PropertyStatusStatusId",
                        column: x => x.PropertyStatusStatusId,
                        principalTable: "PropertyStatuses",
                        principalColumn: "StatusId");
                    table.ForeignKey(
                        name: "FK_Properties_PropertyTypes_PropertyTypeId",
                        column: x => x.PropertyTypeId,
                        principalTable: "PropertyTypes",
                        principalColumn: "TypeId");
                    table.ForeignKey(
                        name: "FK_Properties_RentingTypes_RentingTypeId",
                        column: x => x.RentingTypeId,
                        principalTable: "RentingTypes",
                        principalColumn: "RentingTypeId");
                    table.ForeignKey(
                        name: "FK__Propertie__Locat__625A9A57",
                        column: x => x.location_id,
                        principalTable: "Location",
                        principalColumn: "location_id");
                    table.ForeignKey(
                        name: "FK__Propertie__owner__4AB81AF0",
                        column: x => x.owner_id,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "TenantPreferences",
                columns: table => new
                {
                    TenantPreferenceId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    SearchStartDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    SearchEndDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    MinPrice = table.Column<decimal>(type: "decimal(10,2)", nullable: true),
                    MaxPrice = table.Column<decimal>(type: "decimal(10,2)", nullable: true),
                    City = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValueSql: "((1))")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TenantPreferences", x => x.TenantPreferenceId);
                    table.ForeignKey(
                        name: "FK_TenantPreferences_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Bookings",
                columns: table => new
                {
                    booking_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    property_id = table.Column<int>(type: "int", nullable: true),
                    user_id = table.Column<int>(type: "int", nullable: true),
                    start_date = table.Column<DateOnly>(type: "date", nullable: false),
                    end_date = table.Column<DateOnly>(type: "date", nullable: false),
                    total_price = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    booking_date = table.Column<DateOnly>(type: "date", nullable: true, defaultValueSql: "(getdate())"),
                    status = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Bookings__5DE3A5B1D7B9142C", x => x.booking_id);
                    table.ForeignKey(
                        name: "FK__Bookings__proper__5812160E",
                        column: x => x.property_id,
                        principalTable: "Properties",
                        principalColumn: "property_id");
                    table.ForeignKey(
                        name: "FK__Bookings__user_i__59063A47",
                        column: x => x.user_id,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "MaintenanceIssues",
                columns: table => new
                {
                    MaintenanceIssueId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PropertyId = table.Column<int>(type: "int", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PriorityId = table.Column<int>(type: "int", nullable: false),
                    StatusId = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "(getdate())"),
                    ResolvedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Cost = table.Column<decimal>(type: "decimal(10,2)", nullable: true),
                    AssignedToUserId = table.Column<int>(type: "int", nullable: true),
                    ReportedByUserId = table.Column<int>(type: "int", nullable: false),
                    ResolutionNotes = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Category = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    RequiresInspection = table.Column<bool>(type: "bit", nullable: false),
                    IsTenantComplaint = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MaintenanceIssues", x => x.MaintenanceIssueId);
                    table.ForeignKey(
                        name: "FK_MaintenanceIssues_IssuePriorities_PriorityId",
                        column: x => x.PriorityId,
                        principalTable: "IssuePriorities",
                        principalColumn: "PriorityId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MaintenanceIssues_IssueStatuses_StatusId",
                        column: x => x.StatusId,
                        principalTable: "IssueStatuses",
                        principalColumn: "StatusId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MaintenanceIssues_Properties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "property_id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MaintenanceIssues_Users_AssignedToUserId",
                        column: x => x.AssignedToUserId,
                        principalTable: "Users",
                        principalColumn: "user_id");
                    table.ForeignKey(
                        name: "FK_MaintenanceIssues_Users_ReportedByUserId",
                        column: x => x.ReportedByUserId,
                        principalTable: "Users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PropertyAmenities",
                columns: table => new
                {
                    property_id = table.Column<int>(type: "int", nullable: false),
                    amenity_id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Property__BDCB20312E16270C", x => new { x.property_id, x.amenity_id });
                    table.ForeignKey(
                        name: "FK__PropertyA__ameni__5165187F",
                        column: x => x.amenity_id,
                        principalTable: "Amenities",
                        principalColumn: "amenity_id");
                    table.ForeignKey(
                        name: "FK__PropertyA__prope__5070F446",
                        column: x => x.property_id,
                        principalTable: "Properties",
                        principalColumn: "property_id");
                });

            migrationBuilder.CreateTable(
                name: "Tenants",
                columns: table => new
                {
                    tenant_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    name = table.Column<string>(type: "varchar(100)", unicode: false, maxLength: 100, nullable: false),
                    contact_info = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: true),
                    date_of_birth = table.Column<DateOnly>(type: "date", nullable: true),
                    property_id = table.Column<int>(type: "int", nullable: true),
                    lease_start_date = table.Column<DateOnly>(type: "date", nullable: true),
                    tenant_status = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Tenants__D6F29F3EFB09F8FF", x => x.tenant_id);
                    table.ForeignKey(
                        name: "FK__Tenants__propert__5441852A",
                        column: x => x.property_id,
                        principalTable: "Properties",
                        principalColumn: "property_id");
                });

            migrationBuilder.CreateTable(
                name: "UserSavedProperties",
                columns: table => new
                {
                    UserId = table.Column<int>(type: "int", nullable: false),
                    PropertyId = table.Column<int>(type: "int", nullable: false),
                    DateSaved = table.Column<DateTime>(type: "datetime", nullable: false, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__UserSave__5084563F82C7AD6A", x => new { x.UserId, x.PropertyId });
                    table.ForeignKey(
                        name: "FK__UserSaved__Prope__51300E55",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "property_id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK__UserSaved__UserI__503BEA1C",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TenantPreferenceAmenities",
                columns: table => new
                {
                    TenantPreferenceId = table.Column<int>(type: "int", nullable: false),
                    AmenityId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TenantPreferenceAmenities", x => new { x.TenantPreferenceId, x.AmenityId });
                    table.ForeignKey(
                        name: "FK_TenantPreferenceAmenities_Amenities_AmenityId",
                        column: x => x.AmenityId,
                        principalTable: "Amenities",
                        principalColumn: "amenity_id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TenantPreferenceAmenities_TenantPreferences_TenantPreferenceId",
                        column: x => x.TenantPreferenceId,
                        principalTable: "TenantPreferences",
                        principalColumn: "TenantPreferenceId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Payments",
                columns: table => new
                {
                    payment_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    tenant_id = table.Column<int>(type: "int", nullable: true),
                    property_id = table.Column<int>(type: "int", nullable: true),
                    amount = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    date_paid = table.Column<DateOnly>(type: "date", nullable: true, defaultValueSql: "(getdate())"),
                    payment_method = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: true),
                    payment_status = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: true),
                    payment_reference = table.Column<string>(type: "varchar(100)", unicode: false, maxLength: 100, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Payments__ED1FC9EA3D8D2E81", x => x.payment_id);
                    table.ForeignKey(
                        name: "FK__Payments__proper__656C112C",
                        column: x => x.property_id,
                        principalTable: "Properties",
                        principalColumn: "property_id");
                    table.ForeignKey(
                        name: "FK__Payments__tenant__6477ECF3",
                        column: x => x.tenant_id,
                        principalTable: "Tenants",
                        principalColumn: "tenant_id");
                });

            migrationBuilder.CreateTable(
                name: "Reviews",
                columns: table => new
                {
                    review_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    property_id = table.Column<int>(type: "int", nullable: true),
                    description = table.Column<string>(type: "text", nullable: true),
                    date_reported = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())"),
                    StarRating = table.Column<decimal>(type: "decimal(2,1)", nullable: true),
                    BookingId = table.Column<int>(type: "int", nullable: true),
                    TenantId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Complain__A771F61C85B78CAA", x => x.review_id);
                    table.ForeignKey(
                        name: "FK_Reviews_Bookings_BookingId",
                        column: x => x.BookingId,
                        principalTable: "Bookings",
                        principalColumn: "booking_id");
                    table.ForeignKey(
                        name: "FK_Reviews_Tenants_TenantId",
                        column: x => x.TenantId,
                        principalTable: "Tenants",
                        principalColumn: "tenant_id");
                    table.ForeignKey(
                        name: "FK__Complaint__prope__5EBF139D",
                        column: x => x.property_id,
                        principalTable: "Properties",
                        principalColumn: "property_id");
                });

            migrationBuilder.CreateTable(
                name: "Images",
                columns: table => new
                {
                    ImageId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ReviewId = table.Column<int>(type: "int", nullable: true),
                    PropertyId = table.Column<int>(type: "int", nullable: true),
                    MaintenanceIssueId = table.Column<int>(type: "int", nullable: true),
                    ImageData = table.Column<byte[]>(type: "varbinary(max)", nullable: false),
                    DateUploaded = table.Column<DateTime>(type: "datetime", nullable: true, defaultValueSql: "(getdate())"),
                    file_name = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Images__7516F70C62BBC63F", x => x.ImageId);
                    table.ForeignKey(
                        name: "FK__Images__Maintenance__MaintenanceIssueId",
                        column: x => x.MaintenanceIssueId,
                        principalTable: "MaintenanceIssues",
                        principalColumn: "MaintenanceIssueId");
                    table.ForeignKey(
                        name: "FK__Images__Property__02FC7413",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "property_id");
                    table.ForeignKey(
                        name: "FK__Images__ReviewId__02084FDA",
                        column: x => x.ReviewId,
                        principalTable: "Reviews",
                        principalColumn: "review_id");
                });

            migrationBuilder.CreateIndex(
                name: "UQ__Amenitie__E1B33D18C14BC270",
                table: "Amenities",
                column: "amenity_name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_property_id",
                table: "Bookings",
                column: "property_id");

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_user_id",
                table: "Bookings",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_Images_MaintenanceIssueId",
                table: "Images",
                column: "MaintenanceIssueId");

            migrationBuilder.CreateIndex(
                name: "IX_Images_PropertyId",
                table: "Images",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_Images_ReviewId",
                table: "Images",
                column: "ReviewId");

            migrationBuilder.CreateIndex(
                name: "IX_MaintenanceIssues_AssignedToUserId",
                table: "MaintenanceIssues",
                column: "AssignedToUserId");

            migrationBuilder.CreateIndex(
                name: "IX_MaintenanceIssues_PriorityId",
                table: "MaintenanceIssues",
                column: "PriorityId");

            migrationBuilder.CreateIndex(
                name: "IX_MaintenanceIssues_PropertyId",
                table: "MaintenanceIssues",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_MaintenanceIssues_ReportedByUserId",
                table: "MaintenanceIssues",
                column: "ReportedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_MaintenanceIssues_StatusId",
                table: "MaintenanceIssues",
                column: "StatusId");

            migrationBuilder.CreateIndex(
                name: "IX_Messages_receiver_id",
                table: "Messages",
                column: "receiver_id");

            migrationBuilder.CreateIndex(
                name: "IX_Messages_sender_id",
                table: "Messages",
                column: "sender_id");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_property_id",
                table: "Payments",
                column: "property_id");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_tenant_id",
                table: "Payments",
                column: "tenant_id");

            migrationBuilder.CreateIndex(
                name: "IX_Properties_location_id",
                table: "Properties",
                column: "location_id");

            migrationBuilder.CreateIndex(
                name: "IX_Properties_owner_id",
                table: "Properties",
                column: "owner_id");

            migrationBuilder.CreateIndex(
                name: "IX_Properties_PropertyStatusStatusId",
                table: "Properties",
                column: "PropertyStatusStatusId");

            migrationBuilder.CreateIndex(
                name: "IX_Properties_PropertyTypeId",
                table: "Properties",
                column: "PropertyTypeId");

            migrationBuilder.CreateIndex(
                name: "IX_Properties_RentingTypeId",
                table: "Properties",
                column: "RentingTypeId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyAmenities_amenity_id",
                table: "PropertyAmenities",
                column: "amenity_id");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_BookingId",
                table: "Reviews",
                column: "BookingId");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_property_id",
                table: "Reviews",
                column: "property_id");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_TenantId",
                table: "Reviews",
                column: "TenantId");

            migrationBuilder.CreateIndex(
                name: "IX_TenantPreferenceAmenities_AmenityId",
                table: "TenantPreferenceAmenities",
                column: "AmenityId");

            migrationBuilder.CreateIndex(
                name: "IX_TenantPreferences_UserId",
                table: "TenantPreferences",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Tenants_property_id",
                table: "Tenants",
                column: "property_id");

            migrationBuilder.CreateIndex(
                name: "IX_Users_location_id",
                table: "Users",
                column: "location_id");

            migrationBuilder.CreateIndex(
                name: "IX_Users_UserTypeId",
                table: "Users",
                column: "UserTypeId");

            migrationBuilder.CreateIndex(
                name: "UQ__Users__AB6E61648C818EE9",
                table: "Users",
                column: "email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ__Users__F3DBC5724649C4DE",
                table: "Users",
                column: "username",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserSavedProperties_PropertyId",
                table: "UserSavedProperties",
                column: "PropertyId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Images");

            migrationBuilder.DropTable(
                name: "Messages");

            migrationBuilder.DropTable(
                name: "Payments");

            migrationBuilder.DropTable(
                name: "PropertyAmenities");

            migrationBuilder.DropTable(
                name: "TenantPreferenceAmenities");

            migrationBuilder.DropTable(
                name: "UserSavedProperties");

            migrationBuilder.DropTable(
                name: "MaintenanceIssues");

            migrationBuilder.DropTable(
                name: "Reviews");

            migrationBuilder.DropTable(
                name: "Amenities");

            migrationBuilder.DropTable(
                name: "TenantPreferences");

            migrationBuilder.DropTable(
                name: "IssuePriorities");

            migrationBuilder.DropTable(
                name: "IssueStatuses");

            migrationBuilder.DropTable(
                name: "Bookings");

            migrationBuilder.DropTable(
                name: "Tenants");

            migrationBuilder.DropTable(
                name: "Properties");

            migrationBuilder.DropTable(
                name: "PropertyStatuses");

            migrationBuilder.DropTable(
                name: "PropertyTypes");

            migrationBuilder.DropTable(
                name: "RentingTypes");

            migrationBuilder.DropTable(
                name: "Users");

            migrationBuilder.DropTable(
                name: "Location");

            migrationBuilder.DropTable(
                name: "UserTypes");
        }
    }
}
