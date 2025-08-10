using System.ComponentModel.DataAnnotations;

namespace eRents.Domain.Shared
{
	/// <summary>
	/// Base entity class that provides common properties
	/// </summary>
	public abstract class BaseEntity
	{
		/// <summary>
		/// Creation timestamp
		/// </summary>
		public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

		/// <summary>
		/// Last modification timestamp
		/// </summary>
		public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

		/// <summary>
		/// ID of the user who created this entity
		/// </summary>
		public int? CreatedBy { get; set; }

		/// <summary>
		/// ID of the user who last modified this entity
		/// </summary>
		public int? ModifiedBy { get; set; }
	}
}