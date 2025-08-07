using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using eRents.Features.PaymentManagement.Models;
using eRents.Features.Core.Controllers;
using eRents.Features.Core.Interfaces;

namespace eRents.Features.PaymentManagement.Controllers;

[Route("api/[controller]")]
[ApiController]
public class PaymentsController : CrudController<eRents.Domain.Models.Payment, PaymentRequest, PaymentResponse, PaymentSearch>
{
    public PaymentsController(
        ICrudService<eRents.Domain.Models.Payment, PaymentRequest, PaymentResponse, PaymentSearch> service,
        ILogger<PaymentsController> logger)
        : base(service, logger)
    {
    }
}