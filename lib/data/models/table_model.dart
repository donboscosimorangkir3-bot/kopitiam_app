class TableModel {
  final int id;
  final String number;
  final bool isAvailable;

  TableModel({required this.id, required this.number, required this.isAvailable});

  factory TableModel.fromJson(Map<String, dynamic> json) => TableModel(
    id: json['id'],
    number: json['number'],
    isAvailable: json['is_available'] == 1 || json['is_available'] == true,
  );
}