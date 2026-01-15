
// --- CONFIGURATION ---

import 'package:appwrite_user_app/app/appwrite/appwrite_config.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/enums.dart';

// --- Run the script ---
// dart lib/scripts/seed_database.dart

void main() async {
  print("🚀 Starting Database Setup...");

  final client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId)
      .setKey(AppwriteConfig.apiKey);

  final databases = Databases(client);

  // Setup Admin Account & Team
  await _setupAdminAccount(client);

  try {
    // 1. Create Database
    try {
      await databases.get(databaseId: AppwriteConfig.dbId);
      print("✅ Database '${AppwriteConfig.dbId}' already exists.");
    } catch (e) {
      await databases.create(databaseId: AppwriteConfig.dbId, name: 'Food Delivery DB');
      print("✅ Created Database: ${AppwriteConfig.dbId}");
    }

    // 2. Create Collections & Attributes
    await _setupUsers(databases);
    // await _setupStoreProfile(databases);
    await _setupCategories(databases);
    await _setupProducts(databases);
    await _setupOrders(databases);
    await _setupAddresses(databases);
    await _setupCoupons(databases);
    await _setupBusinessSetup(databases);
    await _setupStoreSetup(databases);
    await _setupBanners(databases);

    print("\n🎉 SETUP COMPLETE! Your Appwrite backend is ready.");
  } catch (e) {
    print("❌ Critical Error: $e");
  }
}

// --- HELPER TO CREATE COLLECTION ---
Future<void> _createCollection(Databases db, String id, String name, List<Function> attributes, List<String> permissions) async {
  try {
    await db.getCollection(databaseId: AppwriteConfig.dbId, collectionId: id);
    print("🔹 Collection '$name' exists. Checking attributes...");
  } catch (e) {
    await db.createCollection(
      databaseId: AppwriteConfig.dbId,
      collectionId: id,
      name: name,
      permissions: permissions,
      documentSecurity: true,
    );
    print("✅ Created Collection: $name");
  }

  // Create Attributes (Ignore if already exists)
  for (var createAttr in attributes) {
    try {
      await createAttr();
      // Small delay to prevent race conditions in Appwrite Cloud
      await Future.delayed(Duration(milliseconds: 200));
    } catch (e) {
      // Ignore "Attribute already exists" error
      if (!e.toString().contains('409')) {
        print("   ⚠️ Error adding attribute: $e");
      }
    }
  }
}

// --- DEFINING SPECIFIC SCHEMAS ---

Future<void> _setupUsers(Databases db) async {
  await _createCollection(db, AppwriteConfig.usersCollection, 'Users', [
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.usersCollection, key: 'name', size: 128, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.usersCollection, key: 'email', size: 128, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.usersCollection, key: 'phone', size: 20, xrequired: true),
        () => db.createEnumAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.usersCollection, key: 'role', elements: ['customer', 'driver', 'manager', 'admin'], xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.usersCollection, key: 'fcm_token', size: 255, xrequired: false),
        () => db.createFloatAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.usersCollection, key: 'wallet_balance', xrequired: false, xdefault: 0.0),
        () => db.createBooleanAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.usersCollection, key: 'is_active', xrequired: false, xdefault: true),
  ], [
    Permission.read(Role.users()),
    Permission.create(Role.users()),      // Any logged-in user can add
    Permission.update(Role.users()), // Users can update their own addresses
    Permission.delete(Role.users()), // Users can delete their own addresses// Everyone can see
    Permission.read(Role.team('admin_team')), // Only 'admin' team can edit
  ]);
}

// Future<void> _setupStoreProfile(Databases db) async {
//   await _createCollection(db, AppwriteConfig.storeProfile, 'Store Profile', [
//         () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeProfile, key: 'currency_symbol', size: 10, xrequired: true),
//         () => db.createFloatAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeProfile, key: 'delivery_fee_per_km', xrequired: true),
//         () => db.createFloatAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeProfile, key: 'min_delivery_fee', xrequired: true),
//         () => db.createFloatAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeProfile, key: 'free_delivery_above', xrequired: false),
//         () => db.createIntegerAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeProfile, key: 'max_delivery_radius', xrequired: true), // in meters
//         () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeProfile, key: 'store_location', size: 1000, xrequired: true), // JSON string
//         () => db.createBooleanAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeProfile, key: 'is_store_open', xrequired: false, xdefault: true),
//   ], [
//     Permission.read(Role.any()),          // Everyone can see
//     Permission.create(Role.team('admin_team')),
//     Permission.read(Role.team('admin_team')),
//     Permission.update(Role.team('admin_team')),
//     Permission.delete(Role.team('admin_team')),
//   ]);
// }

