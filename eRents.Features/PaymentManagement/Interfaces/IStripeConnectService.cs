using eRents.Features.PaymentManagement.Models;

namespace eRents.Features.PaymentManagement.Interfaces;

/// <summary>
/// Service interface for Stripe Connect operations (landlord payouts)
/// </summary>
public interface IStripeConnectService
{
    /// <summary>
    /// Creates an onboarding link for a landlord to connect their Stripe account
    /// </summary>
    /// <param name="userId">The user ID of the landlord</param>
    /// <param name="refreshUrl">URL to redirect if onboarding needs to be restarted</param>
    /// <param name="returnUrl">URL to redirect after onboarding completion</param>
    /// <returns>Onboarding link details</returns>
    Task<ConnectOnboardingResponse> CreateOnboardingLinkAsync(
        int userId,
        string refreshUrl,
        string returnUrl);
    
    /// <summary>
    /// Retrieves the status of a connected account
    /// </summary>
    /// <param name="userId">The user ID of the landlord</param>
    /// <returns>Account status details</returns>
    Task<ConnectAccountStatus> GetAccountStatusAsync(int userId);
    
    /// <summary>
    /// Disconnects a Stripe account from a landlord
    /// </summary>
    /// <param name="userId">The user ID of the landlord</param>
    /// <returns>True if disconnection successful</returns>
    Task<bool> DisconnectAccountAsync(int userId);
    
    /// <summary>
    /// Creates a login link for landlords to access their Stripe dashboard
    /// </summary>
    /// <param name="userId">The user ID of the landlord</param>
    /// <returns>Login link URL</returns>
    Task<string?> CreateDashboardLinkAsync(int userId);
}
