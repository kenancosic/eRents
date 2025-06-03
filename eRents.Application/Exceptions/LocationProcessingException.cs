namespace eRents.Application.Exceptions
{
    /// <summary>
    /// Exception thrown when address or location processing fails
    /// Used by LocationManagementService for address validation and processing errors
    /// </summary>
    public class LocationProcessingException : ApplicationExceptionBase
    {
        public LocationProcessingException(string message) : base(message)
        {
        }

        public LocationProcessingException(string message, Exception innerException) : base(message, innerException)
        {
        }
    }
} 