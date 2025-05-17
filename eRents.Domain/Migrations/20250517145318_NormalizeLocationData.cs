using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class NormalizeLocationData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK__Propertie__Locat__625A9A57",
                table: "Properties");

            migrationBuilder.DropForeignKey(
                name: "FK_User_LocationID",
                table: "Users");

            migrationBuilder.DropTable(
                name: "Location");

            migrationBuilder.DropIndex(
                name: "IX_Properties_location_id",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "address",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "location_id",
                table: "Properties");

            migrationBuilder.RenameColumn(
                name: "location_id",
                table: "Users",
                newName: "AddressDetailId");

            migrationBuilder.RenameIndex(
                name: "IX_Users_location_id",
                table: "Users",
                newName: "IX_Users_AddressDetailId");

            migrationBuilder.AddColumn<int>(
                name: "AddressDetailId",
                table: "Properties",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "GeoRegions",
                columns: table => new
                {
                    GeoRegionId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    City = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    State = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    Country = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    PostalCode = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_GeoRegions", x => x.GeoRegionId);
                });

            migrationBuilder.CreateTable(
                name: "AddressDetails",
                columns: table => new
                {
                    AddressDetailId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    GeoRegionId = table.Column<int>(type: "int", nullable: false),
                    StreetLine1 = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    StreetLine2 = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    Latitude = table.Column<decimal>(type: "decimal(9,6)", nullable: true),
                    Longitude = table.Column<decimal>(type: "decimal(9,6)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AddressDetails", x => x.AddressDetailId);
                    table.ForeignKey(
                        name: "FK_AddressDetails_GeoRegions_GeoRegionId",
                        column: x => x.GeoRegionId,
                        principalTable: "GeoRegions",
                        principalColumn: "GeoRegionId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Properties_AddressDetailId",
                table: "Properties",
                column: "AddressDetailId");

            migrationBuilder.CreateIndex(
                name: "IX_AddressDetails_GeoRegionId",
                table: "AddressDetails",
                column: "GeoRegionId");

            migrationBuilder.CreateIndex(
                name: "IX_GeoRegions_City_State_Country_PostalCode",
                table: "GeoRegions",
                columns: new[] { "City", "State", "Country", "PostalCode" },
                unique: true,
                filter: "[State] IS NOT NULL AND [PostalCode] IS NOT NULL");

            migrationBuilder.AddForeignKey(
                name: "FK_Properties_AddressDetails_AddressDetailId",
                table: "Properties",
                column: "AddressDetailId",
                principalTable: "AddressDetails",
                principalColumn: "AddressDetailId",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Users_AddressDetails_AddressDetailId",
                table: "Users",
                column: "AddressDetailId",
                principalTable: "AddressDetails",
                principalColumn: "AddressDetailId",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Properties_AddressDetails_AddressDetailId",
                table: "Properties");

            migrationBuilder.DropForeignKey(
                name: "FK_Users_AddressDetails_AddressDetailId",
                table: "Users");

            migrationBuilder.DropTable(
                name: "AddressDetails");

            migrationBuilder.DropTable(
                name: "GeoRegions");

            migrationBuilder.DropIndex(
                name: "IX_Properties_AddressDetailId",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "AddressDetailId",
                table: "Properties");

            migrationBuilder.RenameColumn(
                name: "AddressDetailId",
                table: "Users",
                newName: "location_id");

            migrationBuilder.RenameIndex(
                name: "IX_Users_AddressDetailId",
                table: "Users",
                newName: "IX_Users_location_id");

            migrationBuilder.AddColumn<string>(
                name: "address",
                table: "Properties",
                type: "varchar(255)",
                unicode: false,
                maxLength: 255,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "location_id",
                table: "Properties",
                type: "int",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Location",
                columns: table => new
                {
                    location_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    City = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Country = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    Latitude = table.Column<decimal>(type: "decimal(9,6)", nullable: true),
                    Longitude = table.Column<decimal>(type: "decimal(9,6)", nullable: true),
                    PostalCode = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    State = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Location__E7FEA47700C11F68", x => x.location_id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Properties_location_id",
                table: "Properties",
                column: "location_id");

            migrationBuilder.AddForeignKey(
                name: "FK__Propertie__Locat__625A9A57",
                table: "Properties",
                column: "location_id",
                principalTable: "Location",
                principalColumn: "location_id");

            migrationBuilder.AddForeignKey(
                name: "FK_User_LocationID",
                table: "Users",
                column: "location_id",
                principalTable: "Location",
                principalColumn: "location_id");
        }
    }
}
