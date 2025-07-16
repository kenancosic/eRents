namespace eRents.Shared.Exceptions
{
    /// <summary>
    /// Custom exception intended for predictable, user-friendly validation / business rule violations.
    /// These are caught at the API boundary and returned as 400 Bad Request instead of 500.
    /// </summary>
    public class UserException : Exception
    {
        public UserException(string message) : base(message) { }
        public UserException(string message, Exception? inner) : base(message, inner) { }
    }
}
