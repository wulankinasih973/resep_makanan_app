import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/meal.dart';
import 'services/api_service.dart';

void main() {
  runApp(MealApp());
}

class MealApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'What You Wanna Eat Today?',
      theme: ThemeData(primarySwatch: Colors.green),
      home: MealListPage(),
    );
  }
}

// untuk menampilkan daftar resep
class MealListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Recipe (Seafood Only)'),
      ),
      // mengambil data dari API
      body: FutureBuilder<List<Meal>>(
        future: ApiService.fetchMeals(), // Panggil API melalui service
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final meals = snapshot.data!;
            // menampilkan data dalam bentuk Grid
            return GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: meals.length,
              itemBuilder: (context, index) {
                final meal = meals[index];
                return InkWell(
                  onTap: () {
                    // navigasi ke halaman detail saat item diklik
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MealDetailPage(mealId: meal.id),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.network(
                            meal.thumbnail,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            meal.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load the data.'));
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

// untuk menampilkan informasi lengkap resep
class MealDetailPage extends StatefulWidget {
  final String mealId;

  MealDetailPage({required this.mealId});

  @override
  _MealDetailPageState createState() => _MealDetailPageState();
}

class _MealDetailPageState extends State<MealDetailPage> {
  Map<String, dynamic>? mealDetail; // detail resep

  @override
  void initState() {
    super.initState();
    fetchMealDetail();
  }

  // untuk mengambil detail resep dari API
  Future<void> fetchMealDetail() async {
    final response = await http.get(Uri.parse(
      'https://www.themealdb.com/api/json/v1/1/lookup.php?i=${widget.mealId}',
    ));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        mealDetail = data['meals'][0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mealDetail == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Recipe Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // list bahan dan takaran dari field strIngredient dan strMeasure
    List<Widget> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = mealDetail!['strIngredient$i'];
      final measure = mealDetail!['strMeasure$i'];
      if (ingredient != null &&
          ingredient.toString().trim().isNotEmpty &&
          measure != null &&
          measure.toString().trim().isNotEmpty) {
        ingredients.add(Text('• $ingredient - $measure'));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(mealDetail!['strMeal'] ?? 'Detail')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(mealDetail!['strMealThumb']),
            SizedBox(height: 16),
            Text(
              mealDetail!['strMeal'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              "Category: ${mealDetail!['strCategory']}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              "Ingredients:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...ingredients, // menampilkan bahan + takaran
            SizedBox(height: 16),
            Text(
              "How to Make:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(mealDetail!['strInstructions'] ?? ''),
          ],
        ),
      ),
    );
  }
}
