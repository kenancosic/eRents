using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class FixUserTableColumnNames : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Users_AddressDetails_AddressDetailId",
                table: "Users");

            migrationBuilder.DropForeignKey(
                name: "FK_Users_UserTypes_UserTypeId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "created_date",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "profile_picture",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "updated_date",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "user_type",
                table: "Users");

            migrationBuilder.RenameColumn(
                name: "UserTypeId",
                table: "Users",
                newName: "user_type_id");

            migrationBuilder.RenameColumn(
                name: "IsPublic",
                table: "Users",
                newName: "is_public");

            migrationBuilder.RenameColumn(
                name: "AddressDetailId",
                table: "Users",
                newName: "address_detail_id");

            migrationBuilder.RenameColumn(
                name: "name",
                table: "Users",
                newName: "first_name");

            migrationBuilder.RenameIndex(
                name: "IX_Users_UserTypeId",
                table: "Users",
                newName: "IX_Users_user_type_id");

            migrationBuilder.RenameIndex(
                name: "IX_Users_AddressDetailId",
                table: "Users",
                newName: "IX_Users_address_detail_id");

            migrationBuilder.AddColumn<DateTime>(
                name: "created_at",
                table: "Users",
                type: "datetime",
                nullable: false,
                defaultValueSql: "(getdate())");

            migrationBuilder.AddColumn<bool>(
                name: "is_paypal_linked",
                table: "Users",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "paypal_user_identifier",
                table: "Users",
                type: "nvarchar(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "profile_image_id",
                table: "Users",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "updated_at",
                table: "Users",
                type: "datetime",
                nullable: false,
                defaultValueSql: "(getdate())");

            migrationBuilder.CreateIndex(
                name: "IX_Users_profile_image_id",
                table: "Users",
                column: "profile_image_id");

            migrationBuilder.AddForeignKey(
                name: "FK_Users_AddressDetails_address_detail_id",
                table: "Users",
                column: "address_detail_id",
                principalTable: "AddressDetails",
                principalColumn: "AddressDetailId",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Users_Images_profile_image_id",
                table: "Users",
                column: "profile_image_id",
                principalTable: "Images",
                principalColumn: "ImageId",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Users_UserTypes_user_type_id",
                table: "Users",
                column: "user_type_id",
                principalTable: "UserTypes",
                principalColumn: "UserTypeId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Users_AddressDetails_address_detail_id",
                table: "Users");

            migrationBuilder.DropForeignKey(
                name: "FK_Users_Images_profile_image_id",
                table: "Users");

            migrationBuilder.DropForeignKey(
                name: "FK_Users_UserTypes_user_type_id",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Users_profile_image_id",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "created_at",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "is_paypal_linked",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "paypal_user_identifier",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "profile_image_id",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "updated_at",
                table: "Users");

            migrationBuilder.RenameColumn(
                name: "user_type_id",
                table: "Users",
                newName: "UserTypeId");

            migrationBuilder.RenameColumn(
                name: "is_public",
                table: "Users",
                newName: "IsPublic");

            migrationBuilder.RenameColumn(
                name: "address_detail_id",
                table: "Users",
                newName: "AddressDetailId");

            migrationBuilder.RenameColumn(
                name: "first_name",
                table: "Users",
                newName: "name");

            migrationBuilder.RenameIndex(
                name: "IX_Users_user_type_id",
                table: "Users",
                newName: "IX_Users_UserTypeId");

            migrationBuilder.RenameIndex(
                name: "IX_Users_address_detail_id",
                table: "Users",
                newName: "IX_Users_AddressDetailId");

            migrationBuilder.AddColumn<DateTime>(
                name: "created_date",
                table: "Users",
                type: "datetime",
                nullable: true,
                defaultValueSql: "(getdate())");

            migrationBuilder.AddColumn<byte[]>(
                name: "profile_picture",
                table: "Users",
                type: "varbinary(max)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "updated_date",
                table: "Users",
                type: "datetime",
                nullable: true,
                defaultValueSql: "(getdate())");

            migrationBuilder.AddColumn<string>(
                name: "user_type",
                table: "Users",
                type: "varchar(20)",
                unicode: false,
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Users_AddressDetails_AddressDetailId",
                table: "Users",
                column: "AddressDetailId",
                principalTable: "AddressDetails",
                principalColumn: "AddressDetailId",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Users_UserTypes_UserTypeId",
                table: "Users",
                column: "UserTypeId",
                principalTable: "UserTypes",
                principalColumn: "UserTypeId");
        }
    }
}
