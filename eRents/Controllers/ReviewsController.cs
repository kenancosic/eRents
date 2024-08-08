using eRents.Model.DTO.Requests;
using eRents.Model.DTO.Response;
using eRents.Model.SearchObjects;
using eRents.Services.Entities;
using eRents.Services.Service.ReviewService;
using Microsoft.AspNetCore.Mvc;

namespace eRents.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class ReviewsController : BaseCRUDController<ReviewsResponse, ReviewSearchObject, ReviewsInsertRequest, ReviewsUpdateRequest>
	{
		public ReviewsController(IReviewService service) : base(service) { }

		public override ReviewsResponse Insert([FromBody] ReviewsInsertRequest insert) => Insert(insert);
		public override ReviewsResponse Update(int id, [FromBody] ReviewsUpdateRequest update) => Update(id, update);
	}
}
