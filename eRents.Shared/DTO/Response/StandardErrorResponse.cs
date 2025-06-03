namespace eRents.Shared.DTO.Response
{
    /// <summary>
    /// Standardized error response format for consistent API error handling
    /// Part of Phase 2.2 enhancement for controller error handling standardization
    /// </summary>
    public class StandardErrorResponse
    {
        /// <summary>
        /// Type of error: "Validation", "Authorization", "NotFound", "Platform", "LocationProcessing", "Internal"
        /// </summary>
        public string Type { get; set; } = string.Empty;
        
        /// <summary>
        /// Human-readable error message
        /// </summary>
        public string Message { get; set; } = string.Empty;
        
        /// <summary>
        /// Validation errors grouped by field name
        /// </summary>
        public Dictionary<string, string[]> ValidationErrors { get; set; } = new();
        
        /// <summary>
        /// Trace ID for debugging purposes
        /// </summary>
        public string? TraceId { get; set; }
        
        /// <summary>
        /// Timestamp when the error occurred
        /// </summary>
        public DateTime Timestamp { get; set; }
        
        /// <summary>
        /// Request ID for tracking
        /// </summary>
        public string? RequestId { get; set; }
        
        /// <summary>
        /// API path where the error occurred
        /// </summary>
        public string? Path { get; set; }
    }
} 