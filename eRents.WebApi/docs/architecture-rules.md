# eRents Project Architecture Rules

This document defines the architectural principles and coding standards that must be followed when constructing backend components for the eRents project.

## 0. eRents Ecosystem Architecture

### Application Distribution
- **`e_rents_mobile`**: Consumer-facing mobile app for Users and Tenants
  - Property browsing and search
  - Booking management  
  - Tenant services
  - Review system (creating property reviews)
- **`e_rents_desktop`**: Business management desktop app for Landlords ONLY
  - Property portfolio management
  - Tenant management
  - Financial reporting
  - Maintenance oversight
  - Review management (replying to tenant reviews)

### Shared Backend Services
Both applications share the same backend API with role-based data filtering. The backend must support both application types while ensuring proper data access control.

### Authentication Strategy by Application

#### Desktop Application (Landlords Only)
```csharp
// Desktop authentication should validate landlord role
[HttpPost("login/desktop")]
public async Task<LoginResponseDto> DesktopLoginAsync(LoginRequestDto request)
{
    var user = await _userService.AuthenticateAsync(request.UsernameOrEmail, request.Password);
    
    // Desktop app restriction: Only landlords can access
    if (user.Role != UserType.Landlord)
        throw new UnauthorizedAccessException("Desktop application is for landlords only. Please use the mobile app.");
    
    var token = _tokenService.GenerateToken(user);
    return new LoginResponseDto { Token = token, User = user };
}
```

#### Mobile Application (Users & Tenants)
```csharp
// Mobile authentication supports Users and Tenants
[HttpPost("login/mobile")]
public async Task<LoginResponseDto> MobileLoginAsync(LoginRequestDto request)
{
    var user = await _userService.AuthenticateAsync(request.UsernameOrEmail, request.Password);
    
    // Mobile app supports Users and Tenants
    if (user.Role == UserType.Landlord)
        throw new UnauthorizedAccessException("Landlord accounts should use the desktop application for property management.");
    
    var token = _tokenService.GenerateToken(user);
    return new LoginResponseDto { Token = token, User = user };
}
```

## 1. Project Structure & Clean Architecture

### Layer Organization
- **eRents.Domain**: Core business entities, repositories interfaces, domain services
- **eRents.Application**: Application services, business logic, orchestration
- **eRents.WebApi**: Controllers, filters, middleware, API configuration
- **eRents.Shared**: DTOs, enums, exceptions, shared utilities
- **eRents.RabbitMQMicroservice**: Event-driven microservice for real-time features

### Dependency Rules
- **Domain layer** must not depend on any other layers
- **Application layer** can depend on Domain and Shared only
- **WebApi layer** can depend on Application, Domain, and Shared
- **Shared layer** should be dependency-free or minimal dependencies

## 2. User-Scoped Data Access & Security

### Current User Context
- **Always use `ICurrentUserService`** from `eRents.Shared/Services/` to access current user information
- **Filter all data by current user context** unless explicitly designed for admin/cross-user access
- **Never trust client-provided user IDs** - always use the authenticated user's ID from `ICurrentUserService.UserId`

### Data Filtering Patterns
```csharp
// Service Layer - Filter by current user
public class PropertyService : IPropertyService
{
    private readonly ICurrentUserService _currentUserService;
    private readonly IPropertyRepository _propertyRepository;
    
    public async Task<List<PropertyResponseDto>> GetPropertiesAsync()
    {
        var currentUserId = _currentUserService.UserId;
        var currentUserRole = _currentUserService.UserRole;
        
        // Landlords see only their properties
        if (currentUserRole == "Landlord")
        {
            return await _propertyRepository.GetByOwnerIdAsync(currentUserId);
        }
        
        // Tenants and Regular Users see available properties
        if (currentUserRole == "Tenant" || currentUserRole == "User")
        {
            return await _propertyRepository.GetAvailablePropertiesAsync();
        }
        
        throw new UnauthorizedAccessException("Invalid user role");
    }
}

// Repository Layer - Include user context in queries
public async Task<List<Property>> GetByOwnerIdAsync(string ownerId)
{
    return await _context.Properties
        .Where(p => p.OwnerId == ownerId)
        .ToListAsync();
}
```

