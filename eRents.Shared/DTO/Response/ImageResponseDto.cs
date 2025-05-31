namespace eRents.Shared.DTO.Response
{
    public class ImageResponseDto
    {
        public int ImageId { get; set; }
        
        /// <summary>
        /// Generated URL to access the image via API endpoint (e.g., "/Images/{ImageId}")
        /// </summary>
        public string Url { get; set; } = null!;
        
        public string? FileName { get; set; }
        public string? ContentType { get; set; }          // e.g., "image/jpeg", "image/png"
        public DateTime? DateUploaded { get; set; }
        public int? Width { get; set; }
        public int? Height { get; set; }
        public long? FileSizeBytes { get; set; }
        public bool IsCover { get; set; }
        
        /// <summary>
        /// Generated URL for thumbnail version (if available)
        /// </summary>
        public string? ThumbnailUrl { get; set; }
    }
} 