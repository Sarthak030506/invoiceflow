import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../models/inventory_item_model.dart';
import '../models/stock_movement_model.dart';

class InventoryDatabase {
  static final InventoryDatabase _instance = InventoryDatabase._internal();
  factory InventoryDatabase() => _instance;
  InventoryDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inventory.db');

    return await openDatabase(
      path,
      version: 4, // Bumped to 4 for itemId column fix
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE inventory_items (
        id TEXT PRIMARY KEY,
        sku TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        opening_stock REAL NOT NULL DEFAULT 0,
        current_stock REAL NOT NULL DEFAULT 0,
        reorder_point REAL NOT NULL DEFAULT 0,
        avg_cost REAL NOT NULL DEFAULT 0,
        category TEXT NOT NULL,
        last_updated TEXT NOT NULL,
        batch_number TEXT,
        expiry_date TEXT,
        barcode TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        itemId TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        unitCost REAL NOT NULL DEFAULT 0,
        sourceRefType TEXT NOT NULL,
        sourceRefId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        reversalOfMovementId TEXT,
        reversalFlag INTEGER DEFAULT 0,
        FOREIGN KEY (itemId) REFERENCES inventory_items (id)
      )
    ''');

    await db.execute('CREATE INDEX idx_stock_movements_itemId ON stock_movements(itemId)');
    await db.execute('CREATE INDEX idx_stock_movements_createdAt ON stock_movements(createdAt)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='inventory_items'"
      );
      
      if (tables.isEmpty) {
        await _createInventoryTables(db);
      } else {
        await _addMissingColumns(db);
      }
    }
    
    if (oldVersion < 3) {
      await _addAuditColumns(db);
    }
    
    if (oldVersion < 4) {
      await _fixStockMovementsSchema(db);
    }
  }

  Future<void> _createInventoryTables(Database db) async {
    await db.execute('''
      CREATE TABLE inventory_items (
        id TEXT PRIMARY KEY,
        sku TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        opening_stock REAL NOT NULL DEFAULT 0,
        current_stock REAL NOT NULL DEFAULT 0,
        reorder_point REAL NOT NULL DEFAULT 0,
        avg_cost REAL NOT NULL DEFAULT 0,
        category TEXT NOT NULL,
        last_updated TEXT NOT NULL,
        batch_number TEXT,
        expiry_date TEXT,
        barcode TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        itemId TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        unitCost REAL NOT NULL DEFAULT 0,
        sourceRefType TEXT NOT NULL,
        sourceRefId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        reversalOfMovementId TEXT,
        reversalFlag INTEGER DEFAULT 0,
        FOREIGN KEY (itemId) REFERENCES inventory_items (id)
      )
    ''');

    await db.execute('CREATE INDEX idx_stock_movements_itemId ON stock_movements(itemId)');
    await db.execute('CREATE INDEX idx_stock_movements_createdAt ON stock_movements(createdAt)');
  }

  Future<void> _addMissingColumns(Database db) async {
    // Get existing columns
    final columns = await db.rawQuery('PRAGMA table_info(inventory_items)');
    final existingColumns = columns.map((col) => col['name'] as String).toSet();

    // Add missing columns with safe defaults
    final requiredColumns = {
      'opening_stock': 'ALTER TABLE inventory_items ADD COLUMN opening_stock REAL DEFAULT 0',
      'reorder_point': 'ALTER TABLE inventory_items ADD COLUMN reorder_point REAL DEFAULT 0', 
      'avg_cost': 'ALTER TABLE inventory_items ADD COLUMN avg_cost REAL DEFAULT 0',
      'category': 'ALTER TABLE inventory_items ADD COLUMN category TEXT DEFAULT "General"',
      'last_updated': 'ALTER TABLE inventory_items ADD COLUMN last_updated TEXT DEFAULT "${DateTime.now().toIso8601String()}"',
      'batch_number': 'ALTER TABLE inventory_items ADD COLUMN batch_number TEXT',
      'expiry_date': 'ALTER TABLE inventory_items ADD COLUMN expiry_date TEXT',
      'barcode': 'ALTER TABLE inventory_items ADD COLUMN barcode TEXT',
    };

    for (final entry in requiredColumns.entries) {
      if (!existingColumns.contains(entry.key)) {
        try {
          await db.execute(entry.value);
        } catch (e) {
          print('Error adding column ${entry.key}: $e');
        }
      }
    }

    // Create stock_movements table if it doesn't exist
    final movementTables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='stock_movements'"
    );
    
    if (movementTables.isEmpty) {
      await db.execute('''
        CREATE TABLE stock_movements (
          id TEXT PRIMARY KEY,
          itemId TEXT NOT NULL,
          type TEXT NOT NULL,
          quantity REAL NOT NULL,
          unitCost REAL NOT NULL DEFAULT 0,
          sourceRefType TEXT NOT NULL,
          sourceRefId TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          reversalOfMovementId TEXT,
          reversalFlag INTEGER DEFAULT 0,
          FOREIGN KEY (itemId) REFERENCES inventory_items (id)
        )
      ''');

      await db.execute('CREATE INDEX idx_stock_movements_itemId ON stock_movements(itemId)');
      await db.execute('CREATE INDEX idx_stock_movements_createdAt ON stock_movements(createdAt)');
    }
  }

  Future<List<InventoryItem>> getAllItems() async {
    final db = await database;
    final maps = await db.query('inventory_items', orderBy: 'name ASC');
    return maps.map((map) => InventoryItem.fromJson(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getSellableItems() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT id, name, sku, unit, 
             COALESCE(avg_cost, 0.0) as sell_price,
             COALESCE(avg_cost, 0.0) as purchase_price,
             COALESCE(category, 'General') as category,
             COALESCE(current_stock, 0.0) as current_stock,
             COALESCE(reorder_point, 0.0) as reorder_point
      FROM inventory_items 
      ORDER BY name ASC
    ''');
    
