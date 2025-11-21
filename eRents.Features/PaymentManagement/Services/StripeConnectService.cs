using eRents.Domain.Models;
using eRents.Features.PaymentManagement.Interfaces;
using eRents.Features.PaymentManagement.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Stripe;

namespace eRents.Features.PaymentManagement.Services;

/// <summary>
/// Service for Stripe Connect operations (landlord payouts)
/// </summary>
public class StripeConnectService : IStripeConnectService
{
    private readonly ERentsContext _context;
    private readonly ILogger<StripeConnectService> _logger;
    private readonly StripeOptions _stripeOptions;

    public StripeConnectService(
        ERentsContext context,
        ILogger<StripeConnectService> logger,
        IOptions<StripeOptions> stripeOptions)
    {
        _context = context;
        _logger = logger;
        _stripeOptions = stripeOptions.Value;
    }

    /// <inheritdoc/>
    public async Task<ConnectOnboardingResponse> CreateOnboardingLinkAsync(
        int userId,
        string refreshUrl,
        string returnUrl)
    {
        try
        {
            _logger.LogInformation("Creating Stripe Connect onboarding link for user {UserId}", userId);

            var user = await _context.Users.FindAsync(userId);
            if (user == null)
            {
                return new ConnectOnboardingResponse
                {
                    ErrorMessage = "User not found"
                };
            }

            string accountId;

            // Create account if doesn't exist
            if (string.IsNullOrWhiteSpace(user.StripeAccountId))
            {
                var accountService = new AccountService();
                var accountOptions = new AccountCreateOptions
                {
                    Type = "express", // Use Express for simpler onboarding
                    Country = "US", // TODO: Make dynamic based on user location
                    Email = user.Email,
                    Capabilities = new AccountCapabilitiesOptions
                    {
                        CardPayments = new AccountCapabilitiesCardPaymentsOptions
                        {
                            Requested = true
                        },
                        Transfers = new AccountCapabilitiesTransfersOptions
                        {
                            Requested = true
                        }
                    },
                    Metadata = new Dictionary<string, string>
                    {
                        { "user_id", userId.ToString() },
                        { "user_email", user.Email }
                    }
                };

                var account = await accountService.CreateAsync(accountOptions);
                accountId = account.Id;

                // Save account ID to user
                user.StripeAccountId = accountId;
                user.StripeAccountStatus = "pending";
                await _context.SaveChangesAsync();

                _logger.LogInformation("Created Stripe Connect account {AccountId} for user {UserId}",
                    accountId, userId);
            }
            else
            {
                accountId = user.StripeAccountId;
            }

            // Create account link for onboarding
            var accountLinkService = new AccountLinkService();
            var accountLinkOptions = new AccountLinkCreateOptions
            {
                Account = accountId,
                RefreshUrl = refreshUrl,
                ReturnUrl = returnUrl,
                Type = "account_onboarding"
            };

            var accountLink = await accountLinkService.CreateAsync(accountLinkOptions);

            _logger.LogInformation("Created onboarding link for account {AccountId}", accountId);

            return new ConnectOnboardingResponse
            {
                AccountId = accountId,
                OnboardingUrl = accountLink.Url,
                ExpiresAt = new DateTimeOffset(accountLink.ExpiresAt).ToUnixTimeSeconds()
            };
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe error creating onboarding link for user {UserId}: {Message}",
                userId, ex.Message);
            
            return new ConnectOnboardingResponse
            {
                ErrorMessage = $"Onboarding error: {ex.StripeError?.Message ?? ex.Message}"
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating onboarding link for user {UserId}", userId);
            
            return new ConnectOnboardingResponse
            {
                ErrorMessage = "An unexpected error occurred while creating onboarding link"
            };
        }
    }

    /// <inheritdoc/>
    public async Task<ConnectAccountStatus> GetAccountStatusAsync(int userId)
    {
        try
        {
            _logger.LogInformation("Retrieving Stripe Connect account status for user {UserId}", userId);

            var user = await _context.Users.FindAsync(userId);
            if (user == null)
            {
                return new ConnectAccountStatus
                {
                    ErrorMessage = "User not found"
                };
            }

            if (string.IsNullOrWhiteSpace(user.StripeAccountId))
            {
                return new ConnectAccountStatus
                {
                    IsActive = false,
                    StatusMessage = "No Stripe account connected"
                };
            }

            var accountService = new AccountService();
            var account = await accountService.GetAsync(user.StripeAccountId);

            var status = new ConnectAccountStatus
            {
                AccountId = account.Id,
                ChargesEnabled = account.ChargesEnabled,
                PayoutsEnabled = account.PayoutsEnabled,
                DetailsSubmitted = account.DetailsSubmitted,
                IsActive = account.ChargesEnabled && account.PayoutsEnabled,
                CurrentlyDue = account.Requirements?.CurrentlyDue?.ToList(),
                EventuallyDue = account.Requirements?.EventuallyDue?.ToList()
            };

            // Generate status message
            if (status.IsActive)
            {
                status.StatusMessage = "Account active and ready to receive payments";
                user.StripeAccountStatus = "active";
            }
            else if (status.DetailsSubmitted)
            {
                status.StatusMessage = "Account under review";
                user.StripeAccountStatus = "pending";
            }
            else
            {
                status.StatusMessage = "Onboarding incomplete - please complete setup";
                user.StripeAccountStatus = "incomplete";
            }

            await _context.SaveChangesAsync();

            return status;
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe error retrieving account status for user {UserId}: {Message}",
                userId, ex.Message);
            
            return new ConnectAccountStatus
            {
                ErrorMessage = $"Account status error: {ex.StripeError?.Message ?? ex.Message}"
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving account status for user {UserId}", userId);
            
            return new ConnectAccountStatus
            {
                ErrorMessage = "An unexpected error occurred while retrieving account status"
            };
        }
    }

    /// <inheritdoc/>
    public async Task<bool> DisconnectAccountAsync(int userId)
    {
        try
        {
            _logger.LogInformation("Disconnecting Stripe Connect account for user {UserId}", userId);

            var user = await _context.Users.FindAsync(userId);
            if (user == null || string.IsNullOrWhiteSpace(user.StripeAccountId))
            {
                return false;
            }

            // Delete the connected account
            var accountService = new AccountService();
            await accountService.DeleteAsync(user.StripeAccountId);

            // Clear user's Stripe fields
            user.StripeAccountId = null;
            user.StripeAccountStatus = null;
            await _context.SaveChangesAsync();

            _logger.LogInformation("Disconnected Stripe Connect account for user {UserId}", userId);
            return true;
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe error disconnecting account for user {UserId}: {Message}",
                userId, ex.Message);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error disconnecting account for user {UserId}", userId);
            return false;
        }
    }

    /// <inheritdoc/>
    public async Task<string?> CreateDashboardLinkAsync(int userId)
    {
        try
        {
            _logger.LogInformation("Creating Stripe dashboard link for user {UserId}", userId);

            var user = await _context.Users.FindAsync(userId);
            if (user == null || string.IsNullOrWhiteSpace(user.StripeAccountId))
            {
                return null;
            }

            var service = new AccountLinkService();
            var linkOptions = new AccountLinkCreateOptions
            {
                Account = user.StripeAccountId,
                Type = "account_onboarding" // Redirect to full dashboard
            };
            var accountLink = await service.CreateAsync(linkOptions);

            _logger.LogInformation("Created dashboard link for user {UserId}", userId);
            return accountLink.Url;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating dashboard link for user {UserId}", userId);
            return null;
        }
    }
}
