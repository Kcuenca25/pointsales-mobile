import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ecommerce.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createUserTable(db);
    await _createProductTable(db);
    await _createCartTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS productos');
      await _createUserTable(db);
      await _createProductTable(db);
      await _createCartTable(db);
    }
  }

  Future<void> _createUserTable(Database db) async {
    await db.execute('''
      CREATE TABLE Users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        token TEXT
      )
    ''');
  }

  Future<void> _createProductTable(Database db) async {
    await db.execute('''
      CREATE TABLE Products (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        price REAL NOT NULL,
        description TEXT,
        category TEXT,
        image TEXT,
        barcode TEXT,
        rating_rate REAL,
        rating_count INTEGER,
        -- Campos específicos de Odoo
        name TEXT,
        default_code TEXT,
        list_price REAL,
        type TEXT,
        category_id INTEGER,
        category_name TEXT
      )
    ''');
  }

  Future<void> _createCartTable(Database db) async {
    await db.execute('''
      CREATE TABLE Cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        userId INTEGER,
        FOREIGN KEY (productId) REFERENCES Products(id),
        FOREIGN KEY (userId) REFERENCES Users(id)
      )
    ''');
  }

  // ✅ MÉTODOS PARA PRODUCTOS - CORREGIDOS
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('Products', product.toMap());
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Products');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  // ✅ MÉTODO PARA SINCRONIZAR PRODUCTOS DESDE ODDO
  Future<void> syncProductsFromOdoo(List<Product> odooProducts) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Limpiar productos existentes
      await txn.delete('Products');
      
      // Insertar nuevos productos
      for (final product in odooProducts) {
        await txn.insert('Products', product.toMap());
      }
    });
  }

  // ... (el resto de tus métodos para Users y Cart se mantienen igual)
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('Users', user.toMap());
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'Users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      'Users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos para Cart
  Future<int> addToCart(int productId, int quantity, int? userId) async {
    final db = await database;
    
    final existing = await db.query(
      'Cart',
      where: 'productId = ? AND userId = ?',
      whereArgs: [productId, userId],
    );
    
    if (existing.isNotEmpty) {
      return await db.update(
        'Cart',
        {'quantity': quantity},
        where: 'productId = ? AND userId = ?',
        whereArgs: [productId, userId],
      );
    } else {
      return await db.insert('Cart', {
        'productId': productId,
        'quantity': quantity,
        'userId': userId,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCartItems(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT Products.*, Cart.quantity, Cart.id as cartId 
      FROM Cart 
      INNER JOIN Products ON Cart.productId = Products.id 
      WHERE Cart.userId = ?
    ''', [userId]);
  }

  Future<int> removeFromCart(int cartId) async {
    final db = await database;
    return await db.delete(
      'Cart',
      where: 'id = ?',
      whereArgs: [cartId],
    );
  }

  Future<int> clearCart(int userId) async {
    final db = await database;
    return await db.delete(
      'Cart',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
