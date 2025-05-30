using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using eRents.Shared.Enums;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace eRents.Application.Service.MaintenanceService
{
    public class MaintenanceService : ICRUDService<MaintenanceIssueResponse, MaintenanceIssueSearchObject, MaintenanceIssueRequest, MaintenanceIssueRequest>, IMaintenanceService
    {
        private readonly IMaintenanceRepository _repository;
        private readonly IMapper _mapper;
        private readonly ERentsContext _context;

        public MaintenanceService(IMaintenanceRepository repository, IMapper mapper, ERentsContext context)
        {
            _repository = repository;
            _mapper = mapper;
            _context = context;
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
            
            // Since status names are now unified, we can use them directly
            var statusEntity = await _context.IssueStatuses
                .FirstOrDefaultAsync(s => s.StatusName == status);
                
            if (statusEntity != null)
            {
                entity.StatusId = statusEntity.StatusId;
            }
            
            if (resolutionNotes != null) entity.ResolutionNotes = resolutionNotes;
            if (cost.HasValue) entity.Cost = cost.Value;
            if (resolvedAt.HasValue) entity.ResolvedAt = resolvedAt.Value;
            
            await _repository.UpdateAsync(entity);
        }
    }
} 