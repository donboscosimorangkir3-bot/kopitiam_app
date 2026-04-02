class CafeSettings {
  final String cafeName;
  final String cafeDescription;
  final String cafeOperationHours;
  final String cafePhone;
  final String cafeAddress;
  final String? cafeImage;

  CafeSettings({
    required this.cafeName,
    required this.cafeDescription,
    required this.cafeOperationHours,
    required this.cafePhone,
    required this.cafeAddress,
    this.cafeImage,
  });

  factory CafeSettings.fromJson(Map<String, dynamic> json) => CafeSettings(
    cafeName: json['cafe_name'] ?? '',
    cafeDescription: json['cafe_description'] ?? '',
    cafeOperationHours: json['cafe_operation_hours'] ?? '',
    cafePhone: json['cafe_phone'] ?? '',
    cafeAddress: json['cafe_address'] ?? '',
    cafeImage: json['cafe_image'],
  );

  Map<String, dynamic> toJson() => {
    'cafe_name': cafeName,
    'cafe_description': cafeDescription,
    'cafe_operation_hours': cafeOperationHours,
    'cafe_phone': cafePhone,
    'cafe_address': cafeAddress,
  };
}