    // Ensure all items have proper numeric values
    for (final item in maps) {
      item['current_stock'] = (item['current_stock'] as num?)?.toDouble() ?? 0.0;
      item['sell_price'] = (item['sell_price'] as num?)?.toDouble() ?? 0.0;
      item['purchase_price'] = (item['purchase_price'] as num?)?.toDouble() ?? 0.0;
      item['reorder_point'] = (item['reorder_point'] as num?)?.toDouble() ?? 0.0;
    }
    
    return maps;
  }
  
  Future<List<Map<String, dynamic>>> getItemsForPicker() async {
    return await getSellableItems();
  }

  Future<InventoryItem?> getItemById(String id) async {
    final db = await database;
    final maps = await db.query('inventory_items', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? InventoryItem.fromJson(maps.first) : null;
  }

  Future<InventoryItem?> getItemBySku(String sku) async {
    final db = await database;
    final maps = await db.query('inventory_items', where: 'sku = ?', whereArgs: [sku]);
    return maps.isNotEmpty ? InventoryItem.fromJson(maps.first) : null;
  }

  Future<List<InventoryItem>> getLowStockItems() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT * FROM inventory_items 
      WHERE current_stock <= reorder_point 
      ORDER BY current_stock ASC
    ''');
    return maps.map((map) => InventoryItem.fromJson(map)).toList();
  }

  Future<void> insertItem(InventoryItem item) async {
    final db = await database;
    await db.insert('inventory_items', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateItem(InventoryItem item) async {
    final db = await database;
    await db.update('inventory_items', item.toJson(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> insertMovement(StockMovement movement) async {
    final db = await database;
    await db.insert('stock_movements', movement.toJson());
    await _updateItemStockFromMovement(movement);
  }

  Future<void> _updateItemStockFromMovement(StockMovement movement) async {
    final db = await database;
    final item = await getItemById(movement.itemId);
    if (item == null) return;

    double newStock = item.currentStock;
    double newAvgCost = item.avgCost;
    
    switch (movement.type) {
      case StockMovementType.IN:
      case StockMovementType.RETURN_IN:
        if (movement.unitCost > 0) {
          final totalValue = (item.currentStock * item.avgCost) + (movement.quantity * movement.unitCost);
          final totalQty = item.currentStock + movement.quantity;
          newAvgCost = totalQty > 0 ? totalValue / totalQty : movement.unitCost;
        }
        newStock += movement.quantity;
        break;
      case StockMovementType.OUT:
      case StockMovementType.RETURN_OUT:
      case StockMovementType.REVERSAL_OUT:
        newStock -= movement.quantity;
        break;
      case StockMovementType.ADJUSTMENT:
        newStock += movement.quantity; // Add the delta, not set to absolute value
        break;
    }

    await db.update(
      'inventory_items',
      {
        'current_stock': newStock,
        'avg_cost': newAvgCost,
        'last_updated': DateTime.now().toIso8601String()
      },
      where: 'id = ?',
      whereArgs: [movement.itemId],
    );
  }

  Future<double> computeCurrentStock(String itemId) async {
    final db = await database;
    
    // First check if item exists
    final item = await getItemById(itemId);
    if (item == null) {
      return 0.0; // Item doesn't exist, return 0 stock
    }
    
    // Compute actual stock from movements for accuracy
    final movements = await db.query(
      'stock_movements',
      where: 'itemId = ? AND reversalFlag = 0',
      whereArgs: [itemId],
      orderBy: 'createdAt ASC',
    );
    
    double computedStock = item.openingStock;
    
    for (final movementMap in movements) {
      final movement = StockMovement.fromJson(movementMap);
      switch (movement.type) {
        case StockMovementType.IN:
        case StockMovementType.RETURN_IN:
          computedStock += movement.quantity;
          break;
        case StockMovementType.OUT:
        case StockMovementType.RETURN_OUT:
        case StockMovementType.REVERSAL_OUT:
          computedStock -= movement.quantity;
          break;
        case StockMovementType.ADJUSTMENT:
          computedStock += movement.quantity; // Delta adjustment
          break;
      }
    }
    
    return computedStock;
  }

  Future<List<StockMovement>> getMovementsBySource(String sourceType, String sourceId) async {
    final db = await database;
    final maps = await db.query(
      'stock_movements',
      where: 'sourceRefType = ? AND sourceRefId = ?',
      whereArgs: [sourceType, sourceId],
      orderBy: 'createdAt ASC',
    );
    return maps.map((map) => StockMovement.fromJson(map)).toList();
  }

  Future<List<StockMovement>> getMovementsByItem(String itemId) async {
    final db = await database;
    final maps = await db.query(
      'stock_movements',
      where: 'itemId = ?',
      whereArgs: [itemId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => StockMovement.fromJson(map)).toList();
  }

  Future<void> reverseMovementsAtomically(String sourceType, String sourceId) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Get all IN movements for this source
      final movements = await txn.query(
        'stock_movements',
        where: 'sourceRefType = ? AND sourceRefId = ? AND type = ?',
        whereArgs: [sourceType, sourceId, 'IN'],
      );
      
      for (final movementMap in movements) {
        final originalMovement = StockMovement.fromJson(movementMap);
        
        // Create reversal movement
        final reversalMovement = StockMovement(
          id: 'rev_${DateTime.now().millisecondsSinceEpoch}_${originalMovement.id}',
          itemId: originalMovement.itemId,
          type: StockMovementType.REVERSAL_OUT,
          quantity: originalMovement.quantity,
          unitCost: originalMovement.unitCost,
          sourceRefType: 'reversal',
          sourceRefId: sourceId,
          createdAt: DateTime.now(),
          reversalOfMovementId: originalMovement.id,
          reversalFlag: true,
        );
        
        // Insert reversal movement
        await txn.insert('stock_movements', reversalMovement.toJson());
        
        // Update item stock directly in transaction
        await txn.rawUpdate(
          'UPDATE inventory_items SET current_stock = current_stock - ?, last_updated = ? WHERE id = ?',
          [originalMovement.quantity, DateTime.now().toIso8601String(), originalMovement.itemId],
        );
      }
    });
  }

  Future<List<StockMovement>> getMovementsAfterDate(String itemId, DateTime afterDate) async {
    final db = await database;
    final maps = await db.query(
      'stock_movements',
      where: 'itemId = ? AND createdAt > ?',
      whereArgs: [itemId, afterDate.toIso8601String()],
      orderBy: 'createdAt ASC',
    );
    return maps.map((map) => StockMovement.fromJson(map)).toList();
  }

  Future<void> _addAuditColumns(Database db) async {
    try {
      await db.execute('ALTER TABLE stock_movements ADD COLUMN reversalOfMovementId TEXT');
      await db.execute('ALTER TABLE stock_movements ADD COLUMN reversalFlag INTEGER DEFAULT 0');
    } catch (e) {
      print('Error adding audit columns: $e');
    }
  }

  Future<void> _fixStockMovementsSchema(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(stock_movements)');
      final columnNames = columns.map((col) => col['name'] as String).toSet();
      
      if (columnNames.contains('item_id')) {
        await db.execute('ALTER TABLE stock_movements RENAME TO stock_movements_old');
        
        await db.execute('''
          CREATE TABLE stock_movements (
            id TEXT PRIMARY KEY,
            itemId TEXT NOT NULL,
            type TEXT NOT NULL,
            quantity REAL NOT NULL,
            unitCost REAL NOT NULL DEFAULT 0,
            sourceRefType TEXT NOT NULL,
            sourceRefId TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            reversalOfMovementId TEXT,
            reversalFlag INTEGER DEFAULT 0,
            FOREIGN KEY (itemId) REFERENCES inventory_items (id)
          )
        ''');
        
        await db.execute('''
          INSERT INTO stock_movements (id, itemId, type, quantity, unitCost, sourceRefType, sourceRefId, createdAt, reversalOfMovementId, reversalFlag)
          SELECT id, item_id, type, quantity, 
                 COALESCE(unit_cost, 0), 
                 COALESCE(source_type, 'manual'), 
                 COALESCE(source_id, 'unknown'), 
                 created_at,
                 reversal_of_movement_id,
                 COALESCE(reversal_flag, 0)
          FROM stock_movements_old
        ''');
        
        await db.execute('DROP TABLE stock_movements_old');
        await db.execute('CREATE INDEX idx_stock_movements_itemId ON stock_movements(itemId)');
        await db.execute('CREATE INDEX idx_stock_movements_createdAt ON stock_movements(createdAt)');
      }
    } catch (e) {
      print('Error fixing stock_movements schema: $e');
    }
  }

  /// Development utility: Delete database file to force fresh schema creation
  Future<void> deleteItem(String itemId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('stock_movements', where: 'itemId = ?', whereArgs: [itemId]);
      await txn.delete('inventory_items', where: 'id = ?', whereArgs: [itemId]);
    });
  }

  /// Development utility: Delete database file to force fresh schema creation
  Future<void> deleteDatabaseFile() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'inventory.db');
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        _database = null; // Reset cached database
        print('Database file deleted successfully');
      }
    } catch (e) {
      print('Error deleting database file: $e');
    }
  }
}