using eRents.Features.Core.Interfaces;
using eRents.Features.Shared.DTOs;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace eRents.Features.Shared.Services
{
    public interface ILookupService<TResponse> : IReadService<object, TResponse, LookupSearch>
    {
        Task<IEnumerable<TResponse>> GetAllActiveAsync(CancellationToken cancellationToken = default);
    }
}
