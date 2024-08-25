class City {
  final int cityId;
  final String cityName;
  final int stateId;

  City({required this.cityId, required this.cityName, required this.stateId});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      cityId: json['cityId'],
      cityName: json['cityName'],
      stateId: json['stateId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cityId': cityId,
      'cityName': cityName,
      'stateId': stateId,
    };
  }
}
