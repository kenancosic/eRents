# eRents Code Generator

This tool generates boilerplate code for the eRents application using T4 templates, following the **enhanced architecture patterns** with comprehensive error handling, logging, and security.

## 🎯 **What Gets Generated**

When you run the generator, it creates:

### **✅ Controller (EnhancedBaseCRUDController)**
- Inherits from `EnhancedBaseCRUDController` with comprehensive error handling
- Includes proper authorization attributes and role-based access
- Integrated logging with user context tracking
- Structured error handling with `HandleStandardError`
- Ready-to-use CRUD endpoints with documentation

### **✅ Service Layer**
- Service interface extending `ICRUDService`
- Service implementation with proper constructor injection
- Integration with `ICurrentUserService` for user context
- Comprehensive logging throughout all operations
- Pre/post operation hooks for business logic
- Entity-specific filtering and include logic

### **✅ DTOs with Inheritance**
- Request DTOs inheriting from `BaseInsertRequest` and `BaseUpdateRequest`
- Response DTOs with proper documentation
- Search objects inheriting from `BaseSearchObject`
- Proper namespace organization

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
- `eRents.Shared/DTO/AmenityDTOs.cs` - All DTOs for the entity
- `eRents.Application/Service/AmenityService/IAmenityService.cs` - Service interface
- `eRents.Application/Service/AmenityService/AmenityService.cs` - Service implementation
- `eRents.WebApi/Controllers/AmenitiesController.cs` - Enhanced controller

## 🔧 **Post-Generation Setup**

### **1. Register the Service**
Add to your service registration extensions in `Program.cs`:

```csharp
// In ServiceRegistrationExtensions.cs - AddERentsBusinessServices method
services.AddScoped<IAmenityService, AmenityService>();
```

### **2. Configure AutoMapper**
Add mapping profile for your new entity:

```csharp
// In your AutoMapper profile
CreateMap<Amenity, AmenityResponse>();
CreateMap<AmenityInsertRequest, Amenity>();
CreateMap<AmenityUpdateRequest, Amenity>();
```

### **3. Customize Generated Code**
- **Update property definitions** in the DTO template before generation
- **Adjust authorization roles** in the controller as needed
- **Add entity-specific business logic** in the service hooks
- **Configure entity relationships** in the AddInclude method

## 📁 **Generated File Structure**

```
eRents.Shared/
  DTO/
    AmenityDTOs.cs                 # All DTOs for the entity

eRents.Application/
  Service/
    AmenityService/
      IAmenityService.cs           # Service interface
      AmenityService.cs            # Service implementation

eRents.WebApi/
  Controllers/
    AmenitiesController.cs         # Enhanced controller
```

## 🎨 **Customizing Templates**

### **Controller Template (`ControllerGenerator.tt`)**
- Modify authorization roles
- Add custom endpoints
- Adjust error handling patterns

### **Service Template (`ServiceGenerator.tt`)**
- Add entity-specific business logic
- Configure custom filtering
- Add validation rules

### **DTO Template (`DTOGenerator.tt`)**
- Update the properties list at the top of the template
- Add entity-specific validation attributes
- Configure custom search fields

## ✨ **Features of Generated Code**

### **🔒 Security Features**
- Role-based authorization on all endpoints
- User context tracking with `ICurrentUserService`
- Comprehensive audit logging

### **📊 Logging & Monitoring**
- Structured logging with user IDs and trace information
- Operation-specific log messages
- Error tracking with full context

### **🎯 Error Handling**
- Standardized error responses
- Proper HTTP status codes
- Exception type handling
- User-friendly error messages

### **🏗️ Architecture Compliance**
- Follows repository pattern
- Service layer separation
- DTO inheritance patterns
- Enhanced base controller usage

## 🚨 **Important Notes**

1. **Property Definitions**: Update the properties list in `DTOGenerator.tt` before generating
2. **Role Permissions**: Review and adjust authorization roles in generated controllers
3. **Entity Relationships**: Configure includes and filtering in the service after generation
4. **Business Logic**: Add entity-specific validation in the service hooks

## 🔧 **Troubleshooting**

- **Build Errors**: Ensure all namespaces are correctly referenced
- **T4 Issues**: Verify `dotnet-t4` tool is installed and accessible
- **Missing Dependencies**: Check that base classes exist in your projects
- **Authorization Issues**: Verify role names match your authentication setup 