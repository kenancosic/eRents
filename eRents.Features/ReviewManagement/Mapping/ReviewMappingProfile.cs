using AutoMapper;
using eRents.Domain.Models;
using eRents.Features.ReviewManagement.Models;

namespace eRents.Features.ReviewManagement.Mapping;

public sealed class ReviewMappingProfile : Profile
{
    public ReviewMappingProfile()
    {
        // Entity -> Response (RepliesCount left for service to populate)
        CreateMap<Review, ReviewResponse>()
            .ForMember(d => d.RepliesCount, o => o.Ignore())
            .ForMember(d => d.ReviewerFirstName, o => o.MapFrom(s => s.Reviewer != null ? s.Reviewer.FirstName : null))
            .ForMember(d => d.ReviewerLastName, o => o.MapFrom(s => s.Reviewer != null ? s.Reviewer.LastName : null));

        // Request -> Entity (ignore identity/audit)
        CreateMap<ReviewRequest, Review>()
            .ForMember(d => d.ReviewId, o => o.Ignore())
            .ForMember(d => d.CreatedAt, o => o.Ignore())
            .ForMember(d => d.CreatedBy, o => o.Ignore())
            .ForMember(d => d.UpdatedAt, o => o.Ignore())
            .AfterMap((src, dest) =>
            {
                // Preserve semantics from Mapster AfterMapping (placeholders for normalization if needed)
                if (src.ParentReviewId.HasValue)
                {
                    // Replies: leave StarRating as provided (may be null).
                }
                else
                {
                    // Originals: validator/service enforce rating semantics.
                }
            });
    }
}
