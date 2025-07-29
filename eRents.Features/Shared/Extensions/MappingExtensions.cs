using System.Reflection;

namespace eRents.Features.Shared.Extensions;

/// <summary>
/// Generic mapping helpers to reduce boilerplate in entity ↔ DTO mappings
/// </summary>
public static class MappingExtensions
{
    /// <summary>
    /// Maps audit fields (CreatedAt, UpdatedAt) to an entity
    /// </summary>
    /// <typeparam name="TEntity">Entity type</typeparam>
    /// <param name="entity">Entity instance</param>
    /// <param name="createdAt">Created date (optional, uses current UTC time if null)</param>
    /// <param name="updatedAt">Updated date (optional, uses current UTC time if null)</param>
    public static void MapAuditFields<TEntity>(this TEntity entity, DateTime? createdAt = null, DateTime? updatedAt = null)
        where TEntity : class
    {
        var entityType = typeof(TEntity);
        var utcNow = DateTime.UtcNow;

        var createdAtProp = entityType.GetProperty("CreatedAt");
        if (createdAtProp != null && createdAtProp.CanWrite)
        {
            createdAtProp.SetValue(entity, createdAt ?? utcNow);
        }

        var updatedAtProp = entityType.GetProperty("UpdatedAt");
        if (updatedAtProp != null && updatedAtProp.CanWrite)
        {
            updatedAtProp.SetValue(entity, updatedAt ?? utcNow);
        }
    }

    /// <summary>
    /// Maps common properties from source to target object by name and type matching
    /// </summary>
    /// <typeparam name="TTarget">Target type</typeparam>
    /// <param name="target">Target object</param>
    /// <param name="source">Source object</param>
    /// <param name="excludeProperties">Properties to exclude from mapping</param>
    /// <returns>Target object with mapped properties</returns>
    public static TTarget MapCommonProperties<TTarget>(this TTarget target, object source, params string[] excludeProperties)
        where TTarget : class
    {
        if (source == null) return target;

        var sourceType = source.GetType();
        var targetType = typeof(TTarget);
        var excludeSet = new HashSet<string>(excludeProperties ?? Array.Empty<string>());

        var sourceProps = sourceType.GetProperties(BindingFlags.Public | BindingFlags.Instance);
        var targetProps = targetType.GetProperties(BindingFlags.Public | BindingFlags.Instance);

        foreach (var sourceProp in sourceProps)
        {
            if (excludeSet.Contains(sourceProp.Name) || !sourceProp.CanRead)
                continue;

            var targetProp = targetProps.FirstOrDefault(p => 
                p.Name == sourceProp.Name && 
                p.CanWrite && 
                (p.PropertyType == sourceProp.PropertyType || IsNullableMatch(p.PropertyType, sourceProp.PropertyType)));

            if (targetProp != null)
            {
                var value = sourceProp.GetValue(source);
                targetProp.SetValue(target, value);
            }
        }

        return target;
    }

    /// <summary>
    /// Creates a new instance of TTarget and maps common properties from source
    /// </summary>
    /// <typeparam name="TTarget">Target type</typeparam>
    /// <param name="source">Source object</param>
    /// <param name="excludeProperties">Properties to exclude from mapping</param>
    /// <returns>New instance of TTarget with mapped properties</returns>
    public static TTarget MapTo<TTarget>(this object source, params string[] excludeProperties)
        where TTarget : class, new()
    {
        var target = new TTarget();
        return target.MapCommonProperties(source, excludeProperties);
    }

    /// <summary>
    /// Maps DateOnly to DateTime conversion (common in eRents domain)
    /// </summary>
    /// <param name="dateOnly">DateOnly value</param>
    /// <param name="timeOnly">TimeOnly value (optional, uses MinValue if null)</param>
    /// <returns>DateTime value</returns>
    public static DateTime ToDateTime(this DateOnly dateOnly, TimeOnly? timeOnly = null)
    {
        return dateOnly.ToDateTime(timeOnly ?? TimeOnly.MinValue);
    }

    /// <summary>
    /// Maps DateTime to DateOnly conversion (common in eRents domain)
    /// </summary>
    /// <param name="dateTime">DateTime value</param>
    /// <returns>DateOnly value</returns>
    public static DateOnly ToDateOnly(this DateTime dateTime)
    {
        return DateOnly.FromDateTime(dateTime);
    }

    /// <summary>
    /// Maps nullable DateTime to nullable DateOnly conversion
    /// </summary>
    /// <param name="dateTime">Nullable DateTime value</param>
    /// <returns>Nullable DateOnly value</returns>
    public static DateOnly? ToDateOnly(this DateTime? dateTime)
    {
        return dateTime?.ToDateOnly();
    }

    /// <summary>
    /// Safely formats a full name from first and last name
    /// </summary>
    /// <param name="firstName">First name</param>
    /// <param name="lastName">Last name</param>
    /// <returns>Formatted full name or null if both are empty</returns>
    public static string? FormatFullName(string? firstName, string? lastName)
    {
        var fullName = $"{firstName} {lastName}".Trim();
        return string.IsNullOrEmpty(fullName) ? null : fullName;
    }

    /// <summary>
    /// Maps collection of entities to collection of DTOs using a mapper function
    /// </summary>
    /// <typeparam name="TSource">Source type</typeparam>
    /// <typeparam name="TTarget">Target type</typeparam>
    /// <param name="source">Source collection</param>
    /// <param name="mapper">Mapping function</param>
    /// <returns>Mapped collection</returns>
    public static List<TTarget> MapCollection<TSource, TTarget>(this IEnumerable<TSource>? source, Func<TSource, TTarget> mapper)
    {
        return source?.Select(mapper).ToList() ?? new List<TTarget>();
    }

    /// <summary>
    /// Checks if two types are compatible for mapping (including nullable variations)
    /// </summary>
    /// <param name="targetType">Target property type</param>
    /// <param name="sourceType">Source property type</param>
    /// <returns>True if types are compatible for mapping</returns>
    private static bool IsNullableMatch(Type targetType, Type sourceType)
    {
        // Handle nullable types
        var targetUnderlyingType = Nullable.GetUnderlyingType(targetType) ?? targetType;
        var sourceUnderlyingType = Nullable.GetUnderlyingType(sourceType) ?? sourceType;

        return targetUnderlyingType == sourceUnderlyingType;
    }
}
