namespace eRents.Features.LookupManagement.Models
{
    /// <summary>
    /// Generic lookup item response
    /// </summary>
    public class LookupItemResponse
    {
        public int Value { get; set; }
        public string Text { get; set; } = null!;
        public string? Description { get; set; }
    }
}