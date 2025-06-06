using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class AddConcurrencyControlToProperty : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
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
                name: "IX_Users_AddressDetailId",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Properties_AddressDetailId",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "AddressDetailId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "AddressDetailId",
                table: "Properties");

            migrationBuilder.AddColumn<DateTime>(
                name: "created_at",
                table: "Properties",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "(getutcdate())");

            migrationBuilder.AddColumn<string>(
                name: "created_by",
                table: "Properties",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "modified_by",
                table: "Properties",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<byte[]>(
                name: "row_version",
                table: "Properties",
                type: "rowversion",
                rowVersion: true,
                nullable: false,
                defaultValue: new byte[0]);

            migrationBuilder.AddColumn<DateTime>(
                name: "updated_at",
                table: "Properties",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "(getutcdate())");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "created_at",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "created_by",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "modified_by",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "row_version",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "updated_at",
                table: "Properties");

            migrationBuilder.AddColumn<int>(
                name: "AddressDetailId",
                table: "Users",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "AddressDetailId",
                table: "Properties",
                type: "int",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "GeoRegions",
                columns: table => new
                {
                    GeoRegionId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    City = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Country = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    PostalCode = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    State = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true)
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
                    Latitude = table.Column<decimal>(type: "decimal(9,6)", nullable: true),
                    Longitude = table.Column<decimal>(type: "decimal(9,6)", nullable: true),
                    StreetLine1 = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    StreetLine2 = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
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
                name: "IX_Users_AddressDetailId",
                table: "Users",
                column: "AddressDetailId");

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
                principalColumn: "AddressDetailId");

            migrationBuilder.AddForeignKey(
                name: "FK_Users_AddressDetails_AddressDetailId",
                table: "Users",
                column: "AddressDetailId",
                principalTable: "AddressDetails",
                principalColumn: "AddressDetailId");
        }
    }
}
