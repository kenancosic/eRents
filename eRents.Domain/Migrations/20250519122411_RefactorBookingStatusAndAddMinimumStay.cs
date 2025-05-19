using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class RefactorBookingStatusAndAddMinimumStay : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK__Bookings__proper__5812160E",
                table: "Bookings");

            migrationBuilder.DropForeignKey(
                name: "FK__Bookings__user_i__59063A47",
                table: "Bookings");

            migrationBuilder.DropForeignKey(
                name: "FK_Reviews_Bookings_BookingId",
                table: "Reviews");

            migrationBuilder.DropPrimaryKey(
                name: "PK__Bookings__5DE3A5B1D7B9142C",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "status",
                table: "Bookings");

            migrationBuilder.RenameTable(
                name: "Bookings",
                newName: "Booking");

            migrationBuilder.RenameIndex(
                name: "IX_Bookings_user_id",
                table: "Booking",
                newName: "IX_Booking_user_id");

            migrationBuilder.RenameIndex(
                name: "IX_Bookings_property_id",
                table: "Booking",
                newName: "IX_Booking_property_id");

            migrationBuilder.AlterColumn<DateOnly>(
                name: "end_date",
                table: "Booking",
                type: "date",
                nullable: true,
                oldClrType: typeof(DateOnly),
                oldType: "date");

            migrationBuilder.AlterColumn<DateOnly>(
                name: "booking_date",
                table: "Booking",
                type: "date",
                nullable: true,
                oldClrType: typeof(DateOnly),
                oldType: "date",
                oldNullable: true,
                oldDefaultValueSql: "(getdate())");

            migrationBuilder.AddColumn<DateOnly>(
                name: "MinimumStayEndDate",
                table: "Booking",
                type: "date",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "booking_status_id",
                table: "Booking",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddPrimaryKey(
                name: "PK_Booking",
                table: "Booking",
                column: "booking_id");

            migrationBuilder.CreateTable(
                name: "BookingStatus",
                columns: table => new
                {
                    booking_status_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    status_name = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BookingStatus", x => x.booking_status_id);
                });

            migrationBuilder.InsertData(
                table: "BookingStatus",
                columns: new[] { "booking_status_id", "status_name" },
                values: new object[,]
                {
                    { 1, "Upcoming" },
                    { 2, "Completed" },
                    { 3, "Cancelled" },
                    { 4, "Active" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_Booking_booking_status_id",
                table: "Booking",
                column: "booking_status_id");

            migrationBuilder.AddForeignKey(
                name: "FK_Booking_BookingStatus",
                table: "Booking",
                column: "booking_status_id",
                principalTable: "BookingStatus",
                principalColumn: "booking_status_id");

            migrationBuilder.AddForeignKey(
                name: "FK__Booking__Propert__4F7CD00D",
                table: "Booking",
                column: "property_id",
                principalTable: "Properties",
                principalColumn: "property_id");

            migrationBuilder.AddForeignKey(
                name: "FK__Booking__UserId__5070F446",
                table: "Booking",
                column: "user_id",
                principalTable: "Users",
                principalColumn: "user_id");

            migrationBuilder.AddForeignKey(
                name: "FK_Reviews_Booking_BookingId",
                table: "Reviews",
                column: "BookingId",
                principalTable: "Booking",
                principalColumn: "booking_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Booking_BookingStatus",
                table: "Booking");

            migrationBuilder.DropForeignKey(
                name: "FK__Booking__Propert__4F7CD00D",
                table: "Booking");

            migrationBuilder.DropForeignKey(
                name: "FK__Booking__UserId__5070F446",
                table: "Booking");

            migrationBuilder.DropForeignKey(
                name: "FK_Reviews_Booking_BookingId",
                table: "Reviews");

            migrationBuilder.DropTable(
                name: "BookingStatus");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Booking",
                table: "Booking");

            migrationBuilder.DropIndex(
                name: "IX_Booking_booking_status_id",
                table: "Booking");

            migrationBuilder.DropColumn(
                name: "MinimumStayEndDate",
                table: "Booking");

            migrationBuilder.DropColumn(
                name: "booking_status_id",
                table: "Booking");

            migrationBuilder.RenameTable(
                name: "Booking",
                newName: "Bookings");

            migrationBuilder.RenameIndex(
                name: "IX_Booking_user_id",
                table: "Bookings",
                newName: "IX_Bookings_user_id");

            migrationBuilder.RenameIndex(
                name: "IX_Booking_property_id",
                table: "Bookings",
                newName: "IX_Bookings_property_id");

            migrationBuilder.AlterColumn<DateOnly>(
                name: "end_date",
                table: "Bookings",
                type: "date",
                nullable: false,
                defaultValue: new DateOnly(1, 1, 1),
                oldClrType: typeof(DateOnly),
                oldType: "date",
                oldNullable: true);

            migrationBuilder.AlterColumn<DateOnly>(
                name: "booking_date",
                table: "Bookings",
                type: "date",
                nullable: true,
                defaultValueSql: "(getdate())",
                oldClrType: typeof(DateOnly),
                oldType: "date",
                oldNullable: true);

            migrationBuilder.AddColumn<string>(
                name: "status",
                table: "Bookings",
                type: "varchar(50)",
                unicode: false,
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddPrimaryKey(
                name: "PK__Bookings__5DE3A5B1D7B9142C",
                table: "Bookings",
                column: "booking_id");

            migrationBuilder.AddForeignKey(
                name: "FK__Bookings__proper__5812160E",
                table: "Bookings",
                column: "property_id",
                principalTable: "Properties",
                principalColumn: "property_id");

            migrationBuilder.AddForeignKey(
                name: "FK__Bookings__user_i__59063A47",
                table: "Bookings",
                column: "user_id",
                principalTable: "Users",
                principalColumn: "user_id");

            migrationBuilder.AddForeignKey(
                name: "FK_Reviews_Bookings_BookingId",
                table: "Reviews",
                column: "BookingId",
                principalTable: "Bookings",
                principalColumn: "booking_id");
        }
    }
}
