import 'dart:developer';
import 'package:appwrite_user_app/app/models/category_model.dart';
import 'package:appwrite_user_app/app/modules/categories/domain/repository/category_repo_interface.dart';
import 'package:get/get.dart';

class CategoryController extends GetxController implements GetxService {
  final CategoryRepoInterface categoryRepoInterface;
  
  CategoryController({required this.categoryRepoInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> getCategories() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      update();

      _categories = await categoryRepoInterface.getCategories();
      log('====> Categories loaded: ${_categories.length}');
      
      _isLoading = false;
      update();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load categories: $e';
      log('====> Error loading categories: $e');
      update();
    }
  }

}
