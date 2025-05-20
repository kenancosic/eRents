# eRents Code Generator

This tool generates boilerplate code for the eRents application using T4 templates.

## Setup

1. Make sure you have the .NET SDK installed
2. Build the project: `dotnet build`

## Usage

Run the generator by specifying the entity name:

```bash
dotnet run -- Booking
```

This will generate:
- Controller class
- DTO classes (Request and Response)
- Service implementation

The generated files will be placed in the `Output` directory.

## Templates

The generator uses the following T4 templates:

- `ControllerGenerator.tt` - Creates a controller that inherits from BaseCRUDController
- `DTOGenerator.tt` - Creates request and response DTOs for the entity
- `ServiceGenerator.tt` - Creates a service implementation that inherits from BaseCRUDService

## Customizing Templates

To customize the generated code:

1. Edit the T4 templates (*.tt files) in the project root
2. Modify the property definitions in `DTOGenerator.tt` to match your entity
3. Customize filtering logic in `ServiceGenerator.tt`

## Adding New Templates

To add a new template:

1. Create a new .tt file in the project root
2. Add it to the project file in the `<ItemGroup>` section with the same attributes as existing templates
3. Update `Program.cs` to call the new template in the `Main` method 