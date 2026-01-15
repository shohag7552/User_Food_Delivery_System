import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

// Script to add sample banners to the database
// Run: dart lib/scripts/add_sample_banners.dart

void main() async {
  print("🎨 Adding Sample Banners...");

  final client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId)
      .setKey(AppwriteConfig.apiKey);

  final databases = Databases(client);

  final sampleBanners = [
    {
      'image_url': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
      'title': '50% OFF',
      'subtitle': 'On your first order',
      'action_type': 'none',
      'action_value': null,
      'is_active': true,
      'sort_order': 1,
    },
    {
      'image_url': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1',
      'title': 'Free Delivery',
      'subtitle': 'Orders above \$30',
      'action_type': 'none',
      'action_value': null,
      'is_active': true,
      'sort_order': 2,
    },
    {
      'image_url': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38',
      'title': 'Weekend Special',
      'subtitle': 'Get extra 20% off',
      'action_type': 'none',
      'action_value': null,
      'is_active': true,
      'sort_order': 3,
    },
    {
      'image_url': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
      'title': 'New Menu',
      'subtitle': 'Check out our latest dishes',
      'action_type': 'none',
      'action_value': null,
      'is_active': true,
      'sort_order': 4,
    },
  ];

  try {
    for (var banner in sampleBanners) {
      await databases.createDocument(
        databaseId: AppwriteConfig.dbId,
        collectionId: AppwriteConfig.bannersCollection,
        documentId: ID.unique(),
        data: banner,
      );
      print("✅ Added banner: ${banner['title']}");
    }
    print("\n🎉 Sample banners added successfully!");
  } catch (e) {
    print("❌ Error adding banners: $e");
  }
}
