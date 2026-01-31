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
    /// Seeds property images by distributing available images across all properties.
    /// Assigns 2-3 random images per property from SeedImages/Properties folder.
    /// Generates placeholder PNGs when no actual images are available.
    /// Runs at Order 35, after PropertiesSeeder (30) and before Bookings/Reviews.
    /// </summary>
    public class PropertyImagesSeeder : IDataSeeder
    {
        public int Order => 35;
        public string Name => nameof(PropertyImagesSeeder);

        public async Task SeedAsync(ERentsContext context, ILogger logger, bool forceSeed = false)
        {
            logger?.LogInformation("[{Seeder}] Starting...", Name);

            if (!forceSeed)
            {
                // If at least some property images exist, skip to remain minimal
                var anyImages = await context.Images.AnyAsync(i => i.PropertyId != null);
                if (anyImages)
                {
                    logger?.LogInformation("[{Seeder}] Skipped (already present)", Name);
                    return;
                }
            }

            if (forceSeed)
            {
                await context.Images.IgnoreQueryFilters()
                    .Where(i => i.PropertyId != null)
                    .ExecuteDeleteAsync();
            }

            var imagesToAdd = new List<Image>();
            var seedImagesPath = Path.Combine(Directory.GetCurrentDirectory(), "SeedImages");
            var propertyImagesPath = Path.Combine(seedImagesPath, "Properties");
            
            var propertyImages = Directory.Exists(propertyImagesPath) ? 
                Directory.GetFiles(propertyImagesPath, "*.jpg")
                    .Concat(Directory.GetFiles(propertyImagesPath, "*.jpeg"))
                    .Concat(Directory.GetFiles(propertyImagesPath, "*.png"))
                    .ToArray() : 
                Array.Empty<string>();
            
            logger?.LogInformation("[{Seeder}] Found {PropCount} property images", 
                Name, propertyImages.Length);

            // Get all properties to distribute images across
            var allProperties = await context.Properties
                .AsNoTracking()
                .OrderBy(p => p.PropertyId)
                .Select(p => new { p.PropertyId, p.Name })
                .ToListAsync();

            if (allProperties.Count == 0)
            {
                logger?.LogWarning("[{Seeder}] No properties found. Ensure PropertiesSeeder ran.", Name);
                return;
            }

            // Calculate how many images per property (2-3 random images)
            int imagesPerProperty = propertyImages.Length > 0 ? 
                Math.Max(1, propertyImages.Length / allProperties.Count) : 3;
            imagesPerProperty = Math.Min(imagesPerProperty, 3); // Cap at 3 per property
            imagesPerProperty = Math.Max(imagesPerProperty, 2); // Minimum 2 per property

            logger?.LogInformation("[{Seeder}] Distributing images across {PropCount} properties ({PerProp} per property)", 
                Name, allProperties.Count, imagesPerProperty);

            for (int i = 0; i < allProperties.Count; i++)
            {
                var p = allProperties[i];
                var existingCount = await context.Images.CountAsync(img => img.PropertyId == p.PropertyId);
                if (existingCount > 0) continue; // idempotent: skip if images already exist for this property

                // Use actual images if available, otherwise generate placeholders
                if (propertyImages.Length > 0)
                {
                    // Randomly select images for this property (with replacement allowed)
                    var random = new Random(p.PropertyId); // Seed with property ID for consistency
                    for (int k = 0; k < imagesPerProperty; k++)
                    {
                        var imageIndex = random.Next(propertyImages.Length);
                        var imagePath = propertyImages[imageIndex];
                        var imageData = await File.ReadAllBytesAsync(imagePath);
                        var contentType = imagePath.EndsWith(".png", StringComparison.OrdinalIgnoreCase) ? "image/png" : "image/jpeg";

                        imagesToAdd.Add(new Image
                        {
                            PropertyId = p.PropertyId,
                            ImageData = imageData,
                            ContentType = contentType,
                            FileName = Path.GetFileName(imagePath),
                            DateUploaded = DateTime.UtcNow,
                            IsCover = (k == 0) // First image for each property is the cover
                        });
                    }
                }
                else
                {
                    // Generate placeholder PNG images when no actual images exist
                    for (int k = 0; k < imagesPerProperty; k++)
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

            if (imagesToAdd.Count > 0)
            {
                await context.Images.AddRangeAsync(imagesToAdd);
                await context.SaveChangesAsync();
            }

            logger?.LogInformation("[{Seeder}] Done. Added {Count} property images.", Name, imagesToAdd.Count);
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
