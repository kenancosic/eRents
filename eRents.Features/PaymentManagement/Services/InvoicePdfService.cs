using eRents.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace eRents.Features.PaymentManagement.Services;

/// <summary>
/// Service for generating invoice PDF documents using QuestPDF
/// </summary>
public class InvoicePdfService : IInvoicePdfService
{
    private readonly ERentsContext _context;
    private readonly ILogger<InvoicePdfService> _logger;

    public InvoicePdfService(ERentsContext context, ILogger<InvoicePdfService> logger)
    {
        _context = context;
        _logger = logger;
        
        // Configure QuestPDF license (Community license for open source)
        QuestPDF.Settings.License = LicenseType.Community;
    }

    public async Task<byte[]> GenerateInvoicePdfAsync(int paymentId)
    {
        var payment = await _context.Payments
            .Include(p => p.Tenant).ThenInclude(t => t!.User)
            .Include(p => p.Property).ThenInclude(pr => pr!.Owner)
            .Include(p => p.Property).ThenInclude(pr => pr!.Address)
            .FirstOrDefaultAsync(p => p.PaymentId == paymentId);

        if (payment == null)
            throw new KeyNotFoundException($"Payment with ID {paymentId} not found");

        var data = new InvoiceData
        {
            InvoiceNumber = payment.PaymentId,
            InvoiceDate = payment.CreatedAt,
            DueDate = payment.DueDate,
            
            TenantName = GetFullName(payment.Tenant?.User),
            TenantEmail = payment.Tenant?.User?.Email ?? string.Empty,
            TenantAddress = FormatAddress(payment.Tenant?.User),
            
            LandlordName = GetFullName(payment.Property?.Owner),
            LandlordEmail = payment.Property?.Owner?.Email,
            LandlordAddress = FormatAddress(payment.Property?.Owner),
            
            PropertyName = payment.Property?.Name ?? "Property",
            PropertyAddress = FormatPropertyAddress(payment.Property?.Address),
            
            Amount = payment.Amount,
            Currency = payment.Currency ?? "USD",
            PaymentStatus = payment.PaymentStatus ?? "Pending",
            PaymentType = payment.PaymentType,
            // Get period info from subscription or booking if available
            PeriodStart = GetDateTimeFromDateOnly(payment.Subscription?.StartDate) ?? GetDateTimeFromDateOnly(payment.Booking?.StartDate),
            PeriodEnd = GetDateTimeFromDateOnly(payment.Subscription?.EndDate) ?? GetDateTimeFromDateOnly(payment.Booking?.EndDate),
            DatePaid = payment.PaymentStatus == "Completed" ? payment.UpdatedAt : null,
            Description = payment.PaymentType == "SubscriptionPayment" ? "Monthly Rent Payment" : "Rental Payment"
        };

        return await GenerateInvoicePdfAsync(data);
    }

