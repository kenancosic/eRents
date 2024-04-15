using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Services.Migrations
{
    /// <inheritdoc />
    public partial class newMigration : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Amenities",
                columns: table => new
                {
                    amenity_id = table.Column<int>(type: "int", nullable: false),
                    amenity_name = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Amenitie__E908452D40650F6A", x => x.amenity_id);
                });

            migrationBuilder.CreateTable(
                name: "Regions",
                columns: table => new
                {
                    region_id = table.Column<int>(type: "int", nullable: false),
                    region_name = table.Column<string>(type: "varchar(100)", unicode: false, maxLength: 100, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Regions__01146BAE487C7A1E", x => x.region_id);
                });

            migrationBuilder.CreateTable(
                name: "Roles",
                columns: table => new
                {
                    RoleId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Roles", x => x.RoleId);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    user_id = table.Column<int>(type: "int", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Surname = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    email = table.Column<string>(type: "varchar(100)", unicode: false, maxLength: 100, nullable: false),
                    phone_number = table.Column<string>(type: "varchar(20)", unicode: false, maxLength: 20, nullable: true),
                    Status = table.Column<bool>(type: "bit", nullable: true),
                    username = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: false),
                    PasswordHash = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PasswordSalt = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    registration_date = table.Column<DateTime>(type: "date", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Users__B9BE370F4566DF4A", x => x.user_id);
                });

            migrationBuilder.CreateTable(
                name: "Cantons",
                columns: table => new
                {
                    canton_id = table.Column<int>(type: "int", nullable: false),
                    canton_name = table.Column<string>(type: "varchar(100)", unicode: false, maxLength: 100, nullable: false),
                    region_id = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Cantons__7FFFB2CB9EC7B527", x => x.canton_id);
                    table.ForeignKey(
                        name: "FK__Cantons__region___30F848ED",
                        column: x => x.region_id,
                        principalTable: "Regions",
                        principalColumn: "region_id");
                });

            migrationBuilder.CreateTable(
                name: "Conversations",
                columns: table => new
                {
                    conversation_id = table.Column<int>(type: "int", nullable: false),
                    user1_id = table.Column<int>(type: "int", nullable: true),
                    user2_id = table.Column<int>(type: "int", nullable: true),
                    start_date = table.Column<DateTime>(type: "date", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Conversa__311E7E9A579CBF7C", x => x.conversation_id);
                    table.ForeignKey(
                        name: "FK__Conversat__user1__5629CD9C",
                        column: x => x.user1_id,
                        principalTable: "Users",
                        principalColumn: "user_id");
                    table.ForeignKey(
                        name: "FK__Conversat__user2__571DF1D5",
                        column: x => x.user2_id,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "Notifications",
                columns: table => new
                {
                    notification_id = table.Column<int>(type: "int", nullable: false),
                    user_id = table.Column<int>(type: "int", nullable: true),
                    notification_text = table.Column<string>(type: "varchar(500)", unicode: false, maxLength: 500, nullable: false),
                    notification_date = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Notifica__E059842F3BDE2922", x => x.notification_id);
                    table.ForeignKey(
                        name: "FK__Notificat__user___6EF57B66",
                        column: x => x.user_id,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "UserRoles",
                columns: table => new
                {
                    UserRoleId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    RoleId = table.Column<int>(type: "int", nullable: false),
                    UpdateTime = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserRoles", x => x.UserRoleId);
                    table.ForeignKey(
                        name: "FK_UserRoles_Roles_RoleId",
                        column: x => x.RoleId,
                        principalTable: "Roles",
                        principalColumn: "RoleId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserRoles_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Cities",
                columns: table => new
                {
                    city_id = table.Column<int>(type: "int", nullable: false),
                    city_name = table.Column<string>(type: "varchar(100)", unicode: false, maxLength: 100, nullable: false),
                    canton_id = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Cities__031491A86FAC9818", x => x.city_id);
                    table.ForeignKey(
                        name: "FK__Cities__canton_i__33D4B598",
                        column: x => x.canton_id,
                        principalTable: "Cantons",
                        principalColumn: "canton_id");
                });

            migrationBuilder.CreateTable(
                name: "Messages",
                columns: table => new
                {
                    message_id = table.Column<int>(type: "int", nullable: false),
                    conversation_id = table.Column<int>(type: "int", nullable: true),
                    sender_id = table.Column<int>(type: "int", nullable: true),
                    message_text = table.Column<string>(type: "varchar(500)", unicode: false, maxLength: 500, nullable: false),
                    send_date = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Messages__0BBF6EE6773BBECC", x => x.message_id);
                    table.ForeignKey(
                        name: "FK__Messages__conver__59FA5E80",
                        column: x => x.conversation_id,
                        principalTable: "Conversations",
                        principalColumn: "conversation_id");
                    table.ForeignKey(
                        name: "FK__Messages__sender__5AEE82B9",
                        column: x => x.sender_id,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "Properties",
                columns: table => new
                {
                    property_id = table.Column<int>(type: "int", nullable: false),
                    property_type = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: false),
                    address = table.Column<string>(type: "varchar(200)", unicode: false, maxLength: 200, nullable: false),
                    city_id = table.Column<int>(type: "int", nullable: true),
                    zip_code = table.Column<string>(type: "varchar(20)", unicode: false, maxLength: 20, nullable: false),
                    description = table.Column<string>(type: "varchar(500)", unicode: false, maxLength: 500, nullable: true),
                    price = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    owner_id = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Properti__735BA46376FC2C6A", x => x.property_id);
                    table.ForeignKey(
                        name: "FK__Propertie__city___37A5467C",
                        column: x => x.city_id,
                        principalTable: "Cities",
                        principalColumn: "city_id");
                    table.ForeignKey(
                        name: "FK__Propertie__owner__36B12243",
                        column: x => x.owner_id,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "Bookings",
                columns: table => new
                {
                    booking_id = table.Column<int>(type: "int", nullable: false),
                    property_id = table.Column<int>(type: "int", nullable: true),
                    user_id = table.Column<int>(type: "int", nullable: true),
                    start_date = table.Column<DateTime>(type: "date", nullable: false),
                    end_date = table.Column<DateTime>(type: "date", nullable: false),
                    total_price = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    booking_date = table.Column<DateTime>(type: "date", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Bookings__5DE3A5B1F0CCDD3A", x => x.booking_id);
                    table.ForeignKey(
                        name: "FK__Bookings__proper__403A8C7D",
                        column: x => x.property_id,
                        principalTable: "Properties",
                        principalColumn: "property_id");
                    table.ForeignKey(
                        name: "FK__Bookings__user_i__412EB0B6",
                        column: x => x.user_id,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "Favorites",
                columns: table => new
                {
                    user_id = table.Column<int>(type: "int", nullable: false),
                    property_id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Favorite__9E8B8D4998D5B8C6", x => new { x.user_id, x.property_id });
                    table.ForeignKey(
                        name: "FK__Favorites__prope__4BAC3F29",
                        column: x => x.property_id,
                        principalTable: "Properties",
                        principalColumn: "property_id");
                    table.ForeignKey(
                        name: "FK__Favorites__user___4AB81AF0",
                        column: x => x.user_id,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "Property_Amenities",
                columns: table => new
                {
                    property_id = table.Column<int>(type: "int", nullable: false),
                    amenity_id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Property__BDCB20311129E8E8", x => new { x.property_id, x.amenity_id });
                    table.ForeignKey(
                        name: "FK__Property___ameni__3D5E1FD2",
                        column: x => x.amenity_id,
                        principalTable: "Amenities",
                        principalColumn: "amenity_id");
                    table.ForeignKey(
                        name: "FK__Property___prope__3C69FB99",
                        column: x => x.property_id,
                        principalTable: "Properties",
                        principalColumn: "property_id");
                });

            migrationBuilder.CreateTable(
                name: "Property_Features",
                columns: table => new
                {
                    feature_id = table.Column<int>(type: "int", nullable: false),
                    property_id = table.Column<int>(type: "int", nullable: true),
                    feature_name = table.Column<string>(type: "varchar(100)", unicode: false, maxLength: 100, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Property__7906CBD7DC4966F9", x => x.feature_id);
                    table.ForeignKey(
                        name: "FK__Property___prope__75A278F5",
                        column: x => x.property_id,
                        principalTable: "Properties",
                        principalColumn: "property_id");
                });

            migrationBuilder.CreateTable(
                name: "Property_Ratings",
                columns: table => new
                {
                    user_id = table.Column<int>(type: "int", nullable: false),
                    property_id = table.Column<int>(type: "int", nullable: false),
                    rating = table.Column<decimal>(type: "decimal(2,1)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Property__9E8B8D49F9CDBFAE", x => new { x.user_id, x.property_id });
                    table.ForeignKey(
                        name: "FK__Property___prope__534D60F1",
                        column: x => x.property_id,
                        principalTable: "Properties",
                        principalColumn: "property_id");
                    table.ForeignKey(
                        name: "FK__Property___user___52593CB8",
                        column: x => x.user_id,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "Property_Views",
                columns: table => new
                {
                    view_id = table.Column<int>(type: "int", nullable: false),
                    property_id = table.Column<int>(type: "int", nullable: true),
                    user_id = table.Column<int>(type: "int", nullable: true),
                    view_date = table.Column<DateTime>(type: "date", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Property__B5A34EE20CAAEEAB", x => x.view_id);
                    table.ForeignKey(
                        name: "FK__Property___prope__71D1E811",
                        column: x => x.property_id,
                        principalTable: "Properties",
                        principalColumn: "property_id");
                    table.ForeignKey(
                        name: "FK__Property___user___72C60C4A",
                        column: x => x.user_id,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "Reviews",
                columns: table => new
                {
                    review_id = table.Column<int>(type: "int", nullable: false),
                    property_id = table.Column<int>(type: "int", nullable: true),
                    user_id = table.Column<int>(type: "int", nullable: true),
                    rating = table.Column<decimal>(type: "decimal(2,1)", nullable: false),
                    comment = table.Column<string>(type: "varchar(500)", unicode: false, maxLength: 500, nullable: true),
                    review_date = table.Column<DateTime>(type: "date", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Reviews__60883D909569A869", x => x.review_id);
                    table.ForeignKey(
                        name: "FK__Reviews__propert__440B1D61",
                        column: x => x.property_id,
                        principalTable: "Properties",
                        principalColumn: "property_id");
                    table.ForeignKey(
                        name: "FK__Reviews__user_id__44FF419A",
                        column: x => x.user_id,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "Contracts",
                columns: table => new
                {
                    contract_id = table.Column<int>(type: "int", nullable: false),
                    booking_id = table.Column<int>(type: "int", nullable: true),
                    user_id = table.Column<int>(type: "int", nullable: true),
                    contract_text = table.Column<string>(type: "varchar(1000)", unicode: false, maxLength: 1000, nullable: false),
                    signing_date = table.Column<DateTime>(type: "date", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Contract__F8D66423F61F466F", x => x.contract_id);
                    table.ForeignKey(
                        name: "FK__Contracts__booki__5DCAEF64",
                        column: x => x.booking_id,
                        principalTable: "Bookings",
                        principalColumn: "booking_id");
                    table.ForeignKey(
                        name: "FK__Contracts__user___5EBF139D",
                        column: x => x.user_id,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "Payments",
                columns: table => new
                {
                    payment_id = table.Column<int>(type: "int", nullable: false),
                    booking_id = table.Column<int>(type: "int", nullable: true),
                    user_id = table.Column<int>(type: "int", nullable: true),
                    amount = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    payment_date = table.Column<DateTime>(type: "date", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Payments__ED1FC9EAC730626A", x => x.payment_id);
                    table.ForeignKey(
                        name: "FK__Payments__bookin__4E88ABD4",
                        column: x => x.booking_id,
                        principalTable: "Bookings",
                        principalColumn: "booking_id");
                    table.ForeignKey(
                        name: "FK__Payments__user_i__4F7CD00D",
                        column: x => x.user_id,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "Images",
                columns: table => new
                {
                    image_id = table.Column<int>(type: "int", nullable: false),
                    ImageData = table.Column<byte[]>(type: "varbinary(max)", nullable: true),
                    PropertyId = table.Column<int>(type: "int", nullable: true),
                    ReviewId = table.Column<int>(type: "int", nullable: true),
                    UserId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Images__DC9AC955675E0E5B", x => x.image_id);
                    table.ForeignKey(
                        name: "FK_Images_Properties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "property_id");
                    table.ForeignKey(
                        name: "FK_Images_Reviews_ReviewId",
                        column: x => x.ReviewId,
                        principalTable: "Reviews",
                        principalColumn: "review_id");
                    table.ForeignKey(
                        name: "FK_Images_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_property_id",
                table: "Bookings",
                column: "property_id");

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_user_id",
                table: "Bookings",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_Cantons_region_id",
                table: "Cantons",
                column: "region_id");

            migrationBuilder.CreateIndex(
                name: "IX_Cities_canton_id",
                table: "Cities",
                column: "canton_id");

            migrationBuilder.CreateIndex(
                name: "IX_Contracts_booking_id",
                table: "Contracts",
                column: "booking_id");

            migrationBuilder.CreateIndex(
                name: "IX_Contracts_user_id",
                table: "Contracts",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_Conversations_user1_id",
                table: "Conversations",
                column: "user1_id");

            migrationBuilder.CreateIndex(
                name: "IX_Conversations_user2_id",
                table: "Conversations",
                column: "user2_id");

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_property_id",
                table: "Favorites",
                column: "property_id");

            migrationBuilder.CreateIndex(
                name: "IX_Images_PropertyId",
                table: "Images",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_Images_ReviewId",
                table: "Images",
                column: "ReviewId");

            migrationBuilder.CreateIndex(
                name: "IX_Images_UserId",
                table: "Images",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Messages_conversation_id",
                table: "Messages",
                column: "conversation_id");

            migrationBuilder.CreateIndex(
                name: "IX_Messages_sender_id",
                table: "Messages",
                column: "sender_id");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_user_id",
                table: "Notifications",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_booking_id",
                table: "Payments",
                column: "booking_id");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_user_id",
                table: "Payments",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_Properties_city_id",
                table: "Properties",
                column: "city_id");

            migrationBuilder.CreateIndex(
                name: "IX_Properties_owner_id",
                table: "Properties",
                column: "owner_id");

            migrationBuilder.CreateIndex(
                name: "IX_Property_Amenities_amenity_id",
                table: "Property_Amenities",
                column: "amenity_id");

            migrationBuilder.CreateIndex(
                name: "IX_Property_Features_property_id",
                table: "Property_Features",
                column: "property_id");

            migrationBuilder.CreateIndex(
                name: "IX_Property_Ratings_property_id",
                table: "Property_Ratings",
                column: "property_id");

            migrationBuilder.CreateIndex(
                name: "IX_Property_Views_property_id",
                table: "Property_Views",
                column: "property_id");

            migrationBuilder.CreateIndex(
                name: "IX_Property_Views_user_id",
                table: "Property_Views",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_property_id",
                table: "Reviews",
                column: "property_id");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_user_id",
                table: "Reviews",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_UserRoles_RoleId",
                table: "UserRoles",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "IX_UserRoles_UserId",
                table: "UserRoles",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Contracts");

            migrationBuilder.DropTable(
                name: "Favorites");

            migrationBuilder.DropTable(
                name: "Images");

            migrationBuilder.DropTable(
                name: "Messages");

            migrationBuilder.DropTable(
                name: "Notifications");

            migrationBuilder.DropTable(
                name: "Payments");

            migrationBuilder.DropTable(
                name: "Property_Amenities");

            migrationBuilder.DropTable(
                name: "Property_Features");

            migrationBuilder.DropTable(
                name: "Property_Ratings");

            migrationBuilder.DropTable(
                name: "Property_Views");

            migrationBuilder.DropTable(
                name: "UserRoles");

            migrationBuilder.DropTable(
                name: "Reviews");

            migrationBuilder.DropTable(
                name: "Conversations");

            migrationBuilder.DropTable(
                name: "Bookings");

            migrationBuilder.DropTable(
                name: "Amenities");

            migrationBuilder.DropTable(
                name: "Roles");

            migrationBuilder.DropTable(
                name: "Properties");

            migrationBuilder.DropTable(
                name: "Cities");

            migrationBuilder.DropTable(
                name: "Users");

            migrationBuilder.DropTable(
                name: "Cantons");

            migrationBuilder.DropTable(
                name: "Regions");
        }
    }
}
