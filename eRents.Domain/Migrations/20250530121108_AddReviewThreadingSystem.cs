using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class AddReviewThreadingSystem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK__Review__booking_id",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "status",
                table: "Reviews");

            migrationBuilder.AlterColumn<int>(
                name: "booking_id",
                table: "Reviews",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AddColumn<int>(
                name: "parent_review_id",
                table: "Reviews",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_parent_review_id",
                table: "Reviews",
                column: "parent_review_id");

            migrationBuilder.AddForeignKey(
                name: "FK__Review__booking_id",
                table: "Reviews",
                column: "booking_id",
                principalTable: "Booking",
                principalColumn: "booking_id");

            migrationBuilder.AddForeignKey(
                name: "FK__Review__parent_review_id",
                table: "Reviews",
                column: "parent_review_id",
                principalTable: "Reviews",
                principalColumn: "review_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK__Review__booking_id",
                table: "Reviews");

            migrationBuilder.DropForeignKey(
                name: "FK__Review__parent_review_id",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_Reviews_parent_review_id",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "parent_review_id",
                table: "Reviews");

            migrationBuilder.AlterColumn<int>(
                name: "booking_id",
                table: "Reviews",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AddColumn<string>(
                name: "status",
                table: "Reviews",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true,
                defaultValue: "Approved");

            migrationBuilder.AddForeignKey(
                name: "FK__Review__booking_id",
                table: "Reviews",
                column: "booking_id",
                principalTable: "Booking",
                principalColumn: "booking_id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
