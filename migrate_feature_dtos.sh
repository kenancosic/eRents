#!/bin/bash

# Automated DTO Migration Script
# This script systematically migrates each feature to use proper DTO architecture

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Automated DTO Migration Script${NC}"
echo "=========================================="

# Function to create BookingManagement DTOs
migrate_booking_management() {
    echo -e "${YELLOW}📦 Migrating BookingManagement Feature...${NC}"
    
    local feature_path="eRents.Features/BookingManagement"
    local dto_path="$feature_path/DTOs"
    
    # Create BookingSearchObject
    echo "Creating BookingSearchObject..."
    cat > "$dto_path/BookingSearchObject.cs" << 'EOF'
using System.ComponentModel.DataAnnotations;

namespace eRents.Features.BookingManagement.DTOs;

/// <summary>
/// Booking search object for filtering and pagination
/// Feature-specific implementation
/// </summary>
public class BookingSearchObject
{
    #region Pagination
    
    [Range(1, int.MaxValue, ErrorMessage = "Page must be greater than 0")]
    public int? Page { get; set; } = 1;
    
    [Range(1, 100, ErrorMessage = "Page size must be between 1 and 100")]
    public int? PageSize { get; set; } = 10;
    
    public bool NoPaging { get; set; } = false;
    
    #endregion

    #region Basic Search Filters
    
    public string? Name { get; set; }
    public int? UserId { get; set; }
    public int? PropertyId { get; set; }
    public string? Status { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public DateTime? CheckInDate { get; set; }
    public DateTime? CheckOutDate { get; set; }
    
    #endregion

    #region Sorting
    
    public string? SortBy { get; set; } = "CreatedAt";
    public bool SortDescending { get; set; } = true;
    
    #endregion

    #region Pagination Helpers
    
    public int PageNumber => Page ?? 1;
    public int PageSizeValue => PageSize ?? 10;
    
    #endregion
}
EOF

    # Create BookedDateRange
    echo "Creating BookedDateRange..."
    cat > "$dto_path/BookedDateRange.cs" << 'EOF'
namespace eRents.Features.BookingManagement.DTOs;

public class BookedDateRange
{
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
}
EOF

    # Update BookingDtos.cs with all missing DTOs
    echo "Updating BookingDtos.cs..."
    cat > "$dto_path/BookingDtos.cs" << 'EOF'
using eRents.Features.Shared.DTOs;

namespace eRents.Features.BookingManagement.DTOs;

/// <summary>
/// Booking response DTO
/// </summary>
public class BookingResponse
{
    public int BookingId { get; set; }
    public int UserId { get; set; }
    public int PropertyId { get; set; }
    public DateTime CheckInDate { get; set; }
    public DateTime CheckOutDate { get; set; }
    public DateTime BookingDate { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public string? CancellationReason { get; set; }
    public DateTime? CancellationDate { get; set; }
    public bool RefundRequested { get; set; }
    public bool RefundProcessed { get; set; }
    public string? PaymentReference { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

/// <summary>
/// Booking summary response for list views
/// </summary>
public class BookingSummaryResponse
{
    public int BookingId { get; set; }
    public int UserId { get; set; }
    public int PropertyId { get; set; }
    public string PropertyName { get; set; } = string.Empty;
    public DateTime CheckInDate { get; set; }
    public DateTime CheckOutDate { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime BookingDate { get; set; }
}

/// <summary>
/// Booking insert request
/// </summary>
public class BookingInsertRequest
{
    public int PropertyId { get; set; }
    public DateTime CheckInDate { get; set; }
    public DateTime CheckOutDate { get; set; }
    public string? Notes { get; set; }
}

/// <summary>
/// Booking update request
/// </summary>
public class BookingUpdateRequest
{
    public DateTime? CheckInDate { get; set; }
    public DateTime? CheckOutDate { get; set; }
    public string? Notes { get; set; }
}

/// <summary>
/// Booking cancellation request
/// </summary>
public class BookingCancellationRequest
{
    public int BookingId { get; set; }
    public string Reason { get; set; } = string.Empty;
    public bool RequestRefund { get; set; }
    public string? AdditionalNotes { get; set; }
}
EOF

    # Update BookingService interface
    echo "Updating IBookingService interface..."
    local interface_file="$feature_path/Services/IBookingService.cs"
    
    # Check if interface exists and update it
    if [ -f "$interface_file" ]; then
        # Remove shared DTO imports and add feature-specific ones
        sed -i '/using eRents\.Shared\.DTO/d' "$interface_file"
        sed -i '/using eRents\.Shared\.SearchObjects/d' "$interface_file"
        
        # Add feature-specific imports after the first using statement
        sed -i '1a using eRents.Features.BookingManagement.DTOs;' "$interface_file"
        sed -i '1a using eRents.Features.Shared.DTOs;' "$interface_file"
    fi
    
    # Update BookingService implementation
    echo "Updating BookingService implementation..."
    local service_file="$feature_path/Services/BookingService.cs"
    
    if [ -f "$service_file" ]; then
        # Remove shared DTO imports and add feature-specific ones
        sed -i '/using eRents\.Shared\.DTO/d' "$service_file"
        sed -i '/using eRents\.Shared\.SearchObjects/d' "$service_file"
        
        # Add feature-specific imports after the first using statement
        sed -i '1a using eRents.Features.BookingManagement.DTOs;' "$service_file"
        sed -i '1a using eRents.Features.Shared.DTOs;' "$service_file"
    fi
    
    # Update BookingController
    echo "Updating BookingController..."
    local controller_file="$feature_path/Controllers/BookingController.cs"
    
    if [ -f "$controller_file" ]; then
        # Remove shared DTO imports and add feature-specific ones
        sed -i '/using eRents\.Shared\.DTO/d' "$controller_file"
        sed -i '/using eRents\.Shared\.SearchObjects/d' "$controller_file"
        
        # Add feature-specific imports after the first using statement
        sed -i '1a using eRents.Features.BookingManagement.DTOs;' "$controller_file"
        sed -i '1a using eRents.Features.Shared.DTOs;' "$controller_file"
    fi
    
    echo -e "${GREEN}✅ BookingManagement migration completed${NC}"
}

# Function to create UserManagement DTOs
migrate_user_management() {
    echo -e "${YELLOW}👥 Migrating UserManagement Feature...${NC}"
    
    local feature_path="eRents.Features/UserManagement"
    local dto_path="$feature_path/DTOs"
    
    # Create UserSearchObject
    echo "Creating UserSearchObject..."
    cat > "$dto_path/UserSearchObject.cs" << 'EOF'
using System.ComponentModel.DataAnnotations;

namespace eRents.Features.UserManagement.DTOs;

/// <summary>
/// User search object for filtering and pagination
/// Feature-specific implementation
/// </summary>
public class UserSearchObject
{
    #region Pagination
    
    [Range(1, int.MaxValue, ErrorMessage = "Page must be greater than 0")]
    public int? Page { get; set; } = 1;
    
    [Range(1, 100, ErrorMessage = "Page size must be between 1 and 100")]
    public int? PageSize { get; set; } = 10;
    
    public bool NoPaging { get; set; } = false;
    
    #endregion

    #region Basic Search Filters
    
    public string? Name { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Role { get; set; }
    public bool? IsActive { get; set; }
    public DateTime? CreatedFrom { get; set; }
    public DateTime? CreatedTo { get; set; }
    
    #endregion

    #region Sorting
    
    public string? SortBy { get; set; } = "CreatedAt";
    public bool SortDescending { get; set; } = true;
    
    #endregion

    #region Pagination Helpers
    
    public int PageNumber => Page ?? 1;
    public int PageSizeValue => PageSize ?? 10;
    
    #endregion
}
EOF

    # Update UserDtos.cs with all missing DTOs
    echo "Updating UserDtos.cs..."
    cat > "$dto_path/UserDtos.cs" << 'EOF'
using eRents.Features.Shared.DTOs;

namespace eRents.Features.UserManagement.DTOs;

/// <summary>
/// User response DTO
/// </summary>
public class UserResponse
{
    public int UserId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string Role { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

/// <summary>
/// User insert request
/// </summary>
public class UserInsertRequest
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string Role { get; set; } = "Tenant";
}

/// <summary>
/// User update request
/// </summary>
public class UserUpdateRequest
{
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public bool? IsActive { get; set; }
}

/// <summary>
/// Login request
/// </summary>
public class LoginRequest
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

/// <summary>
/// Login response
/// </summary>
public class LoginResponse
{
    public string Token { get; set; } = string.Empty;
    public UserResponse User { get; set; } = new();
}

/// <summary>
/// Change password request
/// </summary>
public class ChangePasswordRequest
{
    public string CurrentPassword { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
}

/// <summary>
/// Reset password request
/// </summary>
public class ResetPasswordRequest
{
    public string Email { get; set; } = string.Empty;
    public string? ResetToken { get; set; }
    public string? NewPassword { get; set; }
}
EOF

    echo -e "${GREEN}✅ UserManagement migration completed${NC}"
}

# Function to migrate any feature
migrate_feature() {
    local feature_name="$1"
    
    case $feature_name in
        "BookingManagement")
            migrate_booking_management
            ;;
        "UserManagement")
            migrate_user_management
            ;;
        *)
            echo -e "${YELLOW}⚠️ Migration for $feature_name not implemented yet${NC}"
            return 1
            ;;
    esac
}

# Main execution
main() {
    echo "Starting DTO migration process..."
    echo ""
    
    # Check if we have parameters
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <feature_name>"
        echo "Available features:"
        echo "  - BookingManagement"
        echo "  - UserManagement"
        echo "  - MaintenanceManagement (TODO)"
        echo "  - FinancialManagement (TODO)"
        echo "  - RentalManagement (TODO)"
        echo "  - TenantManagement (TODO)"
        echo "  - ReviewManagement (TODO)"
        echo ""
        echo "Example: $0 BookingManagement"
        exit 1
    fi
    
    local feature_name="$1"
    
    # Validate feature exists
    if [ ! -d "eRents.Features/$feature_name" ]; then
        echo -e "${RED}❌ Feature $feature_name does not exist${NC}"
        exit 1
    fi
    
    # Run migration
    if migrate_feature "$feature_name"; then
        echo ""
        echo -e "${GREEN}🎉 Migration completed successfully!${NC}"
        echo ""
        echo "Running validation..."
        ./validate_dto_architecture.sh
    else
        echo -e "${RED}❌ Migration failed for $feature_name${NC}"
        exit 1
    fi
}

# Call main function with all arguments
main "$@" 