### Role-Based Data Access Rules
- **Landlords**: Can only access their own properties, maintenance issues for their properties, bookings for their properties
- **Tenants**: Can access available properties, their own bookings, maintenance issues they reported
- **Regular Users**: Can browse available properties, create accounts, become tenants by making bookings
- **Unknown roles**: Should be denied access by default

### Security Validation Pattern
```csharp
// Always validate ownership before operations
public async Task<PropertyResponseDto> UpdatePropertyAsync(int propertyId, UpdatePropertyRequest request)
{
    var currentUserId = _currentUserService.UserId;
    var currentUserRole = _currentUserService.UserRole;
    var property = await _propertyRepository.GetByIdAsync(propertyId);
    
    if (property == null)
        throw new NotFoundException("Property not found");
        
    // Security check: Only landlords can update properties, and only their own
    if (currentUserRole != "Landlord" || property.OwnerId != currentUserId)
        throw new ForbiddenException("You can only update your own properties");
        
    // Proceed with update...
}
```

## 3. Code Generation Principles

### Always Use Existing Patterns
Before creating new files, examine existing patterns:
- **Controllers**: Follow `Controllers/` structure, inherit from base if available
- **Services**: Follow `Application/Service/` organization by feature
- **Repositories**: Implement `IBaseRepository<T>` from `Domain/Shared/`
- **DTOs**: Use `eRents.Shared/DTO/` structure with Request/Response folders
- **Models**: Follow Entity Framework patterns in `Domain/Models/`

### File Naming Conventions
- **Controllers**: `{Feature}Controller.cs` (e.g., `PropertyController.cs`)
- **Services**: `{Feature}Service.cs` in appropriate subfolder
- **Repositories**: `{Entity}Repository.cs` and `I{Entity}Repository.cs`
- **DTOs**: `{Purpose}{Entity}Dto.cs` (e.g., `CreatePropertyDto.cs`, `PropertyResponseDto.cs`)
- **Models**: Use singular names (e.g., `Property.cs`, not `Properties.cs`)

## 4. Shared Folder Utilization

### Mandatory Shared Components
Always use these existing components from `eRents.Shared`:

#### DTOs Structure
- **Requests**: `eRents.Shared/DTO/Requests/` for all input DTOs
- **Response**: `eRents.Shared/DTO/Response/` for all output DTOs
- Follow existing naming patterns: `{Action}{Entity}Request.cs`

#### Enums
- Use existing enums from `eRents.Shared/Enums/`
- Add new enums here, not in Domain models
- Examples: `UserType`, `PropertyType`, `BookingStatus`, etc.

#### Exceptions
- Use `eRents.Shared/Exceptions/` for custom exceptions
- Inherit from existing base exception classes if available
- Follow pattern: `{Feature}Exception.cs`

#### Search Objects
- Use `eRents.Shared/SearchObjects/` for complex query parameters
- Example: `PropertySearchObject.cs` for property filtering

### Services in Shared
- Check `eRents.Shared/Services/` for reusable components
- Don't duplicate functionality that exists here

## 5. Repository Pattern Rules

### Base Repository Usage
- All repositories MUST implement `IBaseRepository<T>`
- Use `BaseRepository<T>` as base class when possible
- Location: `eRents.Domain/Shared/`

### Repository Structure
```csharp
// Interface in Domain/Repositories/
public interface I{Entity}Repository : IBaseRepository<{Entity}>
{
    // Custom methods specific to entity
}

// Implementation in Domain/Repositories/
public class {Entity}Repository : BaseRepository<{Entity}>, I{Entity}Repository
{
    // Custom implementation
}
```

