import '../models/property.dart';
import '../models/image_model.dart';

class MockProperties {
  static Property getSingleProperty(int id) {
    return Property(
      propertyId: id,
      ownerId: 1,
      name: 'Luxury Apartment with Sea View',
      price: 2500.00,
      description: 'Beautiful apartment with modern amenities, '
          'featuring floor-to-ceiling windows and a spacious balcony. '
          'Perfect for those who love ocean views and beach lifestyle.',
      averageRating: 4.8,
      images: List.generate(
          15,
          (index) => ImageModel(
                imageId: index + 1,
                fileName: index.isEven
                    ? 'assets/images/house.jpg'
                    : 'assets/images/appartment.jpg',
                imageData:
                    null, // Using null since ByteData isn't the right type
                dateUploaded: DateTime.now(),
              )),
    );
  }

  static List<Property> getAllProperties() {
    return List.generate(
      10,
      (index) => getSingleProperty(index + 1),
    );
  }
}
