using System;
using System.IO;
using System.Diagnostics;
using System.Reflection;
using System.Text.RegularExpressions;

namespace eRents.CodeGen
{
    public class Program
    {
        static void Main(string[] args)
        {
            if (args.Length == 0 || args[0] == "--help" || args[0] == "-h")
            {
                PrintUsage();
                return;
            }

            string entityName = args[0];
            if (!IsValidCSharpIdentifier(entityName))
            {
                Console.WriteLine($"Error: Entity name '{entityName}' is not a valid C# identifier.");
                return;
            }
            
            Console.WriteLine($"--- Starting code generation for: {entityName} ---");

            try
            {
                string? solutionDirectory = GetSolutionDirectory();
                if (string.IsNullOrEmpty(solutionDirectory))
                {
                    Console.WriteLine("Error: Could not determine the solution directory. Make sure this tool is run from within the solution structure.");
                    return;
                }

                string codeGenProjectDirectory = Path.Combine(solutionDirectory, "eRents.CodeGen"); 

                // Define target base paths
                string sharedProjectPath = Path.Combine(solutionDirectory, "eRents.Shared");
                string applicationProjectPath = Path.Combine(solutionDirectory, "eRents.Application");
                string webapiProjectPath = Path.Combine(solutionDirectory, "eRents.WebApi");

                // --- DTO Generation ---
                string dtoOutputDirectory = Path.Combine(sharedProjectPath, "DTO");
                Directory.CreateDirectory(dtoOutputDirectory); // Ensure directory exists
                string dtoTemplateName = "DTOGenerator.tt";
                // Output DTOs (Requests, Response, SearchObjects) into a single file for simplicity of generation management
                // It's common to have them as separate files, but T4 typically generates one output file per template.
                // For multiple files from one template, more advanced T4 or a post-processing step would be needed.
                string dtoOutputFileName = $"{entityName}DTOs.cs"; 
                GenerateFromTemplate(dtoTemplateName, entityName, dtoOutputDirectory, dtoOutputFileName, codeGenProjectDirectory);

                // --- Service and Interface Generation ---
                string serviceDirectory = Path.Combine(applicationProjectPath, "Service", $"{entityName}Service");
                Directory.CreateDirectory(serviceDirectory); // Ensure directory exists
                string serviceTemplateName = "ServiceGenerator.tt";
                string serviceOutputFileName = $"{entityName}Service.cs";
                GenerateFromTemplate(serviceTemplateName, entityName, serviceDirectory, serviceOutputFileName, codeGenProjectDirectory);
                GenerateServiceInterface(entityName, serviceDirectory, applicationProjectPath);

                // --- Controller Generation ---
                string controllerOutputDirectory = Path.Combine(webapiProjectPath, "Controllers");
                Directory.CreateDirectory(controllerOutputDirectory); // Ensure directory exists
                string controllerTemplateName = "ControllerGenerator.tt";
                // Conventionally, controller names are plural (e.g., PropertiesController for Property entity)
                string controllerOutputFileName = $"{entityName}sController.cs"; 
                GenerateFromTemplate(controllerTemplateName, entityName, controllerOutputDirectory, controllerOutputFileName, codeGenProjectDirectory);

                Console.WriteLine("--- Code generation complete. ---");
                Console.WriteLine("Please check the respective project folders for the generated files:");
                Console.WriteLine($"  DTOs: {Path.Combine(dtoOutputDirectory, dtoOutputFileName)}");
                Console.WriteLine($"  Service Interface: {Path.Combine(serviceDirectory, $"I{entityName}Service.cs")}");
                Console.WriteLine($"  Service: {Path.Combine(serviceDirectory, serviceOutputFileName)}");
                Console.WriteLine($"  Controller: {Path.Combine(controllerOutputDirectory, controllerOutputFileName)}");
                Console.WriteLine("You may need to include these new files in your .csproj files if they aren't automatically picked up (especially for non-SDK style projects or if using specific ItemGroups).");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"An unexpected error occurred: {ex.Message}");
                Console.WriteLine(ex.StackTrace);
            }
        }

