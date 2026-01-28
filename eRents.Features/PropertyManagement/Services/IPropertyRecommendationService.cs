using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using eRents.Features.PropertyManagement.Models;

namespace eRents.Features.PropertyManagement.Services
{
	public interface IPropertyRecommendationService
	{
		Task<List<PropertyRecommendation>> GetRecommendationsAsync(int userId, int count = 10);
		Task<List<PropertyRecommendation>> GetSimilarPropertiesAsync(int userId, int propertyId, int count = 4);
		Task TrainModelAsync();
		Task<float> GetPredictionAsync(int userId, int propertyId);
	}
}