Future<void> _setupBusinessSetup(Databases db) async {
  await _createCollection(db, AppwriteConfig.businessSetup, 'Business Setup', [
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.businessSetup, key: 'currency_symbol', size: 10, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.businessSetup, key: 'business_hours', size: 2000, xrequired: false),
        () => db.createFloatAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.businessSetup, key: 'delivery_fee_per_km', xrequired: true),
        () => db.createFloatAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.businessSetup, key: 'min_delivery_fee', xrequired: true),
        () => db.createFloatAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.businessSetup, key: 'free_delivery_above', xrequired: false),
        () => db.createFloatAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.businessSetup, key: 'max_delivery_radius', xrequired: true), // in meters
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.businessSetup, key: 'store_location', size: 1000, xrequired: true), // JSON string
        () => db.createBooleanAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.businessSetup, key: 'is_store_open', xdefault: true, xrequired: false),
        () => db.createBooleanAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.businessSetup, key: 'is_maintenance_mode_on', xdefault: false, xrequired: false),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.businessSetup, key: 'business_name', size: 1000, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.businessSetup, key: 'registration_number', size: 500, xrequired: false),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.businessSetup, key: 'tax_number', size: 100, xrequired: true),
        () => db.createBooleanAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.businessSetup, key: 'is_cod_active', xdefault: false, xrequired: false),
        () => db.createBooleanAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.businessSetup, key: 'is_digital_active', xdefault: false, xrequired: false),
        () => db.createBooleanAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.businessSetup, key: 'is_wallet_active', xdefault: false, xrequired: false),

  ], [
    Permission.read(Role.any()),          // Everyone can see
    Permission.create(Role.team('admin_team')),
    Permission.read(Role.team('admin_team')),
    Permission.update(Role.team('admin_team')),
    Permission.delete(Role.team('admin_team')),
  ]);
}

Future<void> _setupCategories(Databases db) async {
  await _createCollection(db, AppwriteConfig.categoriesCollection, 'Categories', [
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.categoriesCollection, key: 'name', size: 64, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.categoriesCollection, key: 'description', size: 64, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.categoriesCollection, key: 'image_path', size: 2000, xrequired: true),
        () => db.createIntegerAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.categoriesCollection, key: 'sort_order', xrequired: false),
        () => db.createBooleanAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.categoriesCollection, key: 'is_active', xrequired: false, xdefault: true),
  ], [
    Permission.read(Role.any()),          // Everyone can see
    Permission.create(Role.team('admin_team')),
    Permission.read(Role.team('admin_team')),
    Permission.update(Role.team('admin_team')),
    Permission.delete(Role.team('admin_team')),
  ]);
}

Future<void> _setupProducts(Databases db) async {
  await _createCollection(db, AppwriteConfig.productsCollection, 'Products', [
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.productsCollection, key: 'category_id', size: 64, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.productsCollection, key: 'name', size: 128, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.productsCollection, key: 'description', size: 1024, xrequired: false),
        () => db.createFloatAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.productsCollection, key: 'price', xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.productsCollection, key: 'discount_type', size: 128, xrequired: true),
        () => db.createFloatAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.productsCollection, key: 'discount_value', xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.productsCollection, key: 'image_id', size: 2000, xrequired: true),
        () => db.createBooleanAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.productsCollection, key: 'is_veg', xrequired: false, xdefault: false),
        () => db.createBooleanAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.productsCollection, key: 'is_available', xrequired: false, xdefault: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.productsCollection, key: 'variants', size: 5000, xrequired: false),
        () => db.createIntegerAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.productsCollection, key: 'stock', xrequired: false, xdefault: 0),
        () => db.createIntegerAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.productsCollection, key: 'order_count', xrequired: false, xdefault: 0),
  ], [
    Permission.read(Role.any()),          // Everyone can see
    Permission.write(Role.team('admin')), // Only 'admin' team can edit
    Permission.create(Role.team('admin_team')),
    Permission.read(Role.team('admin_team')),
    Permission.update(Role.team('admin_team')),
    Permission.delete(Role.team('admin_team')),
  ]);
}