### Standard Repository Methods
Always implement these standard operations:
- `GetByIdAsync(int id)`
- `GetAllAsync()`
- `CreateAsync(T entity)`
- `UpdateAsync(T entity)`
- `DeleteAsync(int id)`
- `ExistsAsync(int id)`

## 6. Service Layer Architecture

### Service Organization
- Group services by feature under `Application/Service/`
- Examples: `BookingService/`, `PropertyService/`, `UserService/`
- One service per main entity/aggregate

### Service Interface Pattern
```csharp
// In Application/Service/{Feature}/
public interface I{Feature}Service
{
    Task<ResponseDto> MethodAsync(RequestDto request);
}

public class {Feature}Service : I{Feature}Service
{
    // Implementation
}
```

### Dependency Injection
- Register all services in DI container
- Use interface-based dependency injection
- Prefer constructor injection

## 7. API Controller Standards

### Controller Structure
```csharp
[ApiController]
[Route("api/[controller]")]
public class {Feature}Controller : ControllerBase
{
    private readonly I{Feature}Service _service;
    
    public {Feature}Controller(I{Feature}Service service)
    {
        _service = service;
    }
}
```

### HTTP Method Conventions
- **GET**: Retrieve data (`GetAsync`, `GetByIdAsync`)
- **POST**: Create new resources (`CreateAsync`)
- **PUT**: Update entire resources (`UpdateAsync`)
- **PATCH**: Partial updates (`PatchAsync`)
- **DELETE**: Delete resources (`DeleteAsync`)

### Response Standards
- Use consistent response format from `eRents.Shared/DTO/Response/`
- Return appropriate HTTP status codes
- Use `ActionResult<T>` for typed responses

## 8. Authentication & Authorization

### Security Rules
- All endpoints except public ones (login, register) require authentication
- Use JWT token-based authentication
- Check existing security implementation in `WebApi/Security/`
- Use existing filters from `WebApi/Filters/`

### Authorization Patterns
- Use role-based authorization (`[Authorize(Roles = "Landlord")]`)
- Check user ownership for resource access
- Implement resource-based authorization where needed

## 9. Error Handling

### Exception Handling
- Use existing exception types from `eRents.Shared/Exceptions/`
- Implement global exception handling middleware
- Return consistent error response format
- Log exceptions appropriately

### Validation Rules
- Use Data Annotations for basic validation
- Implement custom validators for complex business rules
- Validate in both DTOs and services

## 10. Database Interactions

### Entity Framework Patterns
- Use existing `ERentsContext` from `Domain/Models/`
- Follow existing migration patterns in `Domain/Migrations/`
- Use async methods for all database operations
- Implement proper transaction handling

### Query Optimization
- Use Include() for eager loading when needed
- Implement projection with Select() for large datasets
- Use pagination for list endpoints
- Consider query performance implications

## 11. DTO and Model Mapping

### Mapping Rules
- Never expose Domain models directly in API
- Always use DTOs for API contracts
- Implement mapping between DTOs and Domain models
- Consider using AutoMapper for complex mappings

### DTO Design
- Request DTOs for input validation
- Response DTOs for output formatting
- Keep DTOs focused and specific to use case

## 12. Image and File Handling

### Image Management
- Follow existing patterns in `Domain/Models/Image.cs`
- Store images as binary data with metadata
- Implement image optimization (compression, resizing)
- Use multipart/form-data for uploads
- Create thumbnail versions

### File Storage
- Use existing image handling from `Application/Service/ImageService/`
- Store files with proper naming conventions
- Implement file validation (size, type, security)

## 13. Real-time Features

### SignalR Integration
- Use existing RabbitMQ microservice patterns
- Implement hub classes for real-time communication
- Follow message patterns from `RabbitMQMicroservice/`
- Use proper group management for broadcasting

### Event-Driven Architecture
- Use RabbitMQ for inter-service communication
- Implement proper event handlers
- Follow existing processor patterns

