using AutoMapper;
using eRents.Application.Shared;
using eRents.Domain.Models;
using eRents.Domain.Repositories;
using eRents.Shared.DTO.Requests;
using eRents.Shared.DTO.Response;
using eRents.Shared.SearchObjects;
using Microsoft.EntityFrameworkCore;
using Microsoft.ML;
using Microsoft.ML.Data;
using Microsoft.ML.Trainers;

namespace eRents.Application.Service
{
	public class PropertyService : BaseCRUDService<PropertyResponse, Property, PropertySearchObject, PropertyInsertRequest, PropertyUpdateRequest>, IPropertyService
	{
		private readonly IPropertyRepository _propertyRepository;

		private static MLContext _mlContext = null;
		private static ITransformer _model = null;
		private static object _lock = new object();
		public PropertyService(IPropertyRepository propertyRepository, IMapper mapper) : base(propertyRepository, mapper)
		{
			_propertyRepository = propertyRepository;
		}

		public override async Task<IEnumerable<PropertyResponse>> GetAsync(PropertySearchObject search)
		{
			var properties = await base.GetAsync(search);

			foreach (var property in properties)
			{
				var propertyEntity = await _propertyRepository.GetByIdAsync(property.PropertyId);
				property.AverageRating = await _propertyRepository.GetAverageRatingAsync(property.PropertyId);
				property.Images = propertyEntity.Images.Select(i => new ImageResponse
				{
					ImageId = i.ImageId,
					FileName = i.FileName ?? $"Untitled (${i.ImageId})",
					ImageData = i.ImageData,
					DateUploaded = i.DateUploaded ?? DateTime.Now
				}).ToList();
			}

			return properties;
		}
		protected override IQueryable<Property> AddInclude(IQueryable<Property> query, PropertySearchObject search = null)
		{
			return query.Include(p => p.Images);  // Include images in the query
		}

		public override async Task<PropertyResponse> GetByIdAsync(int propertyId)
		{
			var property = await base.GetByIdAsync(propertyId);
			if (property == null) return null;

			// AutoMapper handles the rest
			var propertyResponse = _mapper.Map<PropertyResponse>(property);

			return propertyResponse;
		}


		public async Task<decimal> GetTotalRevenueAsync(int propertyId)
		{
			return await _propertyRepository.GetTotalRevenueAsync(propertyId);
		}

		public async Task<int> GetNumberOfBookingsAsync(int propertyId)
		{
			return await _propertyRepository.GetNumberOfBookingsAsync(propertyId);
		}

		public async Task<int> GetNumberOfTenantsAsync(int propertyId)
		{
			return await _propertyRepository.GetNumberOfTenantsAsync(propertyId);
		}

		public async Task<decimal> GetAverageRatingAsync(int propertyId)
		{
			return await _propertyRepository.GetAverageRatingAsync(propertyId);
		}

		public async Task<int> GetNumberOfReviewsAsync(int propertyId)
		{
			return await _propertyRepository.GetNumberOfReviewsAsync(propertyId);
		}

		public async Task<IEnumerable<AmenityResponse>> GetAmenitiesByIdsAsync(IEnumerable<int> amenityIds)
		{
			var amenities = await _propertyRepository.GetAmenitiesByIdsAsync(amenityIds);
			return _mapper.Map<IEnumerable<AmenityResponse>>(amenities);
		}

		protected override async Task BeforeInsertAsync(PropertyInsertRequest insert, Property entity)
		{
			if (insert.AmenityIds != null && insert.AmenityIds.Any())
			{
				var amenities = await _propertyRepository.GetAmenitiesByIdsAsync(insert.AmenityIds);
				entity.Amenities = amenities.ToList();
			}

			await base.BeforeInsertAsync(insert, entity);
		}

