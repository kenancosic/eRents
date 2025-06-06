using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class ConvertToAddressValueObject_Users : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Users_AddressDetails_address_detail_id",
                table: "Users");

            migrationBuilder.RenameColumn(
                name: "address_detail_id",
                table: "Users",
                newName: "AddressDetailId");

            migrationBuilder.RenameIndex(
                name: "IX_Users_address_detail_id",
                table: "Users",
                newName: "IX_Users_AddressDetailId");

            migrationBuilder.AddColumn<string>(
                name: "Address_City",
                table: "Users",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Address_Country",
                table: "Users",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "Address_Latitude",
                table: "Users",
                type: "decimal(9,6)",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "Address_Longitude",
                table: "Users",
                type: "decimal(9,6)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Address_PostalCode",
                table: "Users",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Address_State",
                table: "Users",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Address_StreetLine1",
                table: "Users",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Address_StreetLine2",
                table: "Users",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Users_AddressDetails_AddressDetailId",
                table: "Users",
                column: "AddressDetailId",
                principalTable: "AddressDetails",
                principalColumn: "AddressDetailId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Users_AddressDetails_AddressDetailId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Address_City",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Address_Country",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Address_Latitude",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Address_Longitude",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Address_PostalCode",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Address_State",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Address_StreetLine1",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Address_StreetLine2",
                table: "Users");

            migrationBuilder.RenameColumn(
                name: "AddressDetailId",
                table: "Users",
                newName: "address_detail_id");

            migrationBuilder.RenameIndex(
                name: "IX_Users_AddressDetailId",
                table: "Users",
                newName: "IX_Users_address_detail_id");

            migrationBuilder.AddForeignKey(
                name: "FK_Users_AddressDetails_address_detail_id",
                table: "Users",
                column: "address_detail_id",
                principalTable: "AddressDetails",
                principalColumn: "AddressDetailId",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
