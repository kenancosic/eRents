using eRents.Model.DTO.Requests;
using eRents.Model.DTO.Response;
using eRents.Model.SearchObjects;
using eRents.Services.Entities;
using eRents.Services.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Application.Service.ReviewService
{
	public interface IReviewService : ICRUDService<ReviewsResponse, ReviewSearchObject, ReviewsInsertRequest, ReviewsUpdateRequest>
	{
		ReviewsResponse GetReviewsByUsername(string username);
	}
}
