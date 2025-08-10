using System;
using eRents.Domain.Models.Enums;
using eRents.Features.Core.Models;

namespace eRents.Features.MaintenanceManagement.Models
{
    public class MaintenanceIssueSearch : BaseSearchObject
    {
        public int? PropertyId { get; set; }
        public MaintenanceIssuePriorityEnum? PriorityMin { get; set; }
        public MaintenanceIssuePriorityEnum? PriorityMax { get; set; }
        public MaintenanceIssueStatusEnum[]? Statuses { get; set; }
        public DateTime? CreatedFrom { get; set; }
        public DateTime? CreatedTo { get; set; }
    }
}
