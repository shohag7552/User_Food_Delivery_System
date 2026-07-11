import 'dart:developer';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:appwrite_user_app/app/models/category_model.dart';
import 'package:appwrite_user_app/app/modules/categories/domain/repository/category_repo_interface.dart';
import 'package:image_picker/image_picker.dart';


class CategoryRepository implements CategoryRepoInterface {
  final AppwriteService appwriteService;

  CategoryRepository({required this.appwriteService});

  @override
  Future<List<CategoryModel>> getCategories() async{
    final response = await appwriteService.listTable(
      tableId: AppwriteConfig.categoriesCollection,
      queries: [Query.equal('module_type', ModuleController.current)],
    );
    return response.rows.map((post) {
      print('===> Category Data: ${post.data}');
      return CategoryModel.fromJson(post.data);
    }).toList();
  }

  @override
  Future<CategoryModel?> getCategoryById(String id) async {
    try {
      final response = await appwriteService.getDocument(
        tableId: AppwriteConfig.categoriesCollection,
        rowId: id,
      );
      return CategoryModel.fromJson(response.data);
    } catch (e) {
      log('====> Error fetching category by ID: $e');
      return null;
    }
  }
}