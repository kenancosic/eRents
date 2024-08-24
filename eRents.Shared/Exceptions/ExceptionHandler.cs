using System.Data.Common;

namespace eRents.Shared.Exceptions
{
	public class ValidationException : Exception
	{
		public ValidationException(string message) : base(message) { }
	}

	public class ServiceException : Exception
	{
		public ServiceException(string message, Exception innerException) : base(message, innerException) { }
	}
	public class RepositoryException : Exception
	{
		public RepositoryException(string message, Exception repositoryException) : base(message, repositoryException) { }
	}
}
