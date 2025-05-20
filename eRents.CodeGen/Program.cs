using System;
using System.IO;
using System.Diagnostics;
using System.Reflection;

namespace eRents.CodeGen
{
    public class Program
    {
        static void Main(string[] args)
        {
            if (args.Length == 0)
            {
                Console.WriteLine("Usage: dotnet run -- <EntityName>");
                Console.WriteLine("Example: dotnet run -- Booking");
                return;
            }

            string entityName = args[0];
            Console.WriteLine($"Generating code for entity: {entityName}");
            
            // Get the directory where the assembly is located
            string assemblyLocation = Assembly.GetExecutingAssembly().Location;
            string assemblyDirectory = Path.GetDirectoryName(assemblyLocation) ?? string.Empty;
            
            // Templates are in the main project directory, not bin/Debug
            string projectDirectory = Directory.GetParent(assemblyDirectory)?.Parent?.Parent?.FullName ?? string.Empty;
            
            // Ensure output directory exists
            string outputDirectory = Path.Combine(projectDirectory, "Output");
            Directory.CreateDirectory(outputDirectory);
            
            GenerateFromTemplate("ControllerGenerator.tt", entityName, outputDirectory);
            GenerateFromTemplate("DTOGenerator.tt", entityName, outputDirectory);
            GenerateFromTemplate("ServiceGenerator.tt", entityName, outputDirectory);
            
            Console.WriteLine($"Code generation complete. Check the output at: {outputDirectory}");
        }
        
        static void GenerateFromTemplate(string templateName, string entityName, string outputDirectory)
        {
            try
            {
                // Run a .NET process to transform the template
                // This is a simplified approach; a real implementation would use the T4 API
                // but that requires more complex setup
                
                Console.WriteLine($"Processing {templateName} for {entityName}...");

                // For a real implementation, you would:
                // 1. Load the template content
                // 2. Replace parameters (like entityName)
                // 3. Process the T4 template
                // 4. Save the output file
                
                // For now, we're just creating a placeholder
                string outputFileName = Path.Combine(outputDirectory, 
                    $"{entityName}{Path.GetFileNameWithoutExtension(templateName).Replace("Generator", "")}.cs");
                
                File.WriteAllText(outputFileName, 
                    $"// This would be the output of {templateName} for entity {entityName}\n" +
                    $"// In a real implementation, the T4 template would be processed here.");
                
                Console.WriteLine($"Generated: {outputFileName}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error processing template {templateName}: {ex.Message}");
            }
        }
    }
} 