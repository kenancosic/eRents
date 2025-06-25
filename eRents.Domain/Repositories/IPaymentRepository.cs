using eRents.Domain.Models;
using eRents.Domain.Shared;

namespace eRents.Domain.Repositories
{
    public interface IPaymentRepository : IBaseRepository<Payment>
    {
        Task<IEnumerable<Payment>> GetPaymentsByTenantIdAsync(int tenantId);
        Task<IEnumerable<Payment>> GetPaymentsByPropertyIdAsync(int propertyId);
        Task<Payment?> GetByPaymentReferenceAsync(string paymentReference);
        Task<decimal> GetTotalPaymentsByTenantAsync(int tenantId);
        Task<decimal> GetTotalPaymentsByPropertyAsync(int propertyId);
    }
} 