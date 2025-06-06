using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class AddConcurrencyControlToMultipleEntities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "CreatedAt",
                table: "MaintenanceIssues",
                newName: "created_at_maintenance");

            migrationBuilder.AddColumn<string>(
                name: "created_by",
                table: "Users",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "modified_by",
                table: "Users",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<byte[]>(
                name: "row_version",
                table: "Users",
                type: "rowversion",
                rowVersion: true,
                nullable: false,
                defaultValue: new byte[0]);

            migrationBuilder.AddColumn<DateTime>(
                name: "created_at",
                table: "TenantPreferences",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "(getutcdate())");

            migrationBuilder.AddColumn<string>(
                name: "created_by",
                table: "TenantPreferences",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "modified_by",
                table: "TenantPreferences",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<byte[]>(
                name: "row_version",
                table: "TenantPreferences",
                type: "rowversion",
                rowVersion: true,
                nullable: false,
                defaultValue: new byte[0]);

            migrationBuilder.AddColumn<DateTime>(
                name: "updated_at",
                table: "TenantPreferences",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "(getutcdate())");

            migrationBuilder.AddColumn<DateTime>(
                name: "created_at_review",
                table: "Reviews",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "(getutcdate())");

            migrationBuilder.AddColumn<string>(
                name: "created_by",
                table: "Reviews",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "modified_by",
                table: "Reviews",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<byte[]>(
                name: "row_version",
                table: "Reviews",
                type: "rowversion",
                rowVersion: true,
                nullable: false,
                defaultValue: new byte[0]);

            migrationBuilder.AddColumn<DateTime>(
                name: "updated_at_review",
                table: "Reviews",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "(getutcdate())");

            migrationBuilder.AddColumn<string>(
                name: "created_by",
                table: "MaintenanceIssues",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "modified_by",
                table: "MaintenanceIssues",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<byte[]>(
                name: "row_version",
                table: "MaintenanceIssues",
                type: "rowversion",
                rowVersion: true,
                nullable: false,
                defaultValue: new byte[0]);

            migrationBuilder.AddColumn<DateTime>(
                name: "updated_at_maintenance",
                table: "MaintenanceIssues",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "(getutcdate())");

            migrationBuilder.AddColumn<DateTime>(
                name: "created_at",
                table: "Booking",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "(getutcdate())");

            migrationBuilder.AddColumn<string>(
                name: "created_by",
                table: "Booking",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "modified_by",
                table: "Booking",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<byte[]>(
                name: "row_version",
                table: "Booking",
                type: "rowversion",
                rowVersion: true,
                nullable: false,
                defaultValue: new byte[0]);

            migrationBuilder.AddColumn<DateTime>(
                name: "updated_at",
                table: "Booking",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "(getutcdate())");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "created_by",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "modified_by",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "row_version",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "created_at",
                table: "TenantPreferences");

            migrationBuilder.DropColumn(
                name: "created_by",
                table: "TenantPreferences");

            migrationBuilder.DropColumn(
                name: "modified_by",
                table: "TenantPreferences");

            migrationBuilder.DropColumn(
                name: "row_version",
                table: "TenantPreferences");

            migrationBuilder.DropColumn(
                name: "updated_at",
                table: "TenantPreferences");

            migrationBuilder.DropColumn(
                name: "created_at_review",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "created_by",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "modified_by",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "row_version",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "updated_at_review",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "created_by",
                table: "MaintenanceIssues");

            migrationBuilder.DropColumn(
                name: "modified_by",
                table: "MaintenanceIssues");

            migrationBuilder.DropColumn(
                name: "row_version",
                table: "MaintenanceIssues");

            migrationBuilder.DropColumn(
                name: "updated_at_maintenance",
                table: "MaintenanceIssues");

            migrationBuilder.DropColumn(
                name: "created_at",
                table: "Booking");

            migrationBuilder.DropColumn(
                name: "created_by",
                table: "Booking");

            migrationBuilder.DropColumn(
                name: "modified_by",
                table: "Booking");

            migrationBuilder.DropColumn(
                name: "row_version",
                table: "Booking");

            migrationBuilder.DropColumn(
                name: "updated_at",
                table: "Booking");

            migrationBuilder.RenameColumn(
                name: "created_at_maintenance",
                table: "MaintenanceIssues",
                newName: "CreatedAt");
        }
    }
}
