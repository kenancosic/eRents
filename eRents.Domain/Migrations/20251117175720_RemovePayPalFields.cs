using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class RemovePayPalFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsPaypalLinked",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PaypalAccountEmail",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PaypalAccountType",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PaypalLinkedAt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PaypalMerchantId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PaypalPayerId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PaypalUserIdentifier",
                table: "Users");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsPaypalLinked",
                table: "Users",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "PaypalAccountEmail",
                table: "Users",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "PaypalAccountType",
                table: "Users",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "PaypalLinkedAt",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PaypalMerchantId",
                table: "Users",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PaypalPayerId",
                table: "Users",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PaypalUserIdentifier",
                table: "Users",
                type: "nvarchar(max)",
                nullable: true);
        }
    }
}
