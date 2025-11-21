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
    public async Task<ActionResult<BookingResponse>> Cancel(int id, [FromBody] CancelBookingRequest request)
    {
        if (_service is not Services.BookingService bookingService)
        {
            return StatusCode(500, "Service is not of expected type.");
        }

        try
        {
            var result = await bookingService.CancelBooking(id, request);
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

    [HttpPost("{id}/approve")]
    public async Task<ActionResult<BookingResponse>> Approve(int id)
    {
        if (_service is not Services.BookingService bookingService)
        {
            return StatusCode(500, "Service is not of expected type.");
        }

        try
        {
            var result = await bookingService.ApproveBookingAsync(id);
            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error approving booking with ID {Id}", id);
            return StatusCode(500, "An error occurred while processing your request.");
        }
    }

    [HttpPost("{id}/extend")]
    public async Task<ActionResult<BookingResponse>> Extend(int id, [FromBody] BookingExtensionRequest request)
    {
        if (_service is not Services.BookingService bookingService)
        {
            return StatusCode(500, "Service is not of expected type.");
        }

        try
        {
            var result = await bookingService.ExtendBookingAsync(id, request);
            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error extending booking with ID {Id}", id);
            return StatusCode(500, "An error occurred while processing your request.");
        }
    }
}