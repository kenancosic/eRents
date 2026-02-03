using System.Linq.Expressions;

namespace eRents.Features.Core.Extensions;

/// <summary>
/// Extension methods for common filter operations on IQueryable<T>.
/// Provides fluent API for building query filters with null-check handling.
/// </summary>
public static class QueryableFilterExtensions
{
    /// <summary>
    /// Adds an equality filter when the nullable value has a value.
    /// </summary>
    public static IQueryable<T> AddEquals<T, TValue>(
        this IQueryable<T> query,
        TValue? value,
        Expression<Func<T, TValue>> property)
        where TValue : struct
    {
        if (!value.HasValue) return query;
        return query.Where(ExpressionHelper.BuildEquals(property, value.Value));
    }

    /// <summary>
    /// Adds an equality filter when the nullable value has a value.
    /// </summary>
    public static IQueryable<T> AddEquals<T, TValue>(
        this IQueryable<T> query,
        TValue? value,
        Expression<Func<T, TValue?>> property)
        where TValue : struct
    {
        if (!value.HasValue) return query;
        return query.Where(ExpressionHelper.BuildEquals(property, value.Value));
    }

    /// <summary>
    /// Adds a minimum value filter (inclusive) for comparable types (including enums).
    /// </summary>
    public static IQueryable<T> AddMin<T, TValue>(
        this IQueryable<T> query,
        TValue? minValue,
        Expression<Func<T, TValue>> property)
        where TValue : struct, IComparable<TValue>
    {
        if (!minValue.HasValue) return query;
        return query.Where(ExpressionHelper.BuildGreaterThanOrEqual(property, minValue.Value));
    }

    /// <summary>
    /// Adds a maximum value filter (inclusive) for comparable types (including enums).
    /// </summary>
    public static IQueryable<T> AddMax<T, TValue>(
        this IQueryable<T> query,
        TValue? maxValue,
        Expression<Func<T, TValue>> property)
        where TValue : struct, IComparable<TValue>
    {
        if (!maxValue.HasValue) return query;
        return query.Where(ExpressionHelper.BuildLessThanOrEqual(property, maxValue.Value));
    }

    /// <summary>
    /// Adds a date range filter for DateTime properties.
    /// Both from and to are inclusive.
    /// </summary>
    public static IQueryable<T> AddDateRange<T>(
        this IQueryable<T> query,
        DateTime? from,
        DateTime? to,
        Expression<Func<T, DateTime>> property)
    {
        if (from.HasValue)
            query = query.Where(ExpressionHelper.BuildGreaterThanOrEqual(property, from.Value));
        if (to.HasValue)
            query = query.Where(ExpressionHelper.BuildLessThanOrEqual(property, to.Value));
        return query;
    }

    /// <summary>
    /// Adds a date range filter for nullable DateTime properties.
    /// Both from and to are inclusive.
    /// </summary>
    public static IQueryable<T> AddDateRange<T>(
        this IQueryable<T> query,
        DateTime? from,
        DateTime? to,
        Expression<Func<T, DateTime?>> property)
    {
        if (from.HasValue)
            query = query.Where(ExpressionHelper.BuildGreaterThanOrEqual(property, from.Value));
        if (to.HasValue)
            query = query.Where(ExpressionHelper.BuildLessThanOrEqual(property, to.Value));
        return query;
    }

    /// <summary>
    /// Adds a date range filter for nullable DateOnly properties.
    /// Both from and to are inclusive.
    /// </summary>
    public static IQueryable<T> AddDateRange<T>(
        this IQueryable<T> query,
        DateOnly? from,
        DateOnly? to,
        Expression<Func<T, DateOnly?>> property)
    {
        if (from.HasValue)
            query = query.Where(ExpressionHelper.BuildGreaterThanOrEqual(property, from.Value));
        if (to.HasValue)
            query = query.Where(ExpressionHelper.BuildLessThanOrEqual(property, to.Value));
        return query;
    }

    /// <summary>
    /// Adds a date range filter for non-nullable DateOnly properties.
    /// Both from and to are inclusive.
    /// </summary>
    public static IQueryable<T> AddDateRange<T>(
        this IQueryable<T> query,
        DateOnly? from,
        DateOnly? to,
        Expression<Func<T, DateOnly>> property)
    {
        if (from.HasValue)
            query = query.Where(ExpressionHelper.BuildGreaterThanOrEqual(property, from.Value));
        if (to.HasValue)
            query = query.Where(ExpressionHelper.BuildLessThanOrEqual(property, to.Value));
        return query;
    }

    /// <summary>
    /// Adds a contains filter for string properties (case-sensitive).
    /// </summary>
    public static IQueryable<T> AddContains<T>(
        this IQueryable<T> query,
        string? value,
        Expression<Func<T, string?>> property)
    {
        if (string.IsNullOrWhiteSpace(value)) return query;
        return query.Where(ExpressionHelper.BuildContains(property, value));
    }

    /// <summary>
    /// Adds a case-insensitive LIKE filter using EF.Functions.Like.
    /// </summary>
    public static IQueryable<T> AddLike<T>(
        this IQueryable<T> query,
        string? value,
        Expression<Func<T, string?>> property)
    {
        if (string.IsNullOrWhiteSpace(value)) return query;
        var pattern = $"%{value.Trim()}%";
        return query.Where(ExpressionHelper.BuildLike(property, pattern));
    }
}
