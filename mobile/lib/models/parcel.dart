class Parcel {
  final int id;
  final String name;
  final String location;
  final String soilType;
  final int ownerId;

  Parcel({
    required this.id,
    required this.name,
    required this.location,
    required this.soilType,
    required this.ownerId,
  });

  factory Parcel.fromJson(Map<String, dynamic> json) {
    return Parcel(
      id: json['id'] as int,
      name: json['name'] as String,
      location: json['location'] as String,
      soilType: json['soil_type'] as String,
      ownerId: json['owner_id'] as int,
    );
  }
}
