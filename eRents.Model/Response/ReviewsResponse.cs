namespace eRents.Model.Response
{
    public class ReviewsResponse
    {
        public int ReviewId { get; set; }
        public int? PropertyId { get; set; }
        public int? UserId { get; set; }
        public decimal Rating { get; set; }
        public string Comment { get; set; }
        public DateTime? ReviewDate { get; set; }
        public PropertiesResponse Property { get; set; }
        public UsersResponse User { get; set; }
        public List<int> ImageIds { get; set; }
    }
}