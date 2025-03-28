import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  

  const RecipeCard({super.key, required this.recipe});

  Widget build(BuildContext context) {
    final String name = recipe['name'] as String? ?? 'Unnamed Recipe';

    return GestureDetector(
      onTap: () => _showRecipeDialog(context),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        elevation: 2.0,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  void _showRecipeDialog(BuildContext context) {
    final List<String> ingredients =
        (recipe['ingredient'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final List<String> amounts =
        (recipe['ingredient_amount'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final List<String> guide =
        (recipe['guide'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(recipe['name'] ?? "Recipe Details"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Ingredients Section ---
                Text(
                  "Ingredients",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                if (ingredients.isEmpty)
                  const Text("No ingredients listed.")
                else
                  ...List.generate(ingredients.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Text(
                        '• ${ingredients[i]}'
                        '${(amounts.length > i && amounts[i].isNotEmpty) ? ': ${amounts[i]}' : ''}',
                      ),
                    );
                  }),

                const SizedBox(height: 10),

                // --- Guide Section ---
                Text(
                  "Preparation Guide",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                if (guide.isEmpty)
                  const Text("No preparation steps available.")
                else
                  ...List.generate(guide.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Text('${i + 1}. ${guide[i]}'),
                    );
                  }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
