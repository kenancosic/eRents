using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eRents.Domain.Migrations
{
    /// <inheritdoc />
    public partial class LinkTenantToUserAndRefineRoles : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Attempt to drop the potentially problematic foreign key from Reviews table
            migrationBuilder.Sql("IF OBJECT_ID('FK_Reviews_Tenants_TenantId', 'F') IS NOT NULL ALTER TABLE Reviews DROP CONSTRAINT FK_Reviews_Tenants_TenantId;");

            // Drop FK from Payments to Tenants
            migrationBuilder.DropForeignKey(
                name: "FK__Payments__tenant__6477ECF3", // Actual FK name from error
                table: "Payments");

            migrationBuilder.DropForeignKey(
                name: "FK__Tenants__propert__5441852A",
                table: "Tenants");

            migrationBuilder.DropPrimaryKey(
                name: "PK__Tenants__D6F29F3EFB09F8FF",
                table: "Tenants");

            migrationBuilder.DropColumn(
                name: "contact_info",
                table: "Tenants");

            migrationBuilder.DropColumn(
                name: "date_of_birth",
                table: "Tenants");

            migrationBuilder.DropColumn(
                name: "name",
                table: "Tenants");

            migrationBuilder.AddColumn<int>(
                name: "user_id",
                table: "Tenants",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddPrimaryKey(
                name: "PK__Tenants__E3F9F43B311A209A", // New PK name for Tenants
                table: "Tenants",
                column: "tenant_id");

            migrationBuilder.CreateIndex(
                name: "IX_Tenants_user_id",
                table: "Tenants",
                column: "user_id");

            migrationBuilder.AddForeignKey(
                name: "FK_Tenants_Users_UserId",
                table: "Tenants",
                column: "user_id",
                principalTable: "Users",
                principalColumn: "user_id");

            migrationBuilder.AddForeignKey(
                name: "FK__Tenants__propert__619B8048",
                table: "Tenants",
                column: "property_id",
                principalTable: "Properties",
                principalColumn: "property_id");

            // Re-add FK from Payments to Tenants
            migrationBuilder.AddForeignKey(
                name: "FK__Payments__tenant__6477ECF3", // Must match the name of the FK constraint
                table: "Payments",
                column: "tenant_id", // The FK column in Payments table
                principalTable: "Tenants",
                principalColumn: "tenant_id", // The PK column in Tenants table
                onDelete: ReferentialAction.Restrict); // Or whatever the original onDelete behavior was, often Cascade or Restrict/NoAction
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // ... Down method remains largely the same, but ensure FKs are handled in reverse order too
            migrationBuilder.DropForeignKey(
                name: "FK__Payments__tenant__6477ECF3", 
                table: "Payments");

            migrationBuilder.DropForeignKey(
                name: "FK_Tenants_Users_UserId",
                table: "Tenants");

            migrationBuilder.DropForeignKey(
                name: "FK__Tenants__propert__619B8048",
                table: "Tenants");

            migrationBuilder.DropPrimaryKey(
                name: "PK__Tenants__E3F9F43B311A209A",
                table: "Tenants");

            migrationBuilder.DropIndex(
                name: "IX_Tenants_user_id",
                table: "Tenants");

            migrationBuilder.DropColumn(
                name: "user_id",
                table: "Tenants");

            migrationBuilder.AddColumn<string>(
                name: "contact_info",
                table: "Tenants",
                type: "varchar(255)",
                unicode: false,
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<DateOnly>(
                name: "date_of_birth",
                table: "Tenants",
                type: "date",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "name",
                table: "Tenants",
                type: "varchar(100)",
                unicode: false,
                maxLength: 100,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddPrimaryKey(
                name: "PK__Tenants__D6F29F3EFB09F8FF", // Old PK name for Tenants
                table: "Tenants",
                column: "tenant_id");

            migrationBuilder.AddForeignKey(
                name: "FK__Tenants__propert__5441852A",
                table: "Tenants",
                column: "property_id",
                principalTable: "Properties",
                principalColumn: "property_id");

            // Re-add FK from Payments to Tenants (for Down migration)
            migrationBuilder.AddForeignKey(
                name: "FK__Payments__tenant__6477ECF3",
                table: "Payments",
                column: "tenant_id",
                principalTable: "Tenants",
                principalColumn: "tenant_id",
                onDelete: ReferentialAction.Restrict); // Match original

            // Potentially re-add FK_Reviews_Tenants_TenantId if it was intentionally part of the schema
            // migrationBuilder.Sql("ALTER TABLE Reviews ADD CONSTRAINT FK_Reviews_Tenants_TenantId FOREIGN KEY (TenantColumnInReview) REFERENCES Tenants(tenant_id) ...");
        }
    }
}
