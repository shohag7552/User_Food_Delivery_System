import 'package:appwrite_user_app/app/models/category_model.dart';
import 'package:image_picker/image_picker.dart';

abstract class CategoryRepoInterface {
  Future<List<CategoryModel>> getCategories();
}