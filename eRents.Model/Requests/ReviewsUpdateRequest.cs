using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Model.Requests
{
    public class ReviewsUpdateRequests
    {
        public int Id { get; set; }
        public string Content { get; set; }
        public int Rating { get; set; }
        public bool IsApproved { get; set; }
        public bool IsDeleted { get; set; }
        public int PropertyId { get; set; }
        public int UserId { get; set; }
        public DateTime InsertedAt { get; set; }
    }
}