## 14. Testing Considerations

### Test Data
- Use `SetupService.cs` for test data generation
- Create realistic test scenarios
- Use appropriate test user accounts
- Implement proper cleanup procedures

### Testing Patterns
- Write unit tests for services
- Integration tests for controllers
- Use dependency injection for testable code

## 15. Performance Guidelines

### Caching Strategy
- Implement caching for frequently accessed data
- Use appropriate cache expiration policies
- Consider distributed caching for scalability

### Async Programming
- Use async/await throughout the application
- Avoid blocking calls
- Implement proper cancellation token usage

## 16. Configuration and Environment

### Configuration Management
- Use existing configuration patterns
- Store sensitive data in secure configuration
- Implement environment-specific settings
- Use dependency injection for configuration

### Logging
- Use structured logging
- Log important business events
- Implement proper log levels
- Consider log aggregation needs

## 17. Code Quality Standards

### Code Style
- Follow existing C# conventions
- Use meaningful variable and method names
- Implement proper documentation comments
- Follow SOLID principles

### Review Checklist
Before submitting code, verify:
- [ ] Follows existing patterns in the project
- [ ] Uses components from eRents.Shared appropriately
- [ ] Implements proper error handling
- [ ] Includes appropriate validation
- [ ] Has proper async/await usage
- [ ] Follows security best practices
- [ ] Includes necessary unit tests
- [ ] Uses dependency injection correctly

## 18. Migration and Database Changes

### Entity Framework Migrations
- Create migrations for all model changes
- Use descriptive migration names
- Test migrations on development database
- Consider backward compatibility

### Database Design
- Follow existing foreign key patterns
- Implement proper indexes for performance
- Use appropriate data types
- Consider data integrity constraints

## 19. Review System Architecture (Social Media Style Conversations)

### Review Types and Business Logic
The eRents system supports a conversational review system with two distinct types of reviews:

#### Property Reviews with Threaded Conversations
- **Purpose**: Allow tenants to review properties after their stay, with landlord replies
- **Reviewer**: Tenant (user who booked and stayed at the property)
- **Subject**: Property (identified by `PropertyId`)
- **Timing**: Can only be created after booking has ended
- **Visibility**: Public to all users browsing properties
- **Conversations**: Landlords can reply to reviews, creating social media-style threads

#### Tenant Reviews  
- **Purpose**: Allow landlords to review tenants after booking completion
- **Reviewer**: Landlord (property owner)
- **Subject**: Tenant (user who booked the property, identified by `RevieweeId`)
- **Timing**: Can only be created after booking has ended
- **Visibility**: Only visible when tenant marks their profile as public

### Review Model Structure (Updated)
```csharp
public partial class Review
{
    public int ReviewId { get; set; }
    public ReviewType ReviewType { get; set; } // PropertyReview or TenantReview
    public int? PropertyId { get; set; } // Required for Property Reviews
    public int? RevieweeId { get; set; } // Required for Tenant Reviews
    public int? ReviewerId { get; set; } // Set automatically from current user
    public int? BookingId { get; set; } // Required for original reviews, optional for replies
    public decimal? StarRating { get; set; } // 1-5 stars, optional (null for replies)
    public string? Description { get; set; }
    public DateTime DateCreated { get; set; }
    
    // Threading system for conversations
    public int? ParentReviewId { get; set; } // null for original reviews, points to parent for replies
    
    // Navigation properties
    public virtual Review? ParentReview { get; set; }
    public virtual ICollection<Review> Replies { get; set; } = new List<Review>();
    public virtual ICollection<Image> Images { get; set; } = new List<Image>();
    public virtual Property? Property { get; set; }
    public virtual Booking? Booking { get; set; }
    public virtual User? Reviewer { get; set; }
    public virtual User? Reviewee { get; set; }
}

public enum ReviewType
{
    PropertyReview,  // Tenant reviewing a property after stay
    TenantReview     // Landlord reviewing a tenant after booking ends
}
```

### Security Implementation Patterns (Updated)

#### Review Creation Validation
```csharp
public async Task<ReviewResponse> CreateReviewAsync(ReviewInsertRequest request)
{
    var currentUserId = _currentUserService.UserId;
    var currentUserRole = _currentUserService.UserRole;
    
    // Handle replies vs original reviews
    if (request.ParentReviewId.HasValue)
    {
        return await CreateReplyAsync(request, currentUserId, currentUserRole);
    }
    else
    {
        return await CreateOriginalReviewAsync(request, currentUserId, currentUserRole);
    }
}

private async Task<ReviewResponse> CreateOriginalReviewAsync(ReviewInsertRequest request, int currentUserId, string currentUserRole)
{
    // Original reviews require booking validation
    var booking = await _bookingRepository.GetByIdAsync(request.BookingId.Value);
    if (booking == null || booking.Status != "Completed")
        throw new BusinessException("Reviews can only be created for completed bookings");
    
    // StarRating is required for original reviews
    if (!request.StarRating.HasValue)
        throw new BusinessException("Star rating is required for original reviews");
    
    // Validate review type and user context
    if (request.ReviewType == "PropertyReview")
    {
        if (currentUserRole != "Tenant" || booking.UserId != currentUserId)
            throw new ForbiddenException("Only tenants can review properties they've stayed at");
            
        if (request.PropertyId != booking.PropertyId)
            throw new BusinessException("Property ID must match booking property");
    }
    else if (request.ReviewType == "TenantReview")
    {
        if (currentUserRole != "Landlord")
            throw new ForbiddenException("Only landlords can review tenants");
            
        var property = await _propertyRepository.GetByIdAsync(booking.PropertyId);
        if (property?.OwnerId != currentUserId)
            throw new ForbiddenException("You can only review tenants who stayed at your properties");
    }
    
    // Set reviewer automatically
    request.ReviewerId = currentUserId;
    
    var review = _mapper.Map<Review>(request);
    await _reviewRepository.CreateAsync(review);
    return _mapper.Map<ReviewResponse>(review);
}

private async Task<ReviewResponse> CreateReplyAsync(ReviewInsertRequest request, int currentUserId, string currentUserRole)
{
    // Validate parent review exists
    var parentReview = await _reviewRepository.GetByIdAsync(request.ParentReviewId.Value);
    if (parentReview == null)
        throw new NotFoundException("Parent review not found");
    
    // Validate reply permissions
    if (parentReview.ReviewType == ReviewType.PropertyReview)
    {
        // Only property owners can reply to property reviews about their properties
        var property = await _propertyRepository.GetByIdAsync(parentReview.PropertyId.Value);
        if (property?.OwnerId != currentUserId)
            throw new ForbiddenException("You can only reply to reviews about your properties");
    }
    else if (parentReview.ReviewType == ReviewType.TenantReview)
    {
        // Users can reply to tenant reviews about themselves
        if (parentReview.RevieweeId != currentUserId)
            throw new ForbiddenException("You can only reply to reviews about yourself");
    }
    
    // Set properties for reply
    request.ReviewerId = currentUserId;
    request.ReviewType = parentReview.ReviewType.ToString();
    request.PropertyId = parentReview.PropertyId;
    request.RevieweeId = parentReview.RevieweeId;
    // BookingId and StarRating are optional for replies (can be null)
    
    var reply = _mapper.Map<Review>(request);
    await _reviewRepository.CreateAsync(reply);
    return _mapper.Map<ReviewResponse>(reply);
}
```

#### Review Access Validation (Updated)
```csharp
public async Task<List<ReviewResponse>> GetReviewsAsync(ReviewSearchObject search)
{
    var currentUserId = _currentUserService.UserId;
    var currentUserRole = _currentUserService.UserRole;
    
    var query = _reviewRepository.GetQueryable()
        .Include(r => r.Replies) // Include reply threads
        .ThenInclude(reply => reply.Reviewer)
        .Include(r => r.Reviewer)
        .Include(r => r.Property)
        .Include(r => r.Reviewee);
    
    // Filter for original reviews only (not replies)
    if (!search?.IncludeReplies == true)
    {
        query = query.Where(r => r.ParentReviewId == null);
    }
    
    // Apply user context filtering
    if (currentUserRole == "Landlord")
    {
        // Landlords see: Property reviews for their properties + Tenant reviews they wrote
        query = query.Where(r => 
            (r.ReviewType == ReviewType.PropertyReview && r.Property.OwnerId == currentUserId) ||
            (r.ReviewType == ReviewType.TenantReview && r.ReviewerId == currentUserId));
    }
    else if (currentUserRole == "Tenant")
    {
        // Tenants see: Property reviews they wrote + Tenant reviews about them (if profile public)
        query = query.Where(r => 
            (r.ReviewType == ReviewType.PropertyReview && r.ReviewerId == currentUserId) ||
            (r.ReviewType == ReviewType.TenantReview && r.RevieweeId == currentUserId && r.Reviewee.IsPublic));
    }
    else if (currentUserRole == "User")
    {
        // Regular users see: Property reviews for available properties
        query = query.Where(r => 
            r.ReviewType == ReviewType.PropertyReview && 
            r.Property.Status == "Available");
    }
    
    // Apply additional filters
    if (search?.PropertyId.HasValue == true)
    {
        query = query.Where(r => r.PropertyId == search.PropertyId);
    }
    
    var reviews = await query
        .OrderByDescending(r => r.DateCreated)
        .ToListAsync();
        
    return _mapper.Map<List<ReviewResponse>>(reviews);
}
```

### Repository Implementation Patterns (Updated)

#### Review Repository Interface
```csharp
public interface IReviewRepository : IBaseRepository<Review>
{
    Task<List<Review>> GetPropertyReviewsWithRepliesAsync(int propertyId);
    Task<List<Review>> GetTenantReviewsAsync(int tenantId, bool publicProfileOnly = true);
    Task<decimal> GetAverageRatingAsync(int propertyId); // Only considers original reviews with ratings
    Task<bool> HasUserReviewedPropertyAsync(int userId, int propertyId, int bookingId);
    Task<Review> GetReviewWithRepliesAsync(int reviewId);
    Task<List<Review>> GetRepliesAsync(int parentReviewId);
}
```

#### Review Repository Implementation
```csharp
public class ReviewRepository : BaseRepository<Review>, IReviewRepository
{
    public async Task<List<Review>> GetPropertyReviewsWithRepliesAsync(int propertyId)
    {
        return await _context.Reviews
            .Where(r => r.ReviewType == ReviewType.PropertyReview && 
                       r.PropertyId == propertyId &&
                       r.ParentReviewId == null) // Only original reviews
            .Include(r => r.Replies)
                .ThenInclude(reply => reply.Reviewer)
            .Include(r => r.Reviewer)
            .OrderByDescending(r => r.DateCreated)
            .ToListAsync();
    }
    
    public async Task<decimal> GetAverageRatingAsync(int propertyId)
    {
        var ratings = await _context.Reviews
            .Where(r => r.ReviewType == ReviewType.PropertyReview && 
                       r.PropertyId == propertyId && 
                       r.ParentReviewId == null && // Only original reviews
                       r.StarRating.HasValue)
            .Select(r => r.StarRating.Value)
            .ToListAsync();
            
        return ratings.Any() ? ratings.Average() : 0;
    }
    
    public async Task<Review> GetReviewWithRepliesAsync(int reviewId)
    {
        return await _context.Reviews
            .Include(r => r.Replies)
                .ThenInclude(reply => reply.Reviewer)
            .Include(r => r.Reviewer)
            .Include(r => r.Property)
            .Include(r => r.Reviewee)
            .FirstOrDefaultAsync(r => r.ReviewId == reviewId);
    }
}
```

### Controller Implementation Patterns (Updated)

#### Review Controller Structure
```csharp
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ReviewsController : BaseCRUDController<ReviewResponse, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
{
    private readonly IReviewService _reviewService;
    
    public ReviewsController(IReviewService reviewService) : base(reviewService)
    {
        _reviewService = reviewService;
    }
    
    [HttpGet("properties/{propertyId}")]
    public async Task<ActionResult<List<ReviewResponse>>> GetPropertyReviewsWithReplies(int propertyId)
    {
        var reviews = await _reviewService.GetPropertyReviewsWithRepliesAsync(propertyId);
        return Ok(reviews);
    }
    
    [HttpGet("{reviewId}/thread")]
    public async Task<ActionResult<ReviewResponse>> GetReviewThread(int reviewId)
    {
        var review = await _reviewService.GetReviewWithRepliesAsync(reviewId);
        return Ok(review);
    }
    
    [HttpPost("{reviewId}/reply")]
    public async Task<ActionResult<ReviewResponse>> ReplyToReview(int reviewId, [FromBody] string replyText)
    {
        var request = new ReviewInsertRequest
        {
            ParentReviewId = reviewId,
            Description = replyText,
            StarRating = null, // Replies don't require ratings
            BookingId = null   // Replies don't require booking reference
        };
        
        var reply = await _reviewService.CreateReviewAsync(request);
        return Ok(reply);
    }
}
```

### Migration Considerations (Updated)

#### Review Model Migration Pattern
```csharp
public partial class AddReviewThreadingSystem : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        // Remove Status field (no more moderation)
        migrationBuilder.DropColumn("status", "Reviews");
        
        // Add threading support
        migrationBuilder.AddColumn<int?>("parent_review_id", "Reviews", nullable: true);
        
        // Make StarRating nullable for replies
        migrationBuilder.AlterColumn<decimal?>("star_rating", "Reviews", nullable: true);
        
        // Make BookingId nullable for replies
        migrationBuilder.AlterColumn<int?>("booking_id", "Reviews", nullable: true);
        
        // Add self-referencing foreign key
        migrationBuilder.CreateIndex("IX_Reviews_parent_review_id", "Reviews", "parent_review_id");
        migrationBuilder.AddForeignKey("FK__Review__parent_review_id", "Reviews", "parent_review_id", "Reviews", principalColumn: "review_id");
    }
}
```

### Review System Checklist (Updated)

When implementing review functionality, verify:
- [ ] Threading system supports nested conversations
- [ ] Original reviews require StarRating and BookingId validation
- [ ] Replies can have null StarRating and BookingId
- [ ] ParentReviewId validation prevents orphaned replies
- [ ] Self-referencing foreign key is properly configured
- [ ] User permissions for replies are validated (property owners, reviewees)
- [ ] Average rating calculations exclude replies (only count original reviews)
- [ ] Frontend displays threaded conversation structure
- [ ] Real-time notifications for new replies (via SignalR)
- [ ] Performance indexes on ParentReviewId for reply lookups

### Performance Considerations (Updated)

- **Threading Indexes**: Ensure indexes on `ParentReviewId` for efficient reply queries
- **Nested Loading**: Use `Include()` with `ThenInclude()` for reply threads
- **Rating Calculations**: Filter out replies when calculating property averages
- [ ] Pagination: Implement pagination for original reviews, load replies on demand
- [ ] Caching: Cache review threads for popular properties
- [ ] Real-time Updates: Use SignalR for live reply notifications

## Remember: Always Examine Existing Code First!

Before creating any new component:
1. **Look for similar implementations** in the existing codebase
2. **Check Shared folder** for reusable components
3. **Follow established patterns** rather than creating new ones
4. **Use existing interfaces and base classes** when available
5. **Maintain consistency** with the existing architecture 