using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Model.DTO.Requests
{
    public class PropertiesInsertRequest
    {
        [MinLength(4)]
        [Required(AllowEmptyStrings = false)]
        public string PropertyType { get; set; }
        [Required(AllowEmptyStrings = false)]
        public string Address { get; set; }
        [Required]
        public int UserId { get; set; }
        [Required]
        public int CityId { get; set; }
        public decimal Price { get; set; }
    }
}