		protected override IQueryable<Property> AddFilter(IQueryable<Property> query, PropertySearchObject search = null)
		{
			query = base.AddFilter(query, search);

			if (search?.Latitude.HasValue == true && search?.Longitude.HasValue == true && search?.Radius.HasValue == true)
			{
				decimal radiusInDegrees = search.Radius.HasValue ? search.Radius.Value / 111 : 10; // Convert km to degrees (approximate)

				query = query.Where(p =>
						p.AddressDetail != null && // Ensure AddressDetail is not null
						p.AddressDetail.Latitude.HasValue && p.AddressDetail.Longitude.HasValue && // Ensure coordinates are available
						(p.AddressDetail.Latitude.Value - search.Latitude.Value) * (p.AddressDetail.Latitude.Value - search.Latitude.Value) +
						(p.AddressDetail.Longitude.Value - search.Longitude.Value) * (p.AddressDetail.Longitude.Value - search.Longitude.Value) <= radiusInDegrees * radiusInDegrees);
			}

			if (!string.IsNullOrEmpty(search.SortBy))
			{
				switch (search.SortBy.ToLower())
				{
					case "rating":
						query = query.OrderByDescending(p => p.Reviews.Average(r => r.StarRating));
						break;
					case "distance":
						if (search.Latitude.HasValue && search.Longitude.HasValue)
						{
							query = query.OrderBy(p =>
									p.AddressDetail != null && p.AddressDetail.Latitude.HasValue && p.AddressDetail.Longitude.HasValue ? // Check for nulls before calculating distance
									((p.AddressDetail.Latitude.Value - search.Latitude.Value) * (p.AddressDetail.Latitude.Value - search.Latitude.Value) +
									(p.AddressDetail.Longitude.Value - search.Longitude.Value) * (p.AddressDetail.Longitude.Value - search.Longitude.Value))
									: decimal.MaxValue // Properties without location data go to the end
									);
						}
						break;
					default:
						query = query.OrderBy(p => p.Name); // Default sorting
						break;
				}
			}

			return query;
		}

		public async Task<bool> SavePropertyAsync(int propertyId, int userId)
		{
			var property = await _propertyRepository.GetByIdAsync(propertyId);
			if (property == null)
				return false;

			// Logic to save the property for the user
			// This could involve adding an entry in a UserProperties table or similar

			return true;
		}

		public async Task<List<PropertyResponse>> RecommendPropertiesAsync(int userId)
		{
			List<PropertyEntry> data = null;

			// Lock block only for initializing _mlContext and training the model
			lock (_lock)
			{
				if (_mlContext == null)
				{
					_mlContext = new MLContext();
				}
			}

			// Fetch the ratings data outside the lock statement
			data = (await _propertyRepository.GetAllRatings())
					.Select(r => new PropertyEntry
					{
						PropertyId = (uint)r.PropertyId,
						//UserId = (uint)r.TenantId, // Use TenantId as the user ID
						Label = r.StarRating.HasValue ? (float)r.StarRating.Value : 0f
					})
					.ToList();

			if (data.Count == 0)
			{
				return new List<PropertyResponse>(); // Return empty if no data
			}

			var trainData = _mlContext.Data.LoadFromEnumerable(data);

			var options = new MatrixFactorizationTrainer.Options
			{
				MatrixColumnIndexColumnName = nameof(PropertyEntry.PropertyId),
				MatrixRowIndexColumnName = nameof(PropertyEntry.UserId),
				LabelColumnName = "Label",
				NumberOfIterations = 20,
				ApproximationRank = 100
			};

			var estimator = _mlContext.Recommendation().Trainers.MatrixFactorization(options);
			_model = estimator.Fit(trainData);

			var properties = await _propertyRepository.GetQueryable().ToListAsync();
			var predictionResults = new List<Tuple<Property, float>>();

			foreach (var property in properties)
			{
				var predictionEngine = _mlContext.Model.CreatePredictionEngine<PropertyEntry, PropertyRatingPrediction>(_model);
				var prediction = predictionEngine.Predict(new PropertyEntry
				{
					UserId = (uint)userId,
					PropertyId = (uint)property.PropertyId
				});

				predictionResults.Add(new Tuple<Property, float>(property, prediction.Score));
			}

			var recommendedProperties = predictionResults
					.OrderByDescending(x => x.Item2)
					.Select(x => x.Item1)
					.Take(5)
					.ToList();

			return _mapper.Map<List<PropertyResponse>>(recommendedProperties);
		}


	}
	public class PropertyRatingPrediction
	{
		public float Score { get; set; }
	}

	public class PropertyEntry
	{
		[KeyType(100)]
		public uint UserId { get; set; }

		[KeyType(100)]
		public uint PropertyId { get; set; }

		public float Label { get; set; }
	}


}