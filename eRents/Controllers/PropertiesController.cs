using eRents.Model.DTO.Requests;
using eRents.Model.DTO.Response;
using eRents.Model.SearchObjects;
using eRents.Services.Entities;
using eRents.Services.Service.PropertyService;
using Microsoft.AspNetCore.Mvc;

namespace eRents.Controllers
{
	[ApiController]
	[Route("[controller]")]
	public class PropertiesController : BaseCRUDController<PropertiesResponse, PropertiesSearchObject, PropertiesInsertRequest, PropertiesUpdateRequest>
	{
		public PropertiesController(IPropertiesService service) : base(service)
		{ }

		public override PropertiesResponse Insert([FromBody] PropertiesInsertRequest insert)
		{
			return base.Insert(insert);
		}

		public override PropertiesResponse Update(int id, [FromBody] PropertiesUpdateRequest update)
		{
			return base.Update(id, update);
		}

	}

}
