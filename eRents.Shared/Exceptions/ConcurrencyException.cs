using System;

namespace eRents.Shared.Exceptions
{
    /// <summary>
    /// Exception thrown when a concurrency conflict is detected
    /// </summary>
    public class ConcurrencyException : Exception
    {
        public string EntityName { get; }
        public object EntityId { get; }
        public string ConflictType { get; }

        public ConcurrencyException(string entityName, object entityId, string conflictType) 
            : base($"Concurrency conflict detected for {entityName} with ID {entityId}. Conflict type: {conflictType}")
        {
            EntityName = entityName;
            EntityId = entityId;
            ConflictType = conflictType;
        }

        public ConcurrencyException(string entityName, object entityId, string conflictType, Exception innerException)
            : base($"Concurrency conflict detected for {entityName} with ID {entityId}. Conflict type: {conflictType}", innerException)
        {
            EntityName = entityName;
            EntityId = entityId;
            ConflictType = conflictType;
        }

        public ConcurrencyException(string message) : base(message) { }
        public ConcurrencyException(string message, Exception innerException) : base(message, innerException) { }
    }
} 