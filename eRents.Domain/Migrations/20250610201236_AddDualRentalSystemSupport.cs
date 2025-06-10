using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class AddDualRentalSystemSupport : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DefaultCleaningFee",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "DefaultSecurityDeposit",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "DefaultServiceFee",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "daily_rate",
                table: "Properties");

            migrationBuilder.AddColumn<bool>(
                name: "requires_approval",
                table: "Properties",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "RentalRequests",
                columns: table => new
                {
                    RequestId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PropertyId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    ProposedStartDate = table.Column<DateOnly>(type: "date", nullable: false),
                    LeaseDurationMonths = table.Column<int>(type: "int", nullable: false),
                    ProposedMonthlyRent = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    Message = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    RequestDate = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "(getutcdate())"),
                    ResponseDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    LandlordResponse = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    row_version = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: false),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "(getutcdate())"),
                    updated_at = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "(getutcdate())"),
                    created_by = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    modified_by = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RentalRequests", x => x.RequestId);
                    table.ForeignKey(
                        name: "FK_RentalRequests_Properties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "property_id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_RentalRequests_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_RentalRequests_PropertyId",
                table: "RentalRequests",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_RentalRequests_UserId",
                table: "RentalRequests",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "RentalRequests");

            migrationBuilder.DropColumn(
                name: "requires_approval",
                table: "Properties");

            migrationBuilder.AddColumn<decimal>(
                name: "DefaultCleaningFee",
                table: "Properties",
                type: "decimal(18,2)",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "DefaultSecurityDeposit",
                table: "Properties",
                type: "decimal(18,2)",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "DefaultServiceFee",
                table: "Properties",
                type: "decimal(18,2)",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "daily_rate",
                table: "Properties",
                type: "decimal(10,2)",
                nullable: true);
        }
    }
}
