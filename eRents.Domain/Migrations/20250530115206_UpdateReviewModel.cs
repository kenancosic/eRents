using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class UpdateReviewModel : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Reviews_Booking_BookingId",
                table: "Reviews");

            migrationBuilder.DropForeignKey(
                name: "FK__Complaint__prope__5EBF139D",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "date_reported",
                table: "Reviews");

            migrationBuilder.RenameColumn(
                name: "BookingId",
                table: "Reviews",
                newName: "booking_id");

            migrationBuilder.RenameIndex(
                name: "IX_Reviews_BookingId",
                table: "Reviews",
                newName: "IX_Reviews_booking_id");

            migrationBuilder.AlterColumn<int>(
                name: "booking_id",
                table: "Reviews",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "date_created",
                table: "Reviews",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "(getdate())");

            migrationBuilder.AddColumn<string>(
                name: "review_type",
                table: "Reviews",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "reviewee_id",
                table: "Reviews",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "reviewer_id",
                table: "Reviews",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "status",
                table: "Reviews",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true,
                defaultValue: "Approved");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_reviewee_id",
                table: "Reviews",
                column: "reviewee_id");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_reviewer_id",
                table: "Reviews",
                column: "reviewer_id");

            migrationBuilder.AddForeignKey(
                name: "FK__Review__booking_id",
                table: "Reviews",
                column: "booking_id",
                principalTable: "Booking",
                principalColumn: "booking_id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK__Review__property_id",
                table: "Reviews",
                column: "property_id",
                principalTable: "Properties",
                principalColumn: "property_id");

            migrationBuilder.AddForeignKey(
                name: "FK__Review__reviewee_id",
                table: "Reviews",
                column: "reviewee_id",
                principalTable: "Users",
                principalColumn: "user_id");

            migrationBuilder.AddForeignKey(
                name: "FK__Review__reviewer_id",
                table: "Reviews",
                column: "reviewer_id",
                principalTable: "Users",
                principalColumn: "user_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK__Review__booking_id",
                table: "Reviews");

            migrationBuilder.DropForeignKey(
                name: "FK__Review__property_id",
                table: "Reviews");

            migrationBuilder.DropForeignKey(
                name: "FK__Review__reviewee_id",
                table: "Reviews");

            migrationBuilder.DropForeignKey(
                name: "FK__Review__reviewer_id",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_Reviews_reviewee_id",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_Reviews_reviewer_id",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "date_created",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "review_type",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "reviewee_id",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "reviewer_id",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "status",
                table: "Reviews");

            migrationBuilder.RenameColumn(
                name: "booking_id",
                table: "Reviews",
                newName: "BookingId");

            migrationBuilder.RenameIndex(
                name: "IX_Reviews_booking_id",
                table: "Reviews",
                newName: "IX_Reviews_BookingId");

            migrationBuilder.AlterColumn<int>(
                name: "BookingId",
                table: "Reviews",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AddColumn<DateTime>(
                name: "date_reported",
                table: "Reviews",
                type: "datetime2",
                nullable: true,
                defaultValueSql: "(getdate())");

            migrationBuilder.AddForeignKey(
                name: "FK_Reviews_Booking_BookingId",
                table: "Reviews",
                column: "BookingId",
                principalTable: "Booking",
                principalColumn: "booking_id");

            migrationBuilder.AddForeignKey(
                name: "FK__Complaint__prope__5EBF139D",
                table: "Reviews",
                column: "property_id",
                principalTable: "Properties",
                principalColumn: "property_id");
        }
    }
}
