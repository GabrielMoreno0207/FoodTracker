class FoodItem {
  int? id;
  String name;
  int calories;
  String time;

  FoodItem(
      {this.id,
      required this.name,
      required this.calories,
      required this.time});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'time': time,
    };
  }
}