Future<void> _setupOrders(Databases db) async {
  await _createCollection(db, 'orders', 'Orders', [
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: 'orders', key: 'customer_id', size: 64, xrequired: true),
        //make relation ship attribute between orders and users
        () => db.createRelationshipAttribute(
      databaseId: AppwriteConfig.dbId,
      collectionId: 'orders',
      relatedCollectionId: 'users',
      type: RelationshipType.manyToOne,
      twoWay: true,
      key: 'customer',
      twoWayKey: 'orders',
      onDelete: RelationMutate.restrict, // Don't let someone delete a User if they have active orders (Safe)
    ),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: 'orders', key: 'driver_id', size: 64, xrequired: false),
        () => db.createEnumAttribute(databaseId: AppwriteConfig.dbId, collectionId: 'orders', key: 'status', elements: ['pending', 'cooking', 'ready', 'on_way', 'delivered', 'cancelled'], xrequired: true),
        () => db.createEnumAttribute(databaseId: AppwriteConfig.dbId, collectionId: 'orders', key: 'payment_method', elements: ['cod', 'online', 'wallet'], xrequired: true),
        () => db.createEnumAttribute(databaseId: AppwriteConfig.dbId, collectionId: 'orders', key: 'payment_status', elements: ['paid', 'unpaid'], xrequired: true),
        () => db.createFloatAttribute(databaseId: AppwriteConfig.dbId, collectionId: 'orders', key: 'total_amount', xrequired: true),
        () => db.createFloatAttribute(databaseId: AppwriteConfig.dbId, collectionId: 'orders', key: 'delivery_fee', xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: 'orders', key: 'delivery_address', size: 2000, xrequired: true), // Snapshot JSON
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: 'orders', key: 'order_items', size: 5000, xrequired: true), // Snapshot JSON
        () => db.createDatetimeAttribute(databaseId: AppwriteConfig.dbId, collectionId: 'orders', key: 'created_at', xrequired: true),
  ], [
    Permission.create(Role.users()),      // Any logged-in user can add
    Permission.read(Role.users()), // Users can see their own addresses
    Permission.update(Role.users()), // Users can update their own addresses
    Permission.delete(Role.users()), // Users can delete their own addresses
    Permission.read(Role.team('admin_team')),  // Admins can see all orders
    Permission.update(Role.team('admin_team')), // Admins can update status
  ]);
}

Future<void> _setupAddresses(Databases db) async {
  await _createCollection(db, 'addresses', 'Addresses', [
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: 'addresses', key: 'user_id', size: 64, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: 'addresses', key: 'label', size: 64, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: 'addresses', key: 'address', size: 512, xrequired: true),
    // Note: Creating Spatial Indexes via API is complex, we just store string Lat/Lng for now.
    // In production, manually add a Spatial Index on this location attribute in Console.
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: 'addresses', key: 'location', size: 128, xrequired: true),
  ], [
    Permission.create(Role.users()),      // Any logged-in user can add
    Permission.read(Role.users()), // Users can see their own addresses
    Permission.update(Role.users()), // Users can update their own addresses
    Permission.delete(Role.users()), // Users can delete their own addresses
  ]);
}

Future<void> _setupCoupons(Databases db) async {
  await _createCollection(db, AppwriteConfig.couponsCollection, 'Coupons', [
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.couponsCollection, key: 'code', size: 32, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.couponsCollection, key: 'description', size: 200, xrequired: true),
        () => db.createEnumAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.couponsCollection, key: 'discount_type', elements: ['percentage', 'fixed'], xrequired: true),
        () => db.createFloatAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.couponsCollection, key: 'discount_value', xrequired: true),
        () => db.createFloatAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.couponsCollection, key: 'min_order_amount', xrequired: true),
        () => db.createFloatAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.couponsCollection, key: 'max_discount', xrequired: true),
        () => db.createIntegerAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.couponsCollection, key: 'usage_limit', xrequired: true),
        () => db.createIntegerAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.couponsCollection, key: 'used_count', xrequired: false),
        () => db.createDatetimeAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.couponsCollection, key: 'valid_from', xrequired: true),
        () => db.createDatetimeAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.couponsCollection, key: 'valid_until', xrequired: true),
        () => db.createBooleanAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.couponsCollection, key: 'is_active', xrequired: false, xdefault: true),
  ], [
    Permission.read(Role.users()),
    Permission.write(Role.team('admin_team')), // Only 'admin' team can edit
    Permission.create(Role.team('admin_team')),
    Permission.read(Role.team('admin_team')),
    Permission.update(Role.team('admin_team')),
    Permission.delete(Role.team('admin_team')),
  ]);
}

Future<void> _setupStoreSetup(Databases db) async {
  await _createCollection(db, AppwriteConfig.storeSetup, 'Store Setup', [
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeSetup, key: 'store_name', size: 256, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeSetup, key: 'description', size: 1000, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeSetup, key: 'address', size: 500, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeSetup, key: 'city', size: 100, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeSetup, key: 'state', size: 100, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeSetup, key: 'zip_code', size: 20, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeSetup, key: 'phone', size: 20, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeSetup, key: 'email', size: 128, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeSetup, key: 'website', size: 256, xrequired: false),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeSetup, key: 'facebook', size: 256, xrequired: false),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeSetup, key: 'instagram', size: 256, xrequired: false),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeSetup, key: 'twitter', size: 256, xrequired: false),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeSetup, key: 'logo_url', size: 2000, xrequired: false),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.storeSetup, key: 'cover_url', size: 2000, xrequired: false),
  ], [
    Permission.read(Role.any()),          // Everyone can see
    Permission.create(Role.team('admin_team')),
    Permission.read(Role.team('admin_team')),
    Permission.update(Role.team('admin_team')),
    Permission.delete(Role.team('admin_team')),
  ]);
}

Future<void> _setupBanners(Databases db) async {
  await _createCollection(db, AppwriteConfig.bannersCollection, 'Banners', [
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.bannersCollection, key: 'image_url', size: 2000, xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.bannersCollection, key: 'title', size: 128, xrequired: false),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.bannersCollection, key: 'subtitle', size: 256, xrequired: false),
        () => db.createEnumAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.bannersCollection, key: 'action_type', elements: ['none', 'product', 'category', 'url'], xrequired: true),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.bannersCollection, key: 'action_value', size: 256, xrequired: false),
        () => db.createBooleanAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.bannersCollection, key: 'is_active', xrequired: false, xdefault: true),
        () => db.createIntegerAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.bannersCollection, key: 'sort_order', xrequired: false, xdefault: 0),
        () => db.createRelationshipAttribute(
          databaseId: AppwriteConfig.dbId,
          collectionId: AppwriteConfig.bannersCollection,
          relatedCollectionId: AppwriteConfig.categoriesCollection,
          type: RelationshipType.manyToOne,
          twoWay: true,
          key: 'category_id',
          twoWayKey: AppwriteConfig.bannersCollection,
          onDelete: RelationMutate.restrict, // Don't let someone delete a User if they have active orders (Safe)
        ),
        () => db.createStringAttribute(databaseId: AppwriteConfig.dbId, collectionId: AppwriteConfig.bannersCollection, key: 'url', size: 256, xrequired: false),

  ], [
    Permission.read(Role.any()),          // Everyone can see
    Permission.create(Role.team('admin_team')),
    Permission.read(Role.team('admin_team')),
    Permission.update(Role.team('admin_team')),
    Permission.delete(Role.team('admin_team')),
  ]);
}

// Import the additional services
// import 'package:dart_appwrite/dart_appwrite.dart';

Future<void> _setupAdminAccount(Client client) async {
  final users = Users(client);
  final teams = Teams(client);

  print("🔹 Setting up Admin Account...");

  // 1. Create the 'admin' Team
  String? teamId;
  try {
    final teamList = await teams.list(search: 'admin');
    if (teamList.teams.isNotEmpty) {
      teamId = teamList.teams.first.$id;
      print("✅ 'admin' team already exists.");
    } else {
      final newTeam = await teams.create(teamId: 'admin_team', name: 'admin');
      teamId = newTeam.$id;
      print("✅ Created 'admin' Team.");
    }
  } catch (e) {
    print("⚠️ Error checking teams: $e");
  }

  // 2. Create the Default Admin User
  const adminEmail = 'admin@admin.com';
  const adminPass = '12345678'; // Default password for buyers
  String? userId;

  try {
    // Try to create the user
    final user = await users.create(
      userId: ID.unique(),
      email: adminEmail,
      password: adminPass,
      name: 'Super Admin',
      // emailVerified: true,
    );
    userId = user.$id;
    print("✅ Created Default Admin: $adminEmail / $adminPass");
  } catch (e) {
    // If user already exists, try to find their ID (requires listing users)
    // For simplicity in script, we assume if create fails, they exist.
    print("🔹 Admin user likely exists already.");
    // In a real script, you'd fetch the user ID here to ensure they are in the team.
    return;
  }

  // 3. Add User to the Admin Team
  if (teamId != null) {
    try {
      await teams.createMembership(
        teamId: teamId,
        roles: ['owner'],
        email: adminEmail, // Invite by email (auto-accepted if user exists)
        userId: userId,
        url: AppwriteConfig.endpoint, // Required but not used for auto-join
      );
      print("✅ Added Admin to 'admin' Team.");
    } catch (e) {
      print("🔹 User is already in the team.");
    }
  }
}