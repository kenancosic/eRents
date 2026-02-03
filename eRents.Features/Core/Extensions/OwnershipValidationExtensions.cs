using System.Linq.Expressions;
using eRents.Domain.Shared.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace eRents.Features.Core.Extensions;

/// <summary>
/// Extension methods for ownership validation and desktop user role checking.
/// Centralizes the repetitive ownership validation logic used across services.
/// </summary>
public static class OwnershipValidationExtensions
{
    /// <summary>
    /// Determines if the current user is a desktop client with Owner or Landlord role.
    /// This is the primary gate for applying ownership restrictions.
    /// </summary>
    public static bool IsDesktopOwnerOrLandlord(this ICurrentUserService? currentUser)
    {
        if (currentUser?.IsDesktop != true)
            return false;
        if (string.IsNullOrWhiteSpace(currentUser.UserRole))
            return false;

        return string.Equals(currentUser.UserRole, "Owner", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(currentUser.UserRole, "Landlord", StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Gets the owner ID from current user if they are a desktop owner/landlord.
    /// Returns null if user is not desktop owner/landlord or ID cannot be parsed.
    /// </summary>
    public static int? GetDesktopOwnerId(this ICurrentUserService? currentUser)
    {
        if (!currentUser.IsDesktopOwnerOrLandlord())
            return null;

        return currentUser.GetUserIdAsInt();
    }
}
