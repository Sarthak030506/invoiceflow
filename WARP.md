# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Development Commands

### Building and Running
```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Run on specific device
flutter run -d chrome          # Web
flutter run -d windows         # Windows
flutter run -d android         # Android

# Run with hot reload for development
flutter run --hot

# Build release APK for Android
flutter build apk --release

# Build release bundle for Play Store
flutter build appbundle --release

# Build for iOS
flutter build ios --release

# Build for web
flutter build web --release

# Build for Windows
flutter build windows --release
```

### Testing and Quality Assurance
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Analyze code for issues
flutter analyze

# Format code
dart format .

# Check for outdated dependencies
flutter pub outdated

# Clean build artifacts
flutter clean
```

### Firebase and Deployment
```bash
# Initialize Firebase (if not already done)
flutterfire configure

# Deploy to Firebase Hosting (web builds)
firebase deploy --only hosting

# View Firebase logs
firebase functions:log

# Test Firebase security rules
firebase emulators:start
```

## Architecture Overview

### Core Architecture Pattern
InvoiceFlow follows a **Clean Architecture** with Firebase/Firestore as the backend, implementing:
- **Service Layer**: Business logic encapsulation (`lib/services/`)
- **Repository Pattern**: Data access abstraction via Firebase services
- **Provider Pattern**: State management using `provider` package
- **Multi-tenant Architecture**: User-scoped Firestore collections (`users/{uid}/`)

### Key Services and Their Responsibilities
1. **FirestoreService**: Core CRUD operations for invoices and customers
2. **InventoryFirestoreService**: Inventory and stock movement operations with atomic transactions
3. **InvoiceService**: Business logic layer with CSV migration support and inventory integration
4. **InventoryService**: Comprehensive inventory management with real-time stock calculations
5. **AuthService**: Firebase Authentication management (email/password + Google Sign-In)
6. **AnalyticsService**: Real-time business metrics with correct revenue calculations
7. **NotificationService**: Local push notifications and background reminders

### Firebase/Firestore Data Structure
```
users/{uid}/
├── customers/{customerId}     # Customer profiles with phone lookup
├── invoices/{invoiceId}       # Invoice documents with full lifecycle
├── inventory_items/{itemId}   # Inventory master data
└── stock_movements/{movementId} # All inventory transactions with audit trail
```

### State Management Pattern
- Uses **Provider** pattern with ChangeNotifier
- Key providers: `AuthProvider`, `InventoryProvider`
- Services are singletons accessed via `.instance`
- Real-time updates via Firestore streams and StreamControllers

## Critical Business Logic

### Invoice Lifecycle Management
- **Status Workflow**: Draft → Posted → Paid → Cancelled
- **Inventory Integration**: Posted invoices automatically update inventory
- **Cancellation Validation**: Prevents negative stock scenarios with dependency checking
- **Admin Override**: Force operations with comprehensive audit trail and mandatory reasoning

### Inventory Management System
- **Real-time Stock Calculations**: Computed from movement history, not stored totals
- **Movement Types**: IN, OUT, ADJUSTMENT, RETURN_IN, RETURN_OUT, REVERSAL_OUT
- **Atomic Operations**: All inventory changes use Firestore transactions
- **Stock Validation**: Comprehensive validation to prevent negative stock scenarios

### Revenue Calculation (Critical Implementation)
```dart
// CORRECT: Revenue = SUM(quantity × selling price) for sales invoice line items
Revenue = invoice.items.fold(0.0, (sum, item) => sum + (item.quantity * item.price))
// NOT: Revenue = invoice.total (which may include taxes/discounts)
```

### Multi-tenant Security
- All data strictly scoped to authenticated user UID
- Firestore Security Rules enforce user-based access
- Authentication required for all operations
- No cross-user data access possible

## Key File Locations

### Core Application Structure
- **Entry Point**: `lib/main.dart` - App initialization with Firebase setup
- **Routes**: `lib/routes/app_routes.dart` - Application routing configuration
- **Theme**: `lib/theme/app_theme.dart` - Material 3 theme with custom colors
- **Models**: `lib/models/` - Data models (Invoice, Customer, Inventory, etc.)

### Business Logic Services
- **Invoice Management**: `lib/services/invoice_service.dart`
- **Inventory Management**: `lib/services/inventory_service.dart`
- **Customer Management**: `lib/services/customer_service.dart`
- **Firebase Operations**: `lib/services/firestore_service.dart`
- **Authentication**: `lib/services/auth_service.dart`

### UI Components and Screens
- **Authentication Flow**: `lib/presentation/auth/` (login, register, forgot password)
- **Main Dashboard**: `lib/presentation/home_dashboard/`
- **Invoice Management**: `lib/presentation/invoices_list_screen/`
- **Analytics**: `lib/presentation/analytics_redesign/` (7-card layout)
- **Inventory**: `lib/presentation/inventory_screen/`
- **Customers**: `lib/presentation/customers_screen/`

### Platform Configurations
- **Android**: `android/` directory with build configs and signing setup
- **iOS**: `ios/` directory with Podfile and iOS-specific settings
- **Web**: Automatic via Flutter web support
- **Firebase Config**: `lib/firebase_options.dart` (auto-generated)

## Development Guidelines

### Adding New Features
1. **Services First**: Create or extend services in `lib/services/`
2. **Models**: Define data models in `lib/models/`
3. **UI Screens**: Create screens in `lib/presentation/`
4. **Routes**: Add routes to `lib/routes/app_routes.dart`
5. **State Management**: Use Provider pattern for UI state

### Firebase Integration Patterns
```dart
// Always use user-scoped collections
final userDoc = FirebaseFirestore.instance
    .collection('users')
    .doc(currentUser.uid);

// Use streams for real-time updates
Stream<QuerySnapshot> get invoicesStream => userDoc
    .collection('invoices')
    .snapshots();

// Use transactions for atomic operations
await FirebaseFirestore.instance.runTransaction((transaction) async {
    // Multiple operations here
});
```

### Inventory Integration Requirements
When working with invoices that affect inventory:
1. **Posted Purchase Invoices**: Must call `InventoryService.receiveStock()`
2. **Posted Sales Invoices**: Must call `InventoryService.issueStock()`
3. **Invoice Cancellation**: Must validate with `InventoryService.validateInvoiceCancellation()`
4. **Stock Movements**: Always use atomic transactions

### Testing Considerations
- **Firebase Emulator**: Use for local testing (avoid production data)
- **Mock Services**: Create service mocks for unit testing
- **Integration Tests**: Test complete workflows (invoice → inventory → analytics)
- **Device Testing**: Test on multiple screen sizes and platforms

## Common Development Tasks

### Adding a New Invoice Type
1. Extend `InvoiceModel` with new type constants
2. Update `InvoiceService._processInvoiceInventory()` for inventory handling
3. Add UI screens in `lib/presentation/`
4. Update analytics calculations in `AnalyticsService`

### Adding New Inventory Features
1. Extend `InventoryItem` model if needed
2. Add business logic to `InventoryService`
3. Update Firestore service methods in `InventoryFirestoreService`
4. Create UI in `lib/presentation/inventory_screen/`

### Implementing New Analytics
1. Add calculation logic to `AnalyticsService`
2. Ensure real-time updates via streams
3. Create charts using FL Chart in analytics screens
4. Update the 7-card analytics layout

### Setting Up for Production
1. **Keystore Setup**: Use `KEYSTORE_GENERATION.md` for Android signing
2. **Firebase Config**: Ensure production Firebase project is configured
3. **Build Configuration**: Update version numbers in `pubspec.yaml`
4. **Store Preparation**: Follow `PLAYSTORE_PREPARATION.md` guide

## Architecture Decisions and Constraints

### Why Firebase/Firestore?
- Real-time multi-device synchronization
- Built-in authentication and security
- Horizontal scaling without infrastructure management
- Offline capability with automatic sync

### Why Provider for State Management?
- Simpler than Bloc for this app's complexity
- Excellent integration with Firebase streams
- Flutter-native solution with good performance

### Why Singleton Services?
- Ensures single source of truth for business logic
- Easier dependency management
- Consistent data access patterns across the app

### Critical Performance Considerations
- **Firestore Queries**: Always use compound indices for complex queries
- **Real-time Listeners**: Properly dispose of stream subscriptions
- **Image Handling**: Use `cached_network_image` for performance
- **Large Lists**: Implement pagination for invoice/customer lists

Remember: InvoiceFlow is a production-ready business application with real-time multi-user capabilities. All changes should preserve data integrity, maintain security, and follow the established architectural patterns.
