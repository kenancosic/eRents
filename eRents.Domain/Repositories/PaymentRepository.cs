using eRents.Domain.Models;
using eRents.Domain.Shared;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Domain.Repositories
{
    public class PaymentRepository : ConcurrentBaseRepository<Payment>, IPaymentRepository
    {
        public PaymentRepository(ERentsContext context, ILogger<PaymentRepository> logger) : base(context, logger) { }

        public async Task<IEnumerable<Payment>> GetPaymentsByTenantIdAsync(int tenantId)
        {
            return await _context.Payments
                            .Where(p => p.TenantId == tenantId)
                            .OrderByDescending(p => p.DatePaid)
                            .ToListAsync();
        }

        public async Task<IEnumerable<Payment>> GetPaymentsByPropertyIdAsync(int propertyId)
        {
            return await _context.Payments
                            .Where(p => p.PropertyId == propertyId)
                            .OrderByDescending(p => p.DatePaid)
                            .ToListAsync();
        }

        public async Task<Payment?> GetPaymentByReferenceAsync(string paymentReference)
        {
            return await _context.Payments
                            .FirstOrDefaultAsync(p => p.PaymentReference == paymentReference);
        }

        public async Task<Payment?> GetByPaymentReferenceAsync(string paymentReference)
        {
            return await _context.Payments
                            .FirstOrDefaultAsync(p => p.PaymentReference == paymentReference);
        }

        public async Task<decimal> GetTotalPaymentsByTenantAsync(int tenantId)
        {
            return await _context.Payments
                            .Where(p => p.TenantId == tenantId)
                            .SumAsync(p => p.Amount);
        }

        public async Task<decimal> GetTotalPaymentsByPropertyAsync(int propertyId)
        {
            return await _context.Payments
                            .Where(p => p.PropertyId == propertyId)
                            .SumAsync(p => p.Amount);
        }
    }
} 