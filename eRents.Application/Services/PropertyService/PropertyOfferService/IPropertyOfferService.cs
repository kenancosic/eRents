using eRents.Shared.DTO.Response;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.Application.Services.PropertyService.PropertyOfferService
{
    /// <summary>
    /// Service for managing property offers between landlords and tenants
    /// Extracted from TenantService to maintain proper SoC
    /// Organized under PropertyService as it's property-domain specific
    /// </summary>
    public interface IPropertyOfferService
    {
        /// <summary>
        /// Create a property offer from landlord to tenant
        /// </summary>
        Task<bool> CreateOfferAsync(int tenantId, int propertyId, int landlordId);

        /// <summary>
        /// Get all property offers for a specific tenant
        /// </summary>
        Task<List<PropertyOfferResponse>> GetOffersForTenantAsync(int tenantId);

        /// <summary>
        /// Get all property offers made by a specific landlord
        /// </summary>
        Task<List<PropertyOfferResponse>> GetOffersByLandlordAsync(int landlordId);

        /// <summary>
        /// Accept a property offer (tenant action)
        /// </summary>
        Task<bool> AcceptOfferAsync(int offerId, int tenantId);

        /// <summary>
        /// Reject a property offer (tenant action)
        /// </summary>
        Task<bool> RejectOfferAsync(int offerId, int tenantId);

        /// <summary>
        /// Withdraw a property offer (landlord action)
        /// </summary>
        Task<bool> WithdrawOfferAsync(int offerId, int landlordId);

        /// <summary>
        /// Check if there's an active offer between tenant and property
        /// </summary>
        Task<bool> HasActiveOfferAsync(int tenantId, int propertyId);
    }
} 