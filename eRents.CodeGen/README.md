# eRents Code Generator - NEW FEATURE ARCHITECTURE

This tool generates boilerplate code for the eRents application using T4 templates, following the **new feature-based architecture** with clean separation of concerns and no repository layer.

## 🎯 **What Gets Generated**

When you run the generator, it creates a complete feature module:

### **✅ Feature Structure**
- Complete feature folder: `eRents.Features/{EntityName}Management/`
- Clean DTOs without cross-entity bloat
- Mappers for entity ↔ DTO conversion
- Services using ERentsContext directly (no repositories!)
- Controllers with proper error handling and logging

### **✅ Generated Files**
1. **DTOs** - Clean request/response objects with pagination support
2. **Mappers** - Static extension methods for entity ↔ DTO conversion
3. **Service** - Uses ERentsContext directly with UnitOfWork for transactions
4. **Controller** - RESTful API with proper HTTP status codes and error handling

### **✅ Architecture Benefits**
- **No Repository Layer** - Services use ERentsContext directly
- **Feature Organization** - All related code grouped by business domain
- **Clean DTOs** - 70% smaller than old bloated DTOs
- **Proper Separation** - Domain entities isolated from business logic

## 📋 **Prerequisites**

1. **.NET SDK** installed
2. **T4 (dotnet-t4) tool** installed globally:
   ```bash
   dotnet tool install -g dotnet-t4
   ```
3. Run from the **solution root directory**

## 🚀 **Usage**

### **Basic Generation**
```bash
dotnet run --project eRents.CodeGen -- <EntityName>
```

### **Example**
```bash
dotnet run --project eRents.CodeGen -- Amenity
```

This generates:
- `eRents.Features/AmenityManagement/DTOs/AmenityDtos.cs` - Clean DTOs
- `eRents.Features/AmenityManagement/Mappers/AmenityMapper.cs` - Entity ↔ DTO mappers
- `eRents.Features/AmenityManagement/Services/AmenityService.cs` - Service using ERentsContext
- `eRents.Features/AmenityManagement/Controllers/AmenitiesController.cs` - Feature controller

## 🔧 **Post-Generation Setup**

### **1. Register the Service**
Add to your service registration extensions:

```csharp
// In ServiceRegistrationExtensions.cs
services.AddScoped<AmenityService>();
```

### **2. Customize Property Mappings**
Update the generated mapper with your entity's actual properties:

```csharp
// In AmenityMapper.cs - customize these mappings
public static AmenityResponse ToAmenityResponse(this Amenity entity)
{
    return new AmenityResponse
    {
        Id = entity.Id,
        Name = entity.Name,           // Add your actual properties
        Description = entity.Description,
        // ... other properties
    };
}
```

### **3. Configure Entity Relationships**
Update the service to include related entities as needed:

```csharp
// In AmenityService.cs - add includes
var entity = await _context.Amenities
    .Include(x => x.RelatedEntity)  // Add your includes
    .FirstOrDefaultAsync(x => x.Id == id);
```

## 📁 **Generated File Structure**

```
eRents.Features/
  AmenityManagement/               # Complete feature module
    DTOs/
      AmenityDtos.cs              # Clean request/response DTOs
    Mappers/
      AmenityMapper.cs            # Entity ↔ DTO conversion
    Services/
      AmenityService.cs           # Business logic with ERentsContext
    Controllers/
      AmenitiesController.cs      # RESTful API endpoints
```

## 🎨 **Customizing Templates**

### **Mapper Template (`MapperGenerator.tt`)**
- Update entity property mappings
- Add Address mapping if entity has Address property
- Configure related entity ID collections

### **Service Template (`ServiceGenerator.tt`)**
- Add entity-specific includes for related data
- Configure custom filtering logic
- Add business validation rules

### **DTO Template (`DTOGenerator.tt`)**
- Update the properties list at the top of the template
- Add entity-specific search fields
- Configure pagination parameters

### **Controller Template (`ControllerGenerator.tt`)**
- Adjust authorization roles for your security model
- Add custom endpoints for entity-specific operations
- Configure error handling patterns

## ✨ **Features of Generated Code**

### **🎯 Clean Architecture**
- **No Repository Layer** - Services use ERentsContext directly
- **Feature Organization** - All related code in one place  
- **Clean DTOs** - No cross-entity bloat, just foreign key IDs
- **Proper Separation** - Domain models isolated from business logic

### **🔒 Security Features**
- Role-based authorization on all endpoints
- User context tracking with `ICurrentUserService`
- Comprehensive audit logging with user IDs

### **📊 Error Handling & Logging**
- Proper HTTP status codes (200, 201, 404, 500, etc.)
- Structured logging with entity IDs and operations
- Exception-specific handling (UnauthorizedAccess, InvalidOperation)
- User-friendly error messages

### **⚡ Performance Features**
- Pagination support built-in
- Efficient database queries with targeted includes
- Transaction management with UnitOfWork pattern
- Audit field population (CreatedBy, ModifiedBy, timestamps)

## 🚨 **Important Notes**

1. **Property Definitions**: Update the properties list in `DTOGenerator.tt` before generating
2. **Entity Mapping**: Customize the mapper methods with your entity's actual properties
3. **Database Includes**: Add `.Include()` statements for related entities in the service
4. **Authorization Roles**: Adjust controller authorization roles to match your security model
5. **Business Validation**: Add entity-specific validation rules in the service methods

## 🔧 **Troubleshooting**

- **Build Errors**: Ensure `eRents.Features` project is referenced in your main projects
- **T4 Issues**: Verify `dotnet-t4` tool is installed globally: `dotnet tool install -g dotnet-t4`
- **Missing ERentsContext**: Ensure your entity exists in the `ERentsContext.DbSet<Entity>`
- **Namespace Issues**: Check that all generated namespaces match your project structure
- **Service Registration**: Don't forget to register your new service in `ServiceRegistrationExtensions.cs`

## 🚀 **Next Steps After Generation**

1. **Test the endpoints** using Swagger or Postman
2. **Update frontend** to use the new API endpoints
3. **Add unit tests** for the new service methods
4. **Configure database migrations** if you've added new entities 