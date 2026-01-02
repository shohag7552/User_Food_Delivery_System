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

  @override
  Future<bool> addCategories({required String name, required String description, List<XFile>? images}) async {
    List<String> imageUrls = [];
    log('===> Images length: ${images?.length}');
    if(images != null)  {
      for(XFile image in images) {
        log('===> Image path: ${image.path}');
        String? url = await appwriteService.uploadImage(image);
        if(url != null) {
          imageUrls.add(url);
        }
      }
    }
    final data = {
      'name': name,
      'description': description,
      'image_path': imageUrls.first,
    };
    // try {
      await appwriteService.createRow(
        collectionId: AppwriteConfig.categoriesCollection,
        data: data,
      );
      return true;
    // } catch (e) {
    //   log('Failed to create category: $e');
    //   return false;
    // }
  }

  @override
  Future<CategoryModel?> updateCategories({required String id, required String? name, required String? description, List<XFile>? images}) async {
    try {
      Map<String, dynamic> data = {
        '\$updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null && name.isNotEmpty) data['name'] = name;
      if (description != null && description.isNotEmpty) data['description'] = description;
      if (images != null && images.isNotEmpty) {
        List<String> imageUrls = [];
        for(XFile image in images) {
          log('===> Image path: ${image.path}');
          String? url = await appwriteService.uploadImage(image);
          if(url != null) {
            imageUrls.add(url);
          }
        }
        data['image_path'] = imageUrls.first;
      }

      final response = await appwriteService.updateTable(
        tableId: AppwriteConfig.categoriesCollection,
        rowId: id,
        data: data,
      );

      return CategoryModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  @override
  Future<bool> deleteCategory(String id) async {
    try {
      await appwriteService.deleteRow(
        collectionId: AppwriteConfig.categoriesCollection,
        rowId: id,
      );
      getCategories();
      return true;
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }
}