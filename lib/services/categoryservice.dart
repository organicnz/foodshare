import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodshare/models/category.dart';
import 'package:foodshare/models/categorypart.dart';
import 'package:foodshare/models/subcategory.dart';

class CategoryService {
  FirebaseFirestore? _instance;

  List<Category> _categories = [];

  List<Category> getCategories() {
    return _categories;
  }

  Future<void> getCategoriesCollectionFromFirebase() async {
    _instance = FirebaseFirestore.instance;
    CollectionReference categories =
        _instance!.collection('orilla_fresca_data');

    assert(FirebaseAuth.instance.currentUser != null,
        "User must be signed in before they can read from Firestore");
    DocumentSnapshot snapshot = await categories.doc('categories').get();
    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      var categoriesData = data['categories'] as List<dynamic>;
      categoriesData.forEach((catData) {
        Category cat = Category.fromJson(catData);
        _categories.add(cat);
      });
    }
  }

  void resetCategoriesToDefaults() {
    if (_categories.length > 0) {
      _categories.forEach((Category cat) {
        cat.subCategories!.forEach((Category subCat) {
          (subCat as SubCategory).parts.forEach((CategoryPart part) {
            part.isSelected = false;
          });

          // ignore: unnecessary_cast
          (subCat as SubCategory).amount = 0;
        });
      });
    }
  }
}
