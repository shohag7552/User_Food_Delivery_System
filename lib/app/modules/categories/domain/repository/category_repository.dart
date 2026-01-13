import 'dart:developer';

import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:appwrite_user_app/app/appwrite/appwrite_service.dart';
import 'package:appwrite_user_app/app/models/category_model.dart';
import 'package:appwrite_user_app/app/modules/categories/domain/repository/category_repo_interface.dart';
import 'package:image_picker/image_picker.dart';


class CategoryRepository implements CategoryRepoInterface {
  final AppwriteService appwriteService;

  CategoryRepository({required this.appwriteService});

  @override
  Future<List<CategoryModel>> getCategories() async{
    final response = await appwriteService.listTable(tableId: AppwriteConfig.categoriesCollection);
    return response.rows.map((post) {
      print('===> Category Data: ${post.data}');
      return CategoryModel.fromJson(post.data);
    }).toList();
  }

}