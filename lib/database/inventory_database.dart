// Minimal no-op stub. All inventory operations now use Firestore services.
class InventoryDatabase {
  static final InventoryDatabase _instance = InventoryDatabase._internal();
  factory InventoryDatabase() => _instance;
  InventoryDatabase._internal();

  Future<void> deleteDatabaseFile() async {}
}