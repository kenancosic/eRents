class Property {
  int id;
  String type;
  String address;
  int cityId;
  String zipCode;
  String description;
  double price;
  int ownerId;

  Property({
    required this.id,
    required this.type,
    required this.address,
    required this.cityId,
    required this.zipCode,
    this.description = '',
    required this.price,
    required this.ownerId,
  });
}