    public Task<byte[]> GenerateInvoicePdfAsync(InvoiceData data)
    {
        try
        {
            var document = Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(40);
                    page.DefaultTextStyle(x => x.FontSize(11));

                    page.Header().Element(c => ComposeHeader(c, data));
                    page.Content().Element(c => ComposeContent(c, data));
                    page.Footer().Element(ComposeFooter);
                });
            });

            var pdfBytes = document.GeneratePdf();
            _logger.LogInformation("Generated invoice PDF for invoice #{InvoiceNumber}", data.InvoiceNumber);
            return Task.FromResult(pdfBytes);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate invoice PDF for invoice #{InvoiceNumber}", data.InvoiceNumber);
            throw;
        }
    }

    private void ComposeHeader(IContainer container, InvoiceData data)
    {
        container.Row(row =>
        {
            row.RelativeItem().Column(column =>
            {
                column.Item().Text("eRents").FontSize(24).Bold().FontColor(Colors.Blue.Darken2);
                column.Item().Text("Property Rental Platform").FontSize(10).FontColor(Colors.Grey.Darken1);
            });

            row.RelativeItem().AlignRight().Column(column =>
            {
                column.Item().Text("INVOICE").FontSize(20).Bold().FontColor(Colors.Grey.Darken2);
                column.Item().Text($"#{data.InvoiceNumber}").FontSize(14);
                column.Item().Text($"Date: {data.InvoiceDate:MMM dd, yyyy}").FontSize(10);
                if (data.DueDate.HasValue)
                    column.Item().Text($"Due: {data.DueDate:MMM dd, yyyy}").FontSize(10);
            });
        });
    }

    private void ComposeContent(IContainer container, InvoiceData data)
    {
        container.PaddingVertical(20).Column(column =>
        {
            // Bill To / From section
            column.Item().Row(row =>
            {
                row.RelativeItem().Column(col =>
                {
                    col.Item().Text("BILL TO:").Bold().FontSize(10).FontColor(Colors.Grey.Darken1);
                    col.Item().Text(data.TenantName).Bold();
                    if (!string.IsNullOrEmpty(data.TenantEmail))
                        col.Item().Text(data.TenantEmail).FontSize(10);
                    if (!string.IsNullOrEmpty(data.TenantAddress))
                        col.Item().Text(data.TenantAddress).FontSize(10);
                });

                row.RelativeItem().Column(col =>
                {
                    col.Item().Text("FROM:").Bold().FontSize(10).FontColor(Colors.Grey.Darken1);
                    col.Item().Text(data.LandlordName).Bold();
                    if (!string.IsNullOrEmpty(data.LandlordEmail))
                        col.Item().Text(data.LandlordEmail).FontSize(10);
                    if (!string.IsNullOrEmpty(data.LandlordAddress))
                        col.Item().Text(data.LandlordAddress).FontSize(10);
                });
            });

            column.Item().PaddingVertical(15).LineHorizontal(1).LineColor(Colors.Grey.Lighten2);

            // Property info
            column.Item().Text("PROPERTY").Bold().FontSize(10).FontColor(Colors.Grey.Darken1);
            column.Item().Text(data.PropertyName).Bold();
            if (!string.IsNullOrEmpty(data.PropertyAddress))
                column.Item().Text(data.PropertyAddress).FontSize(10);

            column.Item().PaddingVertical(15).LineHorizontal(1).LineColor(Colors.Grey.Lighten2);

            // Invoice details table
            column.Item().Table(table =>
            {
                table.ColumnsDefinition(columns =>
                {
                    columns.RelativeColumn(3);
                    columns.RelativeColumn(2);
                    columns.RelativeColumn(2);
                });

                // Header row
                table.Header(header =>
                {
                    header.Cell().Background(Colors.Grey.Lighten3).Padding(8).Text("Description").Bold();
                    header.Cell().Background(Colors.Grey.Lighten3).Padding(8).Text("Period").Bold();
                    header.Cell().Background(Colors.Grey.Lighten3).Padding(8).AlignRight().Text("Amount").Bold();
                });

                // Data row
                var description = data.Description ?? data.PaymentType ?? "Rental Payment";
                var period = (data.PeriodStart.HasValue && data.PeriodEnd.HasValue)
                    ? $"{data.PeriodStart:MMM dd} - {data.PeriodEnd:MMM dd, yyyy}"
                    : "N/A";
                var amount = $"{data.Currency} {data.Amount:N2}";

                table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten2).Padding(8).Text(description);
                table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten2).Padding(8).Text(period);
                table.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten2).Padding(8).AlignRight().Text(amount);
            });

            column.Item().PaddingTop(10).Row(row =>
            {
                row.RelativeItem();
                row.ConstantItem(200).Column(col =>
                {
                    col.Item().Row(r =>
                    {
                        r.RelativeItem().Text("Subtotal:").Bold();
                        r.RelativeItem().AlignRight().Text($"{data.Currency} {data.Amount:N2}");
                    });
                    col.Item().PaddingVertical(5).LineHorizontal(1).LineColor(Colors.Grey.Lighten2);
                    col.Item().Row(r =>
                    {
                        r.RelativeItem().Text("TOTAL:").Bold().FontSize(14);
                        r.RelativeItem().AlignRight().Text($"{data.Currency} {data.Amount:N2}").Bold().FontSize(14);
                    });
                });
            });

            // Payment status
            column.Item().PaddingTop(20).Row(row =>
            {
                var statusColor = data.PaymentStatus?.ToLower() switch
                {
                    "completed" or "paid" => Colors.Green.Darken1,
                    "pending" => Colors.Orange.Darken1,
                    "failed" => Colors.Red.Darken1,
                    _ => Colors.Grey.Darken1
                };

                row.RelativeItem();
                row.ConstantItem(150).Background(statusColor).Padding(10).AlignCenter()
                    .Text($"STATUS: {data.PaymentStatus?.ToUpper() ?? "PENDING"}")
                    .FontColor(Colors.White).Bold();
            });

            if (data.DatePaid.HasValue)
            {
                column.Item().PaddingTop(10).AlignRight()
                    .Text($"Paid on: {data.DatePaid:MMM dd, yyyy}").FontSize(10).FontColor(Colors.Grey.Darken1);
            }
        });
    }

    private void ComposeFooter(IContainer container)
    {
        container.AlignCenter().Column(column =>
        {
            column.Item().PaddingTop(10).LineHorizontal(1).LineColor(Colors.Grey.Lighten2);
            column.Item().PaddingTop(10).Text("Thank you for using eRents!")
                .FontSize(10).FontColor(Colors.Grey.Darken1);
            column.Item().Text("This invoice was generated automatically.")
                .FontSize(8).FontColor(Colors.Grey.Lighten1);
        });
    }

    private static string GetFullName(User? user)
    {
        if (user == null) return "Unknown";
        var name = $"{user.FirstName} {user.LastName}".Trim();
        return string.IsNullOrEmpty(name) ? user.Username ?? "Unknown" : name;
    }

    private static string? FormatAddress(User? user)
    {
        if (user?.Address == null) return null;
        var address = user.Address;
        var parts = new List<string>();
        if (!string.IsNullOrEmpty(address.StreetLine1)) parts.Add(address.StreetLine1);
        if (!string.IsNullOrEmpty(address.City)) parts.Add(address.City);
        if (!string.IsNullOrEmpty(address.Country)) parts.Add(address.Country);
        return parts.Count > 0 ? string.Join(", ", parts) : null;
    }

    private static string? FormatPropertyAddress(Address? address)
    {
        if (address == null) return null;
        var parts = new List<string>();
        if (!string.IsNullOrEmpty(address.StreetLine1)) parts.Add(address.StreetLine1);
        if (!string.IsNullOrEmpty(address.City)) parts.Add(address.City);
        if (!string.IsNullOrEmpty(address.Country)) parts.Add(address.Country);
        if (!string.IsNullOrEmpty(address.PostalCode)) parts.Add(address.PostalCode);
        return parts.Count > 0 ? string.Join(", ", parts) : null;
    }

    private static DateTime? GetDateTimeFromDateOnly(DateOnly? date)
    {
        return date?.ToDateTime(TimeOnly.MinValue);
    }
}
