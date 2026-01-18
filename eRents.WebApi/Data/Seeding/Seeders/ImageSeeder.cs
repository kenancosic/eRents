using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace eRents.WebApi.Data.Seeding.Seeders
{
    /// <summary>
    /// Seeds minimal property images. Adds a single cover image for first few properties
    /// that don't already have images. Uses small in-memory placeholder bytes.
    /// </summary>
    public class ImageSeeder : IDataSeeder
    {
        public int Order => 35; // after PropertiesSeeder (30), before Bookings/Reviews
        public string Name => nameof(ImageSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (!forceSeed)
            {
                // If at least some images exist, skip to remain minimal
                var anyImages = await context.Images.AnyAsync(i => i.PropertyId != null);
                if (anyImages)
                {
                    logger?.LogInformation("[{Seeder}] Skipped (already present)", Name);
                    return;
                }
            }

            if (forceSeed)
            {
                await context.Images.IgnoreQueryFilters().ExecuteDeleteAsync();
            }

            // Take first 3-5 properties and ensure 1 cover image each
            var properties = await context.Properties
                .AsNoTracking()
                .OrderBy(p => p.PropertyId)
                .Select(p => new { p.PropertyId, p.Name })
                .Take(5)
                .ToListAsync();

            if (properties.Count == 0)
            {
                logger?.LogWarning("[{Seeder}] No properties found. Ensure PropertiesSeeder ran.", Name);
                return;
            }

            var imagesToAdd = new List<Image>();
            var seedImagesPath = Path.Combine(Directory.GetCurrentDirectory(), "SeedImages");
            var propertyImagesPath = Path.Combine(seedImagesPath, "Properties");
            var maintenanceImagesPath = Path.Combine(seedImagesPath, "Maintenance");
            
            var propertyImages = Directory.Exists(propertyImagesPath) ? 
                Directory.GetFiles(propertyImagesPath, "*.jpg").Concat(Directory.GetFiles(propertyImagesPath, "*.png")).ToArray() : 
                Array.Empty<string>();
            var maintenanceImages = Directory.Exists(maintenanceImagesPath) ? 
                Directory.GetFiles(maintenanceImagesPath, "*.jpg")
                    .Concat(Directory.GetFiles(maintenanceImagesPath, "*.png"))
                    .ToArray() : 
                Array.Empty<string>();
            
            logger?.LogInformation("[{Seeder}] Found {PropCount} property images, {MaintCount} maintenance images", 
                Name, propertyImages.Length, maintenanceImages.Length);

            // Add property image galleries: up to 3 images for first 4 properties (first image as cover)
            int perProperty = 3;
            int propertyCount = Math.Min(properties.Count, 4);
            for (int i = 0; i < propertyCount; i++)
            {
                var p = properties[i];
                var existingCount = await context.Images.CountAsync(img => img.PropertyId == p.PropertyId);
                if (existingCount > 0) continue; // idempotent: skip if images already exist for this property

                // Use actual images if available, otherwise generate placeholders
                if (propertyImages.Length > 0)
                {
                    int startIndex = i * perProperty;
                    for (int k = 0; k < perProperty && (startIndex + k) < propertyImages.Length; k++)
                    {
                        var imagePath = propertyImages[startIndex + k];
                        var imageData = await File.ReadAllBytesAsync(imagePath);
                        var contentType = imagePath.EndsWith(".png", StringComparison.OrdinalIgnoreCase) ? "image/png" : "image/jpeg";

                        imagesToAdd.Add(new Image
                        {
                            PropertyId = p.PropertyId,
                            ImageData = imageData,
                            ContentType = contentType,
                            FileName = Path.GetFileName(imagePath),
                            DateUploaded = DateTime.UtcNow,
                            IsCover = (k == 0)
                        });
                    }
                }
                else
                {
                    // Generate placeholder PNG images when no actual images exist
                    for (int k = 0; k < perProperty; k++)
                    {
                        var placeholderPng = GeneratePlaceholderPng(p.Name, k + 1);
                        imagesToAdd.Add(new Image
                        {
                            PropertyId = p.PropertyId,
                            ImageData = placeholderPng,
                            ContentType = "image/png",
                            FileName = $"property_{p.PropertyId}_image_{k + 1}.png",
                            DateUploaded = DateTime.UtcNow,
                            IsCover = (k == 0)
                        });
                    }
                }
            }

            // Add maintenance issue images
            var maintenanceIssues = await context.MaintenanceIssues
                .AsNoTracking()
                .OrderBy(mi => mi.MaintenanceIssueId)
                .Take(2)
                .ToListAsync();
            for (int i = 0; i < Math.Min(maintenanceIssues.Count, maintenanceImages.Length); i++)
            {
                var issue = maintenanceIssues[i];
                var hasImages = await context.Images.AnyAsync(img => img.MaintenanceIssueId == issue.MaintenanceIssueId);
                if (hasImages) continue;

                var imagePath = maintenanceImages[i];
                var imageData = await File.ReadAllBytesAsync(imagePath);
                var contentType = "image/jpeg"; // All maintenance images are jpg

                imagesToAdd.Add(new Image
                {
                    MaintenanceIssueId = issue.MaintenanceIssueId,
                    ImageData = imageData,
                    ContentType = contentType,
                    FileName = Path.GetFileName(imagePath),
                    DateUploaded = DateTime.UtcNow
                });
            }

            if (imagesToAdd.Count > 0)
            {
                await context.Images.AddRangeAsync(imagesToAdd);
                await context.SaveChangesAsync();
            }

            logger?.LogInformation("[{Seeder}] Done. Added {Count} cover images.", Name, imagesToAdd.Count);
        }

        /// <summary>
        /// Generates a minimal valid PNG placeholder image (1x1 pixel with color based on property)
        /// </summary>
        private static byte[] GeneratePlaceholderPng(string propertyName, int imageNumber)
        {
            // Different colors for variety (RGB values)
            var colors = new (byte R, byte G, byte B)[] 
            { 
                (99, 102, 241),   // indigo
                (139, 92, 246),   // purple
                (236, 72, 153),   // pink
                (20, 184, 166),   // teal
                (245, 158, 11),   // amber
                (239, 68, 68)     // red
            };
            var colorIndex = Math.Abs((propertyName.GetHashCode() + imageNumber) % colors.Length);
            var (r, g, b) = colors[colorIndex];

            // Generate a minimal valid PNG (1x1 pixel)
            // PNG structure: signature + IHDR chunk + IDAT chunk + IEND chunk
            using var ms = new MemoryStream();
            
            // PNG signature
            ms.Write(new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }, 0, 8);
            
            // IHDR chunk (image header): 1x1 pixel, 8-bit RGB
            WriteChunk(ms, "IHDR", new byte[] { 
                0, 0, 0, 1,  // width = 1
                0, 0, 0, 1,  // height = 1
                8,           // bit depth = 8
                2,           // color type = 2 (RGB)
                0,           // compression method
                0,           // filter method
                0            // interlace method
            });
            
            // IDAT chunk (image data): compressed pixel data
            // Raw data: filter byte (0) + RGB values, then deflate compressed
            var rawData = new byte[] { 0, r, g, b }; // filter byte + RGB
            var compressedData = DeflateCompress(rawData);
            WriteChunk(ms, "IDAT", compressedData);
            
            // IEND chunk (image end)
            WriteChunk(ms, "IEND", Array.Empty<byte>());
            
            return ms.ToArray();
        }

        private static void WriteChunk(MemoryStream ms, string type, byte[] data)
        {
            // Length (4 bytes, big-endian)
            var length = BitConverter.GetBytes(data.Length);
            if (BitConverter.IsLittleEndian) Array.Reverse(length);
            ms.Write(length, 0, 4);
            
            // Type (4 bytes ASCII)
            var typeBytes = System.Text.Encoding.ASCII.GetBytes(type);
            ms.Write(typeBytes, 0, 4);
            
            // Data
            if (data.Length > 0) ms.Write(data, 0, data.Length);
            
            // CRC32 of type + data
            var crcData = new byte[4 + data.Length];
            Array.Copy(typeBytes, 0, crcData, 0, 4);
            if (data.Length > 0) Array.Copy(data, 0, crcData, 4, data.Length);
            var crc = Crc32(crcData);
            var crcBytes = BitConverter.GetBytes(crc);
            if (BitConverter.IsLittleEndian) Array.Reverse(crcBytes);
            ms.Write(crcBytes, 0, 4);
        }

        private static byte[] DeflateCompress(byte[] data)
        {
            using var output = new MemoryStream();
            using (var deflate = new System.IO.Compression.DeflateStream(output, System.IO.Compression.CompressionLevel.Optimal, true))
            {
                deflate.Write(data, 0, data.Length);
            }
            
            // Wrap in zlib format: header (78 9C) + deflate data + adler32 checksum
            var deflated = output.ToArray();
            var result = new byte[2 + deflated.Length + 4];
            result[0] = 0x78; // zlib header
            result[1] = 0x9C;
            Array.Copy(deflated, 0, result, 2, deflated.Length);
            
            var adler = Adler32(data);
            var adlerBytes = BitConverter.GetBytes(adler);
            if (BitConverter.IsLittleEndian) Array.Reverse(adlerBytes);
            Array.Copy(adlerBytes, 0, result, 2 + deflated.Length, 4);
            
            return result;
        }

        private static uint Crc32(byte[] data)
        {
            uint crc = 0xFFFFFFFF;
            foreach (var b in data)
            {
                crc ^= b;
                for (int i = 0; i < 8; i++)
                    crc = (crc >> 1) ^ (0xEDB88320 & ~((crc & 1) - 1));
            }
            return ~crc;
        }

        private static uint Adler32(byte[] data)
        {
            uint a = 1, b = 0;
            foreach (var d in data)
            {
                a = (a + d) % 65521;
                b = (b + a) % 65521;
            }
            return (b << 16) | a;
        }
    }
}
