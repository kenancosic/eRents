using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class StandardizeBaseEntityInheritance : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DateSent",
                table: "Messages");

            migrationBuilder.RenameColumn(
                name: "DateUpdated",
                table: "UserPreferences",
                newName: "UpdatedAt");

            migrationBuilder.RenameColumn(
                name: "DateCreated",
                table: "UserPreferences",
                newName: "CreatedAt");

            migrationBuilder.RenameColumn(
                name: "DateCreated",
                table: "PropertyAvailabilities",
                newName: "UpdatedAt");

            migrationBuilder.RenameColumn(
                name: "DateRequested",
                table: "LeaseExtensionRequests",
                newName: "UpdatedAt");

            migrationBuilder.AddColumn<int>(
                name: "CreatedBy",
                table: "UserPreferences",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ModifiedBy",
                table: "UserPreferences",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<byte[]>(
                name: "RowVersion",
                table: "UserPreferences",
                type: "rowversion",
                rowVersion: true,
                nullable: false,
                defaultValue: new byte[0]);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "PropertyAvailabilities",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<int>(
                name: "CreatedBy",
                table: "PropertyAvailabilities",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ModifiedBy",
                table: "PropertyAvailabilities",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<byte[]>(
                name: "RowVersion",
                table: "PropertyAvailabilities",
                type: "rowversion",
                rowVersion: true,
                nullable: false,
                defaultValue: new byte[0]);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "LeaseExtensionRequests",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<int>(
                name: "CreatedBy",
                table: "LeaseExtensionRequests",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ModifiedBy",
                table: "LeaseExtensionRequests",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<byte[]>(
                name: "RowVersion",
                table: "LeaseExtensionRequests",
                type: "rowversion",
                rowVersion: true,
                nullable: false,
                defaultValue: new byte[0]);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CreatedBy",
                table: "UserPreferences");

            migrationBuilder.DropColumn(
                name: "ModifiedBy",
                table: "UserPreferences");

            migrationBuilder.DropColumn(
                name: "RowVersion",
                table: "UserPreferences");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "PropertyAvailabilities");

            migrationBuilder.DropColumn(
                name: "CreatedBy",
                table: "PropertyAvailabilities");

            migrationBuilder.DropColumn(
                name: "ModifiedBy",
                table: "PropertyAvailabilities");

            migrationBuilder.DropColumn(
                name: "RowVersion",
                table: "PropertyAvailabilities");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "LeaseExtensionRequests");

            migrationBuilder.DropColumn(
                name: "CreatedBy",
                table: "LeaseExtensionRequests");

            migrationBuilder.DropColumn(
                name: "ModifiedBy",
                table: "LeaseExtensionRequests");

            migrationBuilder.DropColumn(
                name: "RowVersion",
                table: "LeaseExtensionRequests");

            migrationBuilder.RenameColumn(
                name: "UpdatedAt",
                table: "UserPreferences",
                newName: "DateUpdated");

            migrationBuilder.RenameColumn(
                name: "CreatedAt",
                table: "UserPreferences",
                newName: "DateCreated");

            migrationBuilder.RenameColumn(
                name: "UpdatedAt",
                table: "PropertyAvailabilities",
                newName: "DateCreated");

            migrationBuilder.RenameColumn(
                name: "UpdatedAt",
                table: "LeaseExtensionRequests",
                newName: "DateRequested");

            migrationBuilder.AddColumn<DateTime>(
                name: "DateSent",
                table: "Messages",
                type: "datetime2",
                nullable: true);
        }
    }
}
