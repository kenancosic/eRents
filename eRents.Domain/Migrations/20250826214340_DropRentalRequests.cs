using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class DropRentalRequests : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "RentalRequests");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "RentalRequests",
                columns: table => new
                {
                    RequestId = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    property_id = table.Column<int>(type: "int", nullable: false),
                    user_id = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CreatedBy = table.Column<int>(type: "int", nullable: true),
                    landlord_response = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    lease_duration_months = table.Column<int>(type: "int", nullable: false),
                    message = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    ModifiedBy = table.Column<int>(type: "int", nullable: true),
                    number_of_guests = table.Column<int>(type: "int", nullable: false),
                    proposed_monthly_rent = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    proposed_start_date = table.Column<DateOnly>(type: "date", nullable: false),
                    response_date = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false, defaultValue: "Pending"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RentalRequests", x => x.RequestId);
                    table.ForeignKey(
                        name: "FK_RentalRequests_Properties_property_id",
                        column: x => x.property_id,
                        principalTable: "Properties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_RentalRequests_Users_user_id",
                        column: x => x.user_id,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_RentalRequests_property_id",
                table: "RentalRequests",
                column: "property_id");

            migrationBuilder.CreateIndex(
                name: "IX_RentalRequests_user_id",
                table: "RentalRequests",
                column: "user_id");
        }
    }
}
