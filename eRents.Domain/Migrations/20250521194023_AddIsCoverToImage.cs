using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class AddIsCoverToImage : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LastInspectionDate",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "NextInspectionDate",
                table: "Properties");

            migrationBuilder.RenameColumn(
                name: "Bedrooms",
                table: "Properties",
                newName: "bedrooms");

            migrationBuilder.RenameColumn(
                name: "Bathrooms",
                table: "Properties",
                newName: "bathrooms");

            migrationBuilder.RenameColumn(
                name: "Area",
                table: "Properties",
                newName: "area");

            migrationBuilder.RenameColumn(
                name: "YearBuilt",
                table: "Properties",
                newName: "year_built");

            migrationBuilder.AlterColumn<bool>(
                name: "IsActive",
                table: "TenantPreferences",
                type: "bit",
                nullable: false,
                defaultValue: false,
                oldClrType: typeof(bool),
                oldType: "bit",
                oldDefaultValueSql: "((1))");

            migrationBuilder.AlterColumn<decimal>(
                name: "area",
                table: "Properties",
                type: "decimal(10,2)",
                nullable: true,
                oldClrType: typeof(decimal),
                oldType: "decimal(18,2)",
                oldNullable: true);

            migrationBuilder.AddColumn<string>(
                name: "currency",
                table: "Properties",
                type: "varchar(10)",
                unicode: false,
                maxLength: 10,
                nullable: false,
                defaultValue: "BAM");

            migrationBuilder.AddColumn<bool>(
                name: "is_cover",
                table: "Images",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "currency",
                table: "Properties");

            migrationBuilder.DropColumn(
                name: "is_cover",
                table: "Images");

            migrationBuilder.RenameColumn(
                name: "bedrooms",
                table: "Properties",
                newName: "Bedrooms");

            migrationBuilder.RenameColumn(
                name: "bathrooms",
                table: "Properties",
                newName: "Bathrooms");

            migrationBuilder.RenameColumn(
                name: "area",
                table: "Properties",
                newName: "Area");

            migrationBuilder.RenameColumn(
                name: "year_built",
                table: "Properties",
                newName: "YearBuilt");

            migrationBuilder.AlterColumn<bool>(
                name: "IsActive",
                table: "TenantPreferences",
                type: "bit",
                nullable: false,
                defaultValueSql: "((1))",
                oldClrType: typeof(bool),
                oldType: "bit",
                oldDefaultValue: false);

            migrationBuilder.AlterColumn<decimal>(
                name: "Area",
                table: "Properties",
                type: "decimal(18,2)",
                nullable: true,
                oldClrType: typeof(decimal),
                oldType: "decimal(10,2)",
                oldNullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastInspectionDate",
                table: "Properties",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "NextInspectionDate",
                table: "Properties",
                type: "datetime2",
                nullable: true);
        }
    }
}
