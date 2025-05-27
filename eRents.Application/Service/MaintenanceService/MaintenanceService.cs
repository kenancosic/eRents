using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace eRents.Application.Service.MaintenanceService
{
    public class MaintenanceService : ICRUDService<MaintenanceIssueResponse, MaintenanceIssueSearchObject, MaintenanceIssueRequest, MaintenanceIssueRequest>, IMaintenanceService
    {
        private readonly IMaintenanceRepository _repository;
        private readonly IMapper _mapper;

        public MaintenanceService(IMaintenanceRepository repository, IMapper mapper)
        {
            _repository = repository;
            _mapper = mapper;
        }

        public async Task<MaintenanceIssueResponse> GetByIdAsync(int id)
        {
            var entity = await _repository.GetByIdAsync(id);
            return _mapper.Map<MaintenanceIssueResponse>(entity);
        }

        public async Task<IEnumerable<MaintenanceIssueResponse>> GetAsync(MaintenanceIssueSearchObject search = null)
        {
            var entities = await _repository.GetAllAsync(search);
            return _mapper.Map<IEnumerable<MaintenanceIssueResponse>>(entities);
        }

        public async Task<MaintenanceIssueResponse> InsertAsync(MaintenanceIssueRequest insert)
        {
            var entity = _mapper.Map<MaintenanceIssue>(insert);
            var created = await _repository.CreateAsync(entity);
            return _mapper.Map<MaintenanceIssueResponse>(created);
        }

        public async Task<MaintenanceIssueResponse> UpdateAsync(int id, MaintenanceIssueRequest update)
        {
            var entity = await _repository.GetByIdAsync(id);
            if (entity == null) return null;
            _mapper.Map(update, entity);
            var updated = await _repository.UpdateAsync(entity);
            return _mapper.Map<MaintenanceIssueResponse>(updated);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            return await _repository.DeleteAsync(id);
        }

        public async Task UpdateStatusAsync(int issueId, string status, string? resolutionNotes, decimal? cost, System.DateTime? resolvedAt)
        {
            var entity = await _repository.GetByIdAsync(issueId);
            if (entity == null) return;
            entity.Status = status;
            if (resolutionNotes != null) entity.ResolutionNotes = resolutionNotes;
            if (cost.HasValue) entity.Cost = cost.Value;
            if (resolvedAt.HasValue) entity.DateResolved = resolvedAt.Value;
            await _repository.UpdateAsync(entity);
        }
    }
} 