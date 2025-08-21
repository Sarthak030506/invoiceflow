import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/invoice_model.dart';
import '../models/customer_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'invoiceflow.db');
    return openDatabase(
      path,
      version: 8, // Increment version for modification fields
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE customers (
            id TEXT PRIMARY KEY,
            name TEXT,
            phoneNumber TEXT UNIQUE,
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');
        
        await db.execute('''
          CREATE TABLE invoices (
            id TEXT PRIMARY KEY,
            invoiceNumber TEXT,
            clientName TEXT,
            customerPhone TEXT,
            customerId TEXT,
            date TEXT,
            revenue REAL,
            status TEXT,
            notes TEXT,
            createdAt TEXT,
            updatedAt TEXT,
            invoiceType TEXT DEFAULT 'sales',
            amountPaid REAL DEFAULT 0.0,
            paymentMethod TEXT DEFAULT 'Cash',
            followUpDate TEXT,
            isDeleted INTEGER DEFAULT 0,
            cancelledAt TEXT,
            cancelReason TEXT,
            FOREIGN KEY (customerId) REFERENCES customers(id)
          )
        ''');
        
        await db.execute('''
          CREATE TABLE invoice_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            invoiceId TEXT,
            name TEXT,
            quantity INTEGER,
            price REAL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add invoiceType column to existing database
          await db.execute('ALTER TABLE invoices ADD COLUMN invoiceType TEXT DEFAULT "sales"');
        }
        if (oldVersion < 3) {
          // Add payment fields to existing database
          await db.execute('ALTER TABLE invoices ADD COLUMN amountPaid REAL DEFAULT 0.0');
          await db.execute('ALTER TABLE invoices ADD COLUMN paymentMethod TEXT DEFAULT "Cash"');
        }
        if (oldVersion < 4) {
          // Create customers table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS customers (
              id TEXT PRIMARY KEY,
              name TEXT,
              phoneNumber TEXT UNIQUE,
              createdAt TEXT,
              updatedAt TEXT
            )
          ''');
          
          // Add customer fields to invoices table
          await db.execute('ALTER TABLE invoices ADD COLUMN customerPhone TEXT');
          await db.execute('ALTER TABLE invoices ADD COLUMN customerId TEXT');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE invoices ADD COLUMN followUpDate TEXT');
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE invoices ADD COLUMN isDeleted INTEGER DEFAULT 0');
        }
        if (oldVersion < 7) {
          await db.execute('ALTER TABLE invoices ADD COLUMN cancelledAt TEXT');
          await db.execute('ALTER TABLE invoices ADD COLUMN cancelReason TEXT');
        }
        if (oldVersion < 8) {
          await db.execute('ALTER TABLE invoices ADD COLUMN modifiedFlag INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE invoices ADD COLUMN modifiedReason TEXT');
          await db.execute('ALTER TABLE invoices ADD COLUMN modifiedAt TEXT');
        }
      },
    );
  }

  Future<void> insertInvoice(InvoiceModel invoice) async {
    final db = await database;
    await db.insert('invoices', invoice.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    for (final item in invoice.items) {
      await db.insert('invoice_items', {
        'invoiceId': invoice.id,
        'name': item.name,
        'quantity': item.quantity,
        'price': item.price,
      });
    }
  }

  Future<void> updateInvoice(InvoiceModel invoice) async {
    final db = await database;
    
    // Update the invoice record
    await db.update(
      'invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
    
    // Delete existing items for this invoice
    await db.delete('invoice_items', where: 'invoiceId = ?', whereArgs: [invoice.id]);
    
    // Insert updated items
    for (final item in invoice.items) {
      await db.insert('invoice_items', {
        'invoiceId': invoice.id,
        'name': item.name,
        'quantity': item.quantity,
        'price': item.price,
      });
    }
  }

  Future<List<InvoiceModel>> getAllInvoices() async {
    final db = await database;
    final invoiceMaps = await db.query('invoices', orderBy: 'date ASC');
    
    // Batch fetch all invoice items in a single query
    final allItems = await db.query('invoice_items');
    
    // Group items by invoiceId for faster lookup
    final itemsByInvoiceId = <String, List<Map<String, dynamic>>>{};
    for (final item in allItems) {
      final invoiceId = item['invoiceId'] as String;
      itemsByInvoiceId[invoiceId] ??= [];
      itemsByInvoiceId[invoiceId]!.add(item);
    }
    
    // Create invoice models with their items
    final invoices = invoiceMaps.map((map) {
      final invoiceId = map['id'] as String;
      final items = itemsByInvoiceId[invoiceId] ?? [];
      final invoice = InvoiceModel.fromDb(map, items);
      
      // Ensure paid invoices have their amountPaid set to match the total
      if (invoice.status.toLowerCase() == 'paid' && invoice.amountPaid == 0.0) {
        // Update the database record
        db.update(
          'invoices',
          {'amountPaid': invoice.total},
          where: 'id = ?',
          whereArgs: [invoice.id],
        );
        
        // Return an updated invoice model
        return invoice.copyWith(amountPaid: invoice.total);
      }
      
      return invoice;
    }).toList();
    
    return invoices;
  }

  Future<List<InvoiceModel>> getRecentInvoices({int limit = 5}) async {
    final db = await database;
    final invoiceMaps = await db.query('invoices', orderBy: 'date DESC', limit: limit);
    
    // Extract all invoice IDs
    final invoiceIds = invoiceMaps.map((map) => map['id'] as String).toList();
    
    // No invoices found
    if (invoiceIds.isEmpty) return [];
    
    // Batch fetch items for these invoices in a single query
    final allItems = await db.query(
      'invoice_items',
      where: 'invoiceId IN (${List.filled(invoiceIds.length, '?').join(',')})',
      whereArgs: invoiceIds,
    );
    
    // Group items by invoiceId for faster lookup
    final itemsByInvoiceId = <String, List<Map<String, dynamic>>>{};
    for (final item in allItems) {
      final invoiceId = item['invoiceId'] as String;
      itemsByInvoiceId[invoiceId] ??= [];
      itemsByInvoiceId[invoiceId]!.add(item);
    }
    
    // Create invoice models with their items
    return invoiceMaps.map((map) {
      final invoiceId = map['id'] as String;
      final items = itemsByInvoiceId[invoiceId] ?? [];
      return InvoiceModel.fromDb(map, items);
    }).toList();
  }

  Future<InvoiceModel?> getInvoiceById(String invoiceId) async {
    final db = await database;
    final invoiceMaps = await db.query('invoices', where: 'id = ?', whereArgs: [invoiceId]);
    
    if (invoiceMaps.isEmpty) return null;
    
    final items = await db.query('invoice_items', where: 'invoiceId = ?', whereArgs: [invoiceId]);
    return InvoiceModel.fromDb(invoiceMaps.first, items);
  }

  Future<void> deleteInvoice(String invoiceId) async {
    final db = await database;
    await db.delete('invoice_items', where: 'invoiceId = ?', whereArgs: [invoiceId]);
    await db.delete('invoices', where: 'id = ?', whereArgs: [invoiceId]);
  }

  Future<void> deleteAllInvoices() async {
    final db = await database;
    await db.delete('invoice_items');
    await db.delete('invoices');
  }
  
  // Customer methods
  Future<void> insertCustomer(CustomerModel customer) async {
    final db = await database;
    await db.insert('customers', customer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  Future<CustomerModel?> getCustomerByPhone(String phoneNumber) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'phoneNumber = ?',
      whereArgs: [phoneNumber],
    );
    
    if (maps.isEmpty) return null;
    return CustomerModel.fromMap(maps.first);
  }
  
  Future<CustomerModel?> getCustomerById(String id) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return CustomerModel.fromMap(maps.first);
  }
  
  Future<List<CustomerModel>> getAllCustomers() async {
    final db = await database;
    final maps = await db.query('customers', orderBy: 'name ASC');
    return maps.map((map) => CustomerModel.fromMap(map)).toList();
  }

  Future<List<InvoiceModel>> getInvoicesByCustomerId(String customerId) async {
    final db = await database;
    final invoiceMaps = await db.query(
      'invoices', 
      where: 'customerId = ?', 
      whereArgs: [customerId],
      orderBy: 'date DESC'
    );
    
    final allItems = await db.query('invoice_items');
    final itemsByInvoiceId = <String, List<Map<String, dynamic>>>{};
    
    for (final item in allItems) {
      final invoiceId = item['invoiceId'] as String;
      itemsByInvoiceId[invoiceId] ??= [];
      itemsByInvoiceId[invoiceId]!.add(item);
    }
    
    return invoiceMaps.map((map) {
      final invoiceId = map['id'] as String;
      final items = itemsByInvoiceId[invoiceId] ?? [];
      return InvoiceModel.fromDb(map, items);
    }).toList();
  }

  Future<Map<String, double>> getCustomerOutstandingBalances() async {
    final db = await database;
    final invoices = await db.query(
      'invoices',
      where: 'invoiceType = ? AND customerId IS NOT NULL',
      whereArgs: ['sales'],
    );
    
    final balances = <String, double>{};
    
    for (final invoice in invoices) {
      final customerId = invoice['customerId'] as String?;
      if (customerId == null) continue;
      
      final total = invoice['revenue'] as double;
      final amountPaid = invoice['amountPaid'] as double? ?? 0.0;
      final remaining = total - amountPaid;
      
      if (remaining > 0) {
        balances[customerId] = (balances[customerId] ?? 0.0) + remaining;
      }
    }
    
    return balances;
  }

  Future<void> deleteCustomer(String customerId) async {
    final db = await database;
    
    // First, update all invoices to remove the customer reference
    await db.update(
      'invoices',
      {'customerId': null, 'customerPhone': null},
      where: 'customerId = ?',
      whereArgs: [customerId],
    );
    
    // Then delete the customer record
    await db.delete('customers', where: 'id = ?', whereArgs: [customerId]);
  }
}