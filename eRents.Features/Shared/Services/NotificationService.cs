using eRents.Domain.Models;
using eRents.Domain.Shared;
using eRents.Features.Core.Models.Shared;
using eRents.Domain.Shared.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.Features.Shared.Services
{
	/// <summary>
	/// Notification service with database persistence using direct ERentsContext access
	/// Manages in-app notifications with future email integration support
	/// </summary>
	public class NotificationService : INotificationService
	{
		private readonly ERentsContext _context;
		private readonly ICurrentUserService _currentUserService;
		private readonly ILogger<NotificationService> _logger;

		public NotificationService(
				ERentsContext context,
				ICurrentUserService currentUserService,
				ILogger<NotificationService> logger)
		{
			_context = context;
			_currentUserService = currentUserService;
			_logger = logger;
		}

		#region Core Notification Operations

		public async Task CreateNotificationAsync(int userId, string title, string message, string type, int? referenceId = null)
		{
			try
			{
				// Validate user exists
				var userExists = await _context.Users.AnyAsync(u => u.UserId == userId);
				if (!userExists)
				{
					_logger.LogWarning("Cannot create notification - User {UserId} not found", userId);
					return;
				}

				var notification = new Notification
				{
					UserId = userId,
					Title = title,
					Message = message,
					Type = type,
					ReferenceId = referenceId,
					IsRead = false,

				};

				_context.Notifications.Add(notification);
				await _context.SaveChangesAsync();

				_logger.LogInformation("Created {Type} notification for User {UserId}: {Title}",
						type, userId, title);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error creating notification for User {UserId}", userId);
				throw;
			}
		}

		public async Task<List<NotificationResponse>> GetUnreadNotificationsAsync(int userId)
		{
			try
			{
				var notifications = await _context.Notifications
						.Where(n => n.UserId == userId && !n.IsRead)
						.OrderByDescending(n => n.CreatedAt)
						.ToListAsync();

				return notifications.Select(ToNotificationResponse).ToList();
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error getting unread notifications for User {UserId}", userId);
				throw;
			}
		}

		public async Task<List<NotificationResponse>> GetNotificationsAsync(int userId, int skip = 0, int take = 20)
		{
			try
			{
				var notifications = await _context.Notifications
						.Where(n => n.UserId == userId)
						.OrderByDescending(n => n.CreatedAt)
						.Skip(skip)
						.Take(take)
						.ToListAsync();

				return notifications.Select(ToNotificationResponse).ToList();
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error getting notifications for User {UserId}", userId);
				throw;
			}
		}

		public async Task MarkAsReadAsync(int notificationId)
		{
			try
			{
				var notification = await _context.Notifications
						.FirstOrDefaultAsync(n => n.NotificationId == notificationId);

				if (notification != null)
				{
					notification.IsRead = true;
					await _context.SaveChangesAsync();

					_logger.LogInformation("Marked notification {NotificationId} as read", notificationId);
				}
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error marking notification {NotificationId} as read", notificationId);
				throw;
			}
		}

		public async Task MarkAllAsReadAsync(int userId)
		{
			try
			{
				var unreadNotifications = await _context.Notifications
						.Where(n => n.UserId == userId && !n.IsRead)
						.ToListAsync();

				foreach (var notification in unreadNotifications)
				{
					notification.IsRead = true;
				}

				if (unreadNotifications.Any())
				{
					await _context.SaveChangesAsync();
					_logger.LogInformation("Marked {Count} notifications as read for User {UserId}",
							unreadNotifications.Count, userId);
				}
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error marking all notifications as read for User {UserId}", userId);
				throw;
			}
		}

		public async Task DeleteNotificationAsync(int notificationId)
		{
			try
			{
				var notification = await _context.Notifications
						.FirstOrDefaultAsync(n => n.NotificationId == notificationId);

				if (notification != null)
				{
					_context.Notifications.Remove(notification);
					await _context.SaveChangesAsync();

					_logger.LogInformation("Deleted notification {NotificationId}", notificationId);
				}
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error deleting notification {NotificationId}", notificationId);
				throw;
			}
		}

		public async Task<int> GetUnreadCountAsync(int userId)
		{
			try
			{
				return await _context.Notifications
						.CountAsync(n => n.UserId == userId && !n.IsRead);
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error getting unread count for User {UserId}", userId);
				return 0;
			}
		}

		#endregion

		#region Specialized Notification Methods

		public async Task CreateBookingNotificationAsync(int userId, int bookingId, string title, string message)
		{
			await CreateNotificationAsync(userId, title, message, "booking", bookingId);
		}

		public async Task CreatePaymentNotificationAsync(int userId, int paymentId, string title, string message)
		{
			await CreateNotificationAsync(userId, title, message, "payment", paymentId);
		}

		public async Task CreateMaintenanceNotificationAsync(int userId, int maintenanceIssueId, string title, string message)
		{
			await CreateNotificationAsync(userId, title, message, "maintenance", maintenanceIssueId);
		}

		public async Task CreateReviewNotificationAsync(int userId, int reviewId, string title, string message)
		{
			await CreateNotificationAsync(userId, title, message, "review", reviewId);
		}

		public async Task CreatePropertyNotificationAsync(int userId, int propertyId, string title, string message)
		{
			await CreateNotificationAsync(userId, title, message, "property", propertyId);
		}

		public async Task CreateSystemNotificationAsync(int userId, string title, string message)
		{
			await CreateNotificationAsync(userId, title, message, "system");
		}

		#endregion

		#region Email Integration

		public async Task SendEmailNotificationAsync(int userId, string subject, string message)
		{
			try
			{
				// Get user email
				var user = await _context.Users
						.FirstOrDefaultAsync(u => u.UserId == userId);

				if (user?.Email == null)
				{
					_logger.LogWarning("Cannot send email notification - User {UserId} has no email", userId);
					return;
				}

				// TODO: Implement actual email sending via email service
				// For now, just log the email notification
				_logger.LogInformation("📧 EMAIL NOTIFICATION for User {UserId} ({Email}): {Subject} - {Message}",
						userId, user.Email, subject, message);

				// Future enhancement: Integrate with email service (SendGrid, SMTP, etc.)
				await Task.CompletedTask;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error sending email notification to User {UserId}", userId);
				// Don't throw - email failures shouldn't break the main flow
			}
		}

		public async Task CreateNotificationWithEmailAsync(int userId, string title, string message, string type,
				bool sendEmail = false, int? referenceId = null)
		{
			try
			{
				// Create in-app notification
				await CreateNotificationAsync(userId, title, message, type, referenceId);

				// Send email if requested
				if (sendEmail)
				{
					await SendEmailNotificationAsync(userId, title, message);
				}
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error creating notification with email for User {UserId}", userId);
				throw;
			}
		}

		#endregion

		#region Private Helper Methods

		private static NotificationResponse ToNotificationResponse(Notification notification)
		{
			return new NotificationResponse
			{
				NotificationId = notification.NotificationId,
				UserId = notification.UserId,
				Title = notification.Title,
				Message = notification.Message,
				Type = notification.Type,
				CreatedAt = notification.CreatedAt,
				IsRead = notification.IsRead
			};
		}

		#endregion
	}
}