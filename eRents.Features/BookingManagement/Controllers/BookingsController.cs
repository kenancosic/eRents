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
}