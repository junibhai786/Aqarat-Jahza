class Property {
  const Property({
    required this.id,
    required this.title,
    required this.price,
    required this.priceUnit,
    required this.region,
    required this.address,
    required this.kind,
    required this.type,
    required this.listingStatus,
    required this.badge,
    required this.isVerified,
    required this.area,
    required this.rooms,
    required this.baths,
    required this.floorName,
    required this.finishType,
    required this.images,
    required this.description,
    required this.whatsapp,
    required this.officeName,
    required this.views,
  });

  final int id;
  final String title;
  final num price;
  final String priceUnit;
  final String region;
  final String address;
  final String kind;
  final String type;
  final String listingStatus;
  final String badge;
  final bool isVerified;
  final num? area;
  final int? rooms;
  final int? baths;
  final String floorName;
  final String finishType;
  final List<String> images;
  final String description;
  final String whatsapp;
  final String officeName;
  final int views;
}
