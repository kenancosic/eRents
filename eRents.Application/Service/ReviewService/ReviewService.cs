//using AutoMapper;
//using eRents.Model.DTO.Requests;
//using eRents.Model.DTO.Response;
//using eRents.Model.SearchObjects;
//using eRents.Services.Entities;
//using eRents.Services.Service.PropertyService;
//using eRents.Services.Shared;
//using Microsoft.EntityFrameworkCore;
//using System;
//using System.Collections.Generic;
//using System.Linq;
//using System.Text;
//using System.Threading.Tasks;

//namespace eRents.Application.Service.ReviewService
//{
//	public class ReviewService : BaseCRUDService<ReviewsResponse, Review, ReviewSearchObject, ReviewsInsertRequest, ReviewsUpdateRequest>, IReviewService
//	{
//		public ReviewService(ERentsContext context, IMapper mapper) : base(context, mapper)
//		{

//		}

//		public ReviewsResponse GetReviewsByUsername(string username)
//		{
//			var result = _context.Reviews.Include(x => x.User).Where(x => x.User.Username == username).ToList();
//			if (result == null)
//				return null;
//			return _mapper.Map<ReviewsResponse>(result);
//		}


//	}
//}
