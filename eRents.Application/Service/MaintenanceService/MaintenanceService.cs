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

        // Sync methods required by IService interface
        public IEnumerable<MaintenanceIssueResponse> Get(MaintenanceIssueSearchObject search = null)
        {
            return GetAsync(search).Result;
        }

        public MaintenanceIssueResponse GetById(int id)
        {
            return GetByIdAsync(id).Result;
        }

        // Async methods
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
            await _repository.AddAsync(entity);
            return _mapper.Map<MaintenanceIssueResponse>(entity);
        }

        public async Task<MaintenanceIssueResponse> UpdateAsync(int id, MaintenanceIssueRequest update)
        {
            var entity = await _repository.GetByIdAsync(id);
            if (entity == null) return null;
            _mapper.Map(update, entity);
            await _repository.UpdateAsync(entity);
            return _mapper.Map<MaintenanceIssueResponse>(entity);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var entity = await _repository.GetByIdAsync(id);
            if (entity == null) return false;
            await _repository.DeleteAsync(entity);
            return true;
        }

        public async Task UpdateStatusAsync(int issueId, string status, string? resolutionNotes, decimal? cost, System.DateTime? resolvedAt)
        {
            var entity = await _repository.GetByIdAsync(issueId);
            if (entity == null) return;
            
            // Note: This would need proper enum/lookup handling in a real implementation
            // For now, assuming status is handled via StatusId and navigation property
            // entity.StatusId = GetStatusIdFromName(status); // You'd need to implement this
            
            if (resolutionNotes != null) entity.ResolutionNotes = resolutionNotes;
            if (cost.HasValue) entity.Cost = cost.Value;
            if (resolvedAt.HasValue) entity.ResolvedAt = resolvedAt.Value;
            
            await _repository.UpdateAsync(entity);
        }
    }
} 