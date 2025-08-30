using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.BookingManagement.Models;
using eRents.Features.Core;

namespace eRents.Features.BookingManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
public class BookingsController : CrudController<eRents.Domain.Models.Booking, BookingRequest, BookingResponse, BookingSearch>
{
    public BookingsController(
        ICrudService<eRents.Domain.Models.Booking, BookingRequest, BookingResponse, BookingSearch> service,
        ILogger<BookingsController> logger)
        : base(service, logger)
    {
    }

    [HttpPost("{id}/cancel")]
    public async Task<ActionResult<BookingResponse>> Cancel(int id)
    {
        if (_service is not Services.BookingService bookingService)
        {
            return StatusCode(500, "Service is not of expected type.");
        }

        try
        {
            var result = await bookingService.CancelBooking(id);
            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error cancelling booking with ID {Id}", id);
            return StatusCode(500, "An error occurred while processing your request.");
        }
    }
}