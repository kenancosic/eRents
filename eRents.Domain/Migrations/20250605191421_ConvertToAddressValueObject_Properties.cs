using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class ConvertToAddressValueObject_Properties : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Properties_AddressDetails_AddressDetailId",
                table: "Properties");

            migrationBuilder.AddColumn<string>(
                name: "Address_City",
                table: "Properties",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Address_Country",
                table: "Properties",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "Address_Latitude",
                table: "Properties",
                type: "decimal(9,6)",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "Address_Longitude",
                table: "Properties",
                type: "decimal(9,6)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Address_PostalCode",
                table: "Properties",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Address_State",
                table: "Properties",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Address_StreetLine1",
                table: "Properties",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Address_StreetLine2",
                table: "Properties",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Properties_AddressDetails_AddressDetailId",
                table: "Properties",
                column: "AddressDetailId",
                principalTable: "AddressDetails",
                principalColumn: "AddressDetailId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Properties_AddressDetails_AddressDetailId",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "Address_City",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "Address_Country",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "Address_Latitude",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "Address_Longitude",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "Address_PostalCode",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "Address_State",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "Address_StreetLine1",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "Address_StreetLine2",
                table: "Properties");

            migrationBuilder.AddForeignKey(
                name: "FK_Properties_AddressDetails_AddressDetailId",
                table: "Properties",
                column: "AddressDetailId",
                principalTable: "AddressDetails",
                principalColumn: "AddressDetailId",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
