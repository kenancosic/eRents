using System.Linq.Expressions;

namespace eRents.Features.Core;

/// <summary>
/// Helper class to build expression trees dynamically for query filtering.
/// </summary>
public static class ExpressionHelper
{
    /// <summary>
    /// Builds an equality comparison expression.
    /// </summary>
    public static Expression<Func<T, bool>> BuildEquals<T, TValue>(
        Expression<Func<T, TValue>> property,
        TValue value)
    {
        var param = property.Parameters[0];
        var constant = Expression.Constant(value, typeof(TValue));
        var equality = Expression.Equal(property.Body, constant);
        return Expression.Lambda<Func<T, bool>>(equality, param);
    }

    /// <summary>
    /// Builds a greater-than-or-equal comparison expression.
    /// </summary>
    public static Expression<Func<T, bool>> BuildGreaterThanOrEqual<T, TValue>(
        Expression<Func<T, TValue>> property,
        TValue value)
    {
        var param = property.Parameters[0];
        var constant = Expression.Constant(value, typeof(TValue));
        var comparison = Expression.GreaterThanOrEqual(property.Body, constant);
        return Expression.Lambda<Func<T, bool>>(comparison, param);
    }

    /// <summary>
    /// Builds a less-than-or-equal comparison expression.
    /// </summary>
    public static Expression<Func<T, bool>> BuildLessThanOrEqual<T, TValue>(
        Expression<Func<T, TValue>> property,
        TValue value)
    {
        var param = property.Parameters[0];
        var constant = Expression.Constant(value, typeof(TValue));
        var comparison = Expression.LessThanOrEqual(property.Body, constant);
        return Expression.Lambda<Func<T, bool>>(comparison, param);
    }

    /// <summary>
    /// Builds a string contains expression.
    /// </summary>
    public static Expression<Func<T, bool>> BuildContains<T>(
        Expression<Func<T, string?>> property,
        string value)
    {
        var param = property.Parameters[0];
        var constant = Expression.Constant(value);
        var containsMethod = typeof(string).GetMethod("Contains", new[] { typeof(string) })!;
        var call = Expression.Call(property.Body, containsMethod, constant);
        return Expression.Lambda<Func<T, bool>>(call, param);
    }

    /// <summary>
    /// Builds an EF.Functions.Like expression for case-insensitive pattern matching.
    /// </summary>
    public static Expression<Func<T, bool>> BuildLike<T>(
        Expression<Func<T, string?>> property,
        string pattern)
    {
        var param = property.Parameters[0];
        var patternConstant = Expression.Constant(pattern);
        var efFunctions = typeof(Microsoft.EntityFrameworkCore.EF).GetProperty("Functions")!;
        var likeMethod = typeof(Microsoft.EntityFrameworkCore.DbFunctions).GetMethod("Like",
            new[] { typeof(string), typeof(string) })!;

        var functionsAccess = Expression.Property(null, efFunctions);
        var call = Expression.Call(functionsAccess, likeMethod, property.Body, patternConstant);
        return Expression.Lambda<Func<T, bool>>(call, param);
    }
}
