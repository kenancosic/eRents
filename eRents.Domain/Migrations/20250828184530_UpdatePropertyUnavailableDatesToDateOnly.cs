using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class UpdatePropertyUnavailableDatesToDateOnly : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Bathrooms",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "Facilities",
                table: "Properties");

            migrationBuilder.RenameColumn(
                name: "Bedrooms",
                table: "Properties",
                newName: "Rooms");

            migrationBuilder.AddColumn<DateOnly>(
                name: "UnavailableFrom",
                table: "Properties",
                type: "date",
                nullable: true);

            migrationBuilder.AddColumn<DateOnly>(
                name: "UnavailableTo",
                table: "Properties",
                type: "date",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "UnavailableFrom",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "UnavailableTo",
                table: "Properties");

            migrationBuilder.RenameColumn(
                name: "Rooms",
                table: "Properties",
                newName: "Bedrooms");

            migrationBuilder.AddColumn<int>(
                name: "Bathrooms",
                table: "Properties",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Facilities",
                table: "Properties",
                type: "nvarchar(max)",
                nullable: true);
        }
    }
}
