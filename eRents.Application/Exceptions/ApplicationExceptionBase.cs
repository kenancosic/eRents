namespace eRents.Application.Exceptions
{
	public abstract class ApplicationExceptionBase : Exception
	{
		protected ApplicationExceptionBase()
		{
		}

		protected ApplicationExceptionBase(string message)
				: base(message)
		{
		}

		protected ApplicationExceptionBase(string message, Exception innerException)
				: base(message, innerException)
		{
		}
	}
}