        static void PrintUsage()
        {
            Console.WriteLine("eRents Code Generator");
            Console.WriteLine("---------------------");
            Console.WriteLine("Usage: dotnet run --project eRents.CodeGen -- <EntityName>");
            Console.WriteLine("  <EntityName>  - The name of the entity (e.g., Property, User, Booking).");
            Console.WriteLine("                  Must be a valid C# class name, typically singular.");
            Console.WriteLine();
            Console.WriteLine("Example: dotnet run --project eRents.CodeGen -- Amenity");
            Console.WriteLine();
            Console.WriteLine("This tool will generate:");
            Console.WriteLine("  - DTO classes (InsertRequest, UpdateRequest, SearchObject, Response) in 'eRents.Shared/DTO/<EntityName>DTOs.cs'");
            Console.WriteLine("  - Service Interface 'I<EntityName>Service.cs' in 'eRents.Application/Service/<EntityName>Service/'");
            Console.WriteLine("  - Service Implementation '<EntityName>Service.cs' in 'eRents.Application/Service/<EntityName>Service/'");
            Console.WriteLine("  - API Controller '<EntityName>sController.cs' in 'eRents.WebApi/Controllers/'");
            Console.WriteLine();
            Console.WriteLine("Prerequisites:");
            Console.WriteLine("  - Ensure the 't4' command (from dotnet-t4 tool) is installed globally and accessible in your PATH.");
            Console.WriteLine("    Install using: dotnet tool install -g dotnet-t4");
            Console.WriteLine("  - Run this command from the solution root directory.");
        }

        static bool IsValidCSharpIdentifier(string identifier)
        {
            if (string.IsNullOrWhiteSpace(identifier)) return false;
            if (!char.IsLetter(identifier[0]) && identifier[0] != '_') return false;
            for (int i = 1; i < identifier.Length; i++)
            {
                if (!char.IsLetterOrDigit(identifier[i]) && identifier[i] != '_') return false;
            }
            // C# keywords are not exhaustively checked here but T4 generation would likely fail.
            // Common keywords that might be accidentally used for entity names:
            string[] keywords = { "class", "struct", "interface", "enum", "delegate", "event", "namespace", "using", "public", "private", "protected", "internal", "static", "readonly", "const", "volatile", "new", "override", "virtual", "abstract", "sealed", "params", "ref", "out", "in", "is", "as", "typeof", "sizeof", "default", "checked", "unchecked", "true", "false", "null" };
            if (Array.IndexOf(keywords, identifier.ToLowerInvariant()) >= 0) return false;
            return true;
        }

        static string? GetSolutionDirectory()
        {
            // Start from the directory of the currently executing assembly (eRents.CodeGen.dll)
            string? currentDirectory = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            // Navigate up: eRents.CodeGen/bin/Debug/netX.X -> eRents.CodeGen/bin/Debug -> eRents.CodeGen/bin -> eRents.CodeGen -> SolutionRoot
            int maxLevelsToSearch = 5; // Adjust if your build output is deeper or shallower
            for(int i=0; i < maxLevelsToSearch && currentDirectory != null; ++i)
            {
                if (Directory.GetFiles(currentDirectory, "*.sln").Length > 0)
                {
                    return currentDirectory;
                }
                currentDirectory = Directory.GetParent(currentDirectory)?.FullName;
            }
            // Fallback if .sln not found by navigating up (e.g. if run from an unexpected location)
            currentDirectory = Directory.GetCurrentDirectory();
             while (currentDirectory != null)
            {
                if (Directory.GetFiles(currentDirectory, "*.sln").Length > 0)
                {
                    return currentDirectory;
                }
                currentDirectory = Directory.GetParent(currentDirectory)?.FullName;
            }
            return null; 
        }

