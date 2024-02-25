using eRents.Model.Requests;
using eRents.Model.Response;
using eRents.Model.SearchObjects;
using eRents.Services.Database;
using eRents.Services.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eRents.Services.Service.ReviewService
{
    public interface IReviewService : ICRUDService<ReviewsResponse, ReviewSearchObject, ReviewsInsertRequest, ReviewsUpdateRequest>
    {
        ReviewsResponse GetReviewsByUsername(string username);
    }
}
