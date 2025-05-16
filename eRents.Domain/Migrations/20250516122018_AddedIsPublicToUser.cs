using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class AddedIsPublicToUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsPublic",
                table: "Users",
                type: "bit",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsPublic",
                table: "Users");
        }
    }
}