        static void GenerateServiceInterface(string entityName, string serviceDirectoryPath, string applicationProjectBasePath)
        {
            string interfaceName = $"I{entityName}Service";
            string interfaceFileName = Path.Combine(serviceDirectoryPath, $"{interfaceName}.cs");
            
            // Construct namespaces based on known project structure
            string serviceNamespace = $"eRents.Application.Service.{entityName}Service";
            string sharedDtoRequestsNamespace = "eRents.Shared.DTO.Requests";
            string sharedDtoResponseNamespace = "eRents.Shared.DTO.Response";
            // Assuming SearchObject is directly under DTO or in a specific SearchObjects folder based on DTOGenerator.tt output
            string sharedSearchObjectsNamespace = "eRents.Shared.DTO.Requests"; // Or eRents.Shared.DTO if DTOGenerator puts it there
            string applicationSharedNamespace = "eRents.Application.Shared";

            Console.WriteLine($"Generating Interface {interfaceName} in {interfaceFileName}...");

            // Ensure all DTOs (Request, Response, SearchObject) are referenced correctly
            string interfaceContent = $@"using {applicationSharedNamespace};
using {sharedDtoRequestsNamespace}; // For InsertRequest, UpdateRequest, SearchObject
using {sharedDtoResponseNamespace}; // For Response

namespace {serviceNamespace}
{{
    public interface {interfaceName} : ICRUDService<{entityName}Response, {entityName}SearchObject, {entityName}InsertRequest, {entityName}UpdateRequest>
    {{
        // Add any entity-specific methods here if needed in the future
        // Example: Task<IEnumerable<{entityName}Response>> GetActive{entityName}sAsync();
    }}
}}
";
            File.WriteAllText(interfaceFileName, interfaceContent);
            Console.WriteLine($"Generated: {interfaceFileName}");
        }

        static void GenerateFromTemplate(string templateFileName, string entityName, string outputDirectoryPath, string outputFileNameWithExtension, string codeGenProjectRootPath)
        {
            try
            {
                Console.WriteLine($"Processing template '{templateFileName}' for entity '{entityName}' -> '{Path.Combine(outputDirectoryPath, outputFileNameWithExtension)}'...");

                string templateFilePath = Path.Combine(codeGenProjectRootPath, templateFileName); 
                if (!File.Exists(templateFilePath))
                {
                    Console.WriteLine($"Error: Template file not found at '{templateFilePath}'. Make sure the eRents.CodeGen project is correctly located relative to the solution root.");
                    return;
                }

                string outputFilePath = Path.Combine(outputDirectoryPath, outputFileNameWithExtension);

                var processInfo = new ProcessStartInfo
                {
                    FileName = "t4", // Assumes 't4' (dotnet-t4 tool) is in the system PATH
                    Arguments = $"-o \"{outputFilePath}\" \"{templateFilePath}\" --entityName={entityName}",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    WorkingDirectory = codeGenProjectRootPath // Important if T4 templates use relative paths for includes
                };

                using (var process = Process.Start(processInfo))
                {
                    if (process != null)
                    {
                        // Read output/error streams. Avoids deadlocks on full pipes.
                        string stdout = process.StandardOutput.ReadToEnd(); 
                        string stderr = process.StandardError.ReadToEnd();
                        process.WaitForExit(30000); // Wait for 30 seconds

                        if (process.HasExited && process.ExitCode == 0)
                        {
                            Console.WriteLine($"Successfully generated: {outputFilePath}");
                            if (!string.IsNullOrWhiteSpace(stdout) && !(stdout.Contains("Build success") || stdout.Contains("Transforming template succeeded"))) Console.WriteLine($"  T4 Output: {stdout.Trim()}");
                            // Treat stderr as warnings if exit code is 0, as some T4 messages go to stderr
                            if (!string.IsNullOrWhiteSpace(stderr)) Console.WriteLine($"  T4 Info/Warnings: {stderr.Trim()}"); 
                        }
                        else
                        {
                            Console.WriteLine($"Error generating file from '{templateFileName}'. Process did not exit successfully or timed out.");
                            if (!process.HasExited) process.Kill(true); // Ensure process is killed if it timed out
                            Console.WriteLine($"  Exit Code: {(process.HasExited ? process.ExitCode.ToString() : "N/A (Killed)")}");
                            if (!string.IsNullOrWhiteSpace(stdout)) Console.WriteLine($"  T4 Output: {stdout.Trim()}");
                            if (!string.IsNullOrWhiteSpace(stderr)) Console.WriteLine($"  T4 Error: {stderr.Trim()}");
                        }
                    }
                    else
                    {
                        Console.WriteLine("Failed to start the t4 process. Ensure 't4' command (dotnet-t4 tool) is installed and in your PATH.");
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error processing template '{templateFileName}': {ex.Message}");
                Console.WriteLine(ex.StackTrace);
                Console.WriteLine("Ensure 't4' command (from dotnet-t4 tool) is installed globally or accessible in your PATH (e.g., via 'dotnet tool install -g dotnet-t4').");
            }
        }
    }
} 