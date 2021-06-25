import 'package:flutter/material.dart';
import 'package:foodshare/helpers/utils.dart';
import 'package:foodshare/models/category.dart';
import 'package:foodshare/services/categoryselectionservice.dart';
import 'package:foodshare/services/categoryservice.dart';
import 'package:foodshare/widgets/categorycard.dart';
import 'package:provider/provider.dart';

class CategoryListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    CategorySelectionService catSelection =
        Provider.of<CategorySelectionService>(context, listen: false);
    CategoryService catService =
        Provider.of<CategoryService>(context, listen: false);
    List<Category> categories = catService.getCategories();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Text('Select a category:',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.black)),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: categories.length,
          itemBuilder: (BuildContext ctx, int index) {
            return CategoryCard(
                category: categories[index],
                onCardClick: () {
                  catSelection.selectedCategory = categories[index];
                  Utils.mainAppNav.currentState!
                      .pushNamed('/selectedcategorypage');
                });
          },
        ),
      )
    ]);
  }
}
