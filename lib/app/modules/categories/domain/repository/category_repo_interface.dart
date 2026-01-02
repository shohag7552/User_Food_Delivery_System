import 'package:appwrite_user_app/app/models/category_model.dart';
import 'package:image_picker/image_picker.dart';

abstract class CategoryRepoInterface {
  Future<List<CategoryModel>> getCategories();
  Future<bool> addCategories({required String name, required String description, List<XFile>? images});
  Future<CategoryModel?> updateCategories({required String id, required String name, required String description, List<XFile>? images});
  Future<bool> deleteCategory(String id);
}