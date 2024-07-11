import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charts_flutter/flutter.dart' as charts;

void main() {
  runApp(FoodTrackerApp());
}

class FoodItem {
  final String name;
  final int calories;
  final String time;

  FoodItem({required this.name, required this.calories, required this.time});
}

class FoodTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Tracker',
      theme: ThemeData(
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          headline6: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          subtitle1: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal),
          bodyText1: TextStyle(fontSize: 14.0, fontStyle: FontStyle.italic),
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green)
            .copyWith(secondary: Colors.orangeAccent),
      ),
      home: FoodTrackerHomePage(),
    );
  }
}

class FoodTrackerHomePage extends StatefulWidget {
  @override
  _FoodTrackerHomePageState createState() => _FoodTrackerHomePageState();
}

class _FoodTrackerHomePageState extends State<FoodTrackerHomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  List<FoodItem> _foodItems = [];
  Map<String, int> _caloriesByDay = {};

  @override
  void initState() {
    super.initState();
    _loadCaloriesByDay();
  }

  Future<void> _loadCaloriesByDay() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, int> caloriesByDay = {};
    List<String>? days = prefs.getStringList('days');
    if (days != null) {
      for (String day in days) {
        int? calories = prefs.getInt(day);
        if (calories != null) {
          caloriesByDay[day] = calories;
        }
      }
    }
    setState(() {
      _caloriesByDay = caloriesByDay;
    });
  }

  Future<void> _addFood() async {
    final name = _nameController.text;
    final calories = int.tryParse(_caloriesController.text) ?? 0;
    final time = _timeController.text;

    if (name.isEmpty || calories <= 0 || time.isEmpty) {
      return;
    }

    FoodItem food = FoodItem(name: name, calories: calories, time: time);

    setState(() {
      _foodItems.add(food);
    });

    _nameController.clear();
    _caloriesController.clear();
    _timeController.clear();
  }

  Future<void> _saveCaloriesByDay(String day) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(day, _calculateTotalCalories());
    List<String>? days = prefs.getStringList('days');
    if (days == null) {
      days = [];
    }
    if (!days.contains(day)) {
      days.add(day);
      await prefs.setStringList('days', days);
    }
    await _loadCaloriesByDay();
    _clearFoods();
  }

  int _calculateTotalCalories() {
    return _foodItems.fold(0, (sum, item) => sum + item.calories);
  }

  void _clearFoods() {
    setState(() {
      _foodItems.clear();
    });
  }

  void _finalizeDay() {
    DateTime now = DateTime.now();
    String day = '${now.day}/${now.month}/${now.year}';
    _saveCaloriesByDay(day);
  }

  void _viewHistory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Histórico de Consumo'),
          content: SingleChildScrollView(
            child: ListBody(
              children: _caloriesByDay.keys.map((day) {
                return ListTile(
                  title: Text('$day - ${_caloriesByDay[day]} cal'),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _viewStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StatisticsPage(_caloriesByDay)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: _viewHistory,
          ),
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: _viewStatistics,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputFields(),
            SizedBox(height: 20),
            _buildAddButton(),
            SizedBox(height: 20),
            Expanded(
              child: _buildFoodList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _finalizeDay,
        tooltip: 'Finalizar Dia',
        child: Icon(Icons.done),
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nome do Alimento',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _caloriesController,
          decoration: InputDecoration(
            labelText: 'Calorias',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 10),
        TextField(
          controller: _timeController,
          decoration: InputDecoration(
            labelText: 'Horário',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton(
      onPressed: _addFood,
      child: Text('Adicionar Alimento'),
    );
  }

  Widget _buildFoodList() {
    return ListView.builder(
      itemCount: _foodItems.length,
      itemBuilder: (context, index) {
        final food = _foodItems[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(
              '${food.name}',
              style: Theme.of(context).textTheme.headline6,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${food.calories} cal',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                Text(
                  food.time,
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StatisticsPage extends StatelessWidget {
  final Map<String, int> _caloriesByDay;

  StatisticsPage(this._caloriesByDay);

  @override
  Widget build(BuildContext context) {
    List<charts.Series<CaloriesData, String>> series = [
      charts.Series(
        id: 'Calories',
        data: _caloriesByDay.entries
            .map((entry) => CaloriesData(entry.key, entry.value))
            .toList(),
        domainFn: (CaloriesData data, _) => data.day,
        measureFn: (CaloriesData data, _) => data.calories,
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      )
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Estatísticas de Consumo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Calorias Consumidas por Dia',
              style: Theme.of(context).textTheme.headline6,
            ),
            Expanded(
              child: charts.BarChart(series, animate: true),
            ),
          ],
        ),
      ),
    );
  }
}

class CaloriesData {
  final String day;
  final int calories;

  CaloriesData(this.day, this.calories);
}
