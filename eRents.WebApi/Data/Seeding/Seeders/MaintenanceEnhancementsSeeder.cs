using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using eRents.Domain.Models;
using eRents.Domain.Models.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.WebApi.Data.Seeding.Seeders
{
    /// <summary>
    /// Enhances existing maintenance issues with assignments, resolution data, and extra images.
    /// </summary>
    public class MaintenanceEnhancementsSeeder : IDataSeeder
    {
        public int Order => 62; // After MaintenanceIssuesSeeder (60) and before Messages/Notifications
        public string Name => nameof(MaintenanceEnhancementsSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            // Load a couple of issues
            var issues = await context.MaintenanceIssues
                .OrderBy(i => i.MaintenanceIssueId)
                .Take(3)
                .ToListAsync();

            if (issues.Count == 0)
            {
                logger?.LogInformation("[{Seeder}] No maintenance issues found; skipping.", Name);
                return;
            }

            // Get assignable users
            var desktop = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "desktop");
            var ownerZenica = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == "owner_zenica");

            int updates = 0;
            if (issues.Count > 0)
            {
                var first = issues[0];
                if (forceSeed || first.Status != MaintenanceIssueStatusEnum.Completed || first.Cost == null)
                {
                    first.AssignedToUserId = desktop?.UserId;
                    first.Status = MaintenanceIssueStatusEnum.Completed;
                    first.Cost = 45.00m;
                    first.ResolutionNotes = "Zamijenjena brtva i zategnuta slavina. Problem riješen.";
                    first.ResolvedAt = DateTime.UtcNow.AddDays(-2);
                    updates++;
                }
            }

            if (issues.Count > 1)
            {
                var second = issues[1];
                if (forceSeed || second.Status == MaintenanceIssueStatusEnum.Pending || second.AssignedToUserId == null)
                {
                    second.AssignedToUserId = ownerZenica?.UserId ?? desktop?.UserId;
                    second.Status = MaintenanceIssueStatusEnum.InProgress;
                    second.ResolutionNotes = "U toku je nabavka rezervnih dijelova.";
                    updates++;
                }
            }

            // Attach placeholder images to maintenance issues that don't have any
            var allIssues = await context.MaintenanceIssues.ToListAsync();
            int imagesAdded = 0;
            
            foreach (var issue in allIssues)
            {
                bool hasAny = await context.Images.AnyAsync(i => i.MaintenanceIssueId == issue.MaintenanceIssueId);
                if (!hasAny || forceSeed)
                {
                    // Generate a simple placeholder PNG image (1x1 pixel colored based on priority)
                    var placeholderImage = GeneratePlaceholderPng(issue.Priority);
                    
                    var img = new Image
                    {
                        MaintenanceIssueId = issue.MaintenanceIssueId,
                        ImageData = placeholderImage,
                        ContentType = "image/png",
                        FileName = $"maintenance_{issue.MaintenanceIssueId}_photo.png",
                        DateUploaded = DateTime.UtcNow.AddDays(-Random.Shared.Next(1, 30))
                    };
                    await context.Images.AddAsync(img);
                    imagesAdded++;
                    updates++;
                }
            }
            
            if (imagesAdded > 0)
            {
                logger?.LogInformation("[{Seeder}] Added {ImageCount} placeholder images to maintenance issues.", Name, imagesAdded);
            }

            if (updates > 0)
            {
                await context.SaveChangesAsync();
            }

            logger?.LogInformation("[{Seeder}] Done. Enhanced {Count} maintenance items.", Name, updates);
        }

        /// <summary>
        /// Generates a 400x300 PNG placeholder image with a color based on priority.
        /// Uses a minimal valid PNG structure - larger size for better visibility.
        /// </summary>
        private static byte[] GeneratePlaceholderPng(MaintenanceIssuePriorityEnum priority)
        {
            // Color based on priority (RGB) - using gradients for better appearance
            byte r, g, b;
            switch (priority)
            {
                case MaintenanceIssuePriorityEnum.Low:
                    r = 76; g = 175; b = 80; // Green
                    break;
                case MaintenanceIssuePriorityEnum.Medium:
                    r = 255; g = 193; b = 7; // Amber/Yellow
                    break;
                case MaintenanceIssuePriorityEnum.High:
                    r = 255; g = 152; b = 0; // Orange
                    break;
                case MaintenanceIssuePriorityEnum.Emergency:
                    r = 244; g = 67; b = 54; // Red
                    break;
                default:
                    r = 158; g = 158; b = 158; // Grey
                    break;
            }

            // Generate a larger PNG (400x300 pixels) for better visibility
            const int width = 400;
            const int height = 300;
            
            using var ms = new MemoryStream();
            using var bw = new BinaryWriter(ms);

            // PNG Signature
            bw.Write(new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A });

            // IHDR chunk (image header)
            WriteChunk(bw, "IHDR", GetIHDRData(width, height));

            // IDAT chunk (image data - compressed) with gradient effect
            WriteChunk(bw, "IDAT", GetIDATDataWithGradient(width, height, r, g, b));

            // IEND chunk (image end)
            WriteChunk(bw, "IEND", Array.Empty<byte>());

            return ms.ToArray();
        }

        private static byte[] GetIHDRData(int width, int height)
        {
            using var ms = new MemoryStream();
            using var bw = new BinaryWriter(ms);
            bw.Write(ToBigEndian(width));
            bw.Write(ToBigEndian(height));
            bw.Write((byte)8);  // Bit depth
            bw.Write((byte)2);  // Color type (RGB)
            bw.Write((byte)0);  // Compression method
            bw.Write((byte)0);  // Filter method
            bw.Write((byte)0);  // Interlace method
            return ms.ToArray();
        }

        private static byte[] GetIDATDataWithGradient(int width, int height, byte r, byte g, byte b)
        {
            // Create raw image data with vertical gradient effect
            var rawData = new byte[height * (1 + width * 3)];
            int idx = 0;
            for (int y = 0; y < height; y++)
            {
                rawData[idx++] = 0; // Filter type: None
                // Create gradient effect - darker at top, lighter at bottom
                float factor = 0.7f + (0.3f * y / height);
                byte gr = (byte)Math.Min(255, r * factor);
                byte gg = (byte)Math.Min(255, g * factor);
                byte gb = (byte)Math.Min(255, b * factor);
                
                for (int x = 0; x < width; x++)
                {
                    rawData[idx++] = gr;
                    rawData[idx++] = gg;
                    rawData[idx++] = gb;
                }
            }

            // Compress with zlib (deflate)
            using var output = new MemoryStream();
            output.WriteByte(0x78); // zlib header
            output.WriteByte(0x9C); // zlib header

            using (var deflate = new System.IO.Compression.DeflateStream(output, System.IO.Compression.CompressionLevel.Fastest, true))
            {
                deflate.Write(rawData, 0, rawData.Length);
            }

            // Adler-32 checksum
            uint adler = Adler32(rawData);
            output.Write(ToBigEndian((int)adler), 0, 4);

            return output.ToArray();
        }

        private static void WriteChunk(BinaryWriter bw, string type, byte[] data)
        {
            bw.Write(ToBigEndian(data.Length));
            var typeBytes = System.Text.Encoding.ASCII.GetBytes(type);
            bw.Write(typeBytes);
            bw.Write(data);

            // CRC32 of type + data
            var crcData = new byte[typeBytes.Length + data.Length];
            Array.Copy(typeBytes, 0, crcData, 0, typeBytes.Length);
            Array.Copy(data, 0, crcData, typeBytes.Length, data.Length);
            bw.Write(ToBigEndian((int)Crc32(crcData)));
        }

        private static byte[] ToBigEndian(int value)
        {
            var bytes = BitConverter.GetBytes(value);
            if (BitConverter.IsLittleEndian) Array.Reverse(bytes);
            return bytes;
        }

        private static uint Crc32(byte[] data)
        {
            uint crc = 0xFFFFFFFF;
            foreach (byte b in data)
            {
                crc ^= b;
                for (int i = 0; i < 8; i++)
                    crc = (crc >> 1) ^ (0xEDB88320 * (crc & 1));
            }
            return crc ^ 0xFFFFFFFF;
        }

        private static uint Adler32(byte[] data)
        {
            uint a = 1, b = 0;
            foreach (byte c in data)
            {
                a = (a + c) % 65521;
                b = (b + a) % 65521;
            }
            return (b << 16) | a;
        }
    }
}
