# eRents Project Architecture Rules

This document defines the architectural principles and coding standards that must be followed when constructing backend components for the eRents project.

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

## 2. Code Generation Principles

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

## 3. Shared Folder Utilization

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

## 4. Repository Pattern Rules

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

## 5. Service Layer Architecture

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

## 6. API Controller Standards

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

## 7. Authentication & Authorization

### Security Rules
- All endpoints except public ones (login, register) require authentication
- Use JWT token-based authentication
- Check existing security implementation in `WebApi/Security/`
- Use existing filters from `WebApi/Filters/`

### Authorization Patterns
- Use role-based authorization (`[Authorize(Roles = "Landlord")]`)
- Check user ownership for resource access
- Implement resource-based authorization where needed

## 8. Error Handling

### Exception Handling
- Use existing exception types from `eRents.Shared/Exceptions/`
- Implement global exception handling middleware
- Return consistent error response format
- Log exceptions appropriately

### Validation Rules
- Use Data Annotations for basic validation
- Implement custom validators for complex business rules
- Validate in both DTOs and services

## 9. Database Interactions

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

## 10. DTO and Model Mapping

### Mapping Rules
- Never expose Domain models directly in API
- Always use DTOs for API contracts
- Implement mapping between DTOs and Domain models
- Consider using AutoMapper for complex mappings

### DTO Design
- Request DTOs for input validation
- Response DTOs for output formatting
- Keep DTOs focused and specific to use case

## 11. Image and File Handling

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

## 12. Real-time Features

### SignalR Integration
- Use existing RabbitMQ microservice patterns
- Implement hub classes for real-time communication
- Follow message patterns from `RabbitMQMicroservice/`
- Use proper group management for broadcasting

### Event-Driven Architecture
- Use RabbitMQ for inter-service communication
- Implement proper event handlers
- Follow existing processor patterns

## 13. Testing Considerations

### Test Data
- Use `SetupService.cs` for test data generation
- Create realistic test scenarios
- Use appropriate test user accounts
- Implement proper cleanup procedures

### Testing Patterns
- Write unit tests for services
- Integration tests for controllers
- Use dependency injection for testable code

## 14. Performance Guidelines

### Caching Strategy
- Implement caching for frequently accessed data
- Use appropriate cache expiration policies
- Consider distributed caching for scalability

### Async Programming
- Use async/await throughout the application
- Avoid blocking calls
- Implement proper cancellation token usage

## 15. Configuration and Environment

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

## 16. Code Quality Standards

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

## 17. Migration and Database Changes

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

## Remember: Always Examine Existing Code First!

Before creating any new component:
1. **Look for similar implementations** in the existing codebase
2. **Check Shared folder** for reusable components
3. **Follow established patterns** rather than creating new ones
4. **Use existing interfaces and base classes** when available
5. **Maintain consistency** with the existing architecture 