# InvoiceFlow

**InvoiceFlow** is a comprehensive business management platform designed for small to medium-sized businesses and freelancers. It provides complete invoice lifecycle management, real-time inventory tracking, customer relationship management, and advanced business analytics through a unified, cloud-native mobile application.

![Flutter](https://img.shields.io/badge/Flutter-3.6.0+-blue.svg)
![Firebase](https://img.shields.io/badge/Firebase-Cloud-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## What InvoiceFlow Does

InvoiceFlow helps businesses:
- **Create & Manage Invoices** - Professional sales and purchase invoices with smart numbering
- **Track Payments** - Monitor outstanding balances and send WhatsApp payment reminders
- **Manage Inventory** - Real-time stock tracking with automatic updates and low stock alerts
- **Process Returns** - Handle sales and purchase returns with inventory adjustments
- **Analyze Performance** - Real-time dashboards with revenue analytics and business KPIs
- **Stay Organized** - Automated notifications for follow-ups and unpaid invoices
- **Sync Everywhere** - Cloud-based sync across all devices via Firebase

## Key Features

### Invoice Management
- **Dual Invoice Types**: Sales invoices (customer billing) and Purchase invoices (vendor/expense tracking)
- **Smart Numbering**: Auto-generated invoice numbers with format `INV-YYYYMM###`
- **Flexible Dating**: Backdate or future-date invoices as needed
- **Invoice Lifecycle**: Draft → Posted → Paid/Cancelled with full status tracking
- **Payment Tracking**: Record partial/full payments with multiple payment methods (Cash, Online, Cheque)
- **Follow-up Scheduling**: Set and track follow-up dates for unpaid invoices
- **PDF Export**: Generate professional invoice PDFs for sharing
- **WhatsApp Integration**: Send payment reminders directly via WhatsApp

### Customer Management
- **Complete Profiles**: Store contact information, address, email, and phone
- **Purchase History**: View complete invoice timeline for each customer
- **Outstanding Balances**: Real-time tracking of amounts due
- **Smart Lookup**: Phone-based customer search with duplicate prevention
- **Customer Analytics**: Spending patterns, revenue contribution, and lifetime value
- **Pending Returns**: Track refund amounts awaiting application

### Inventory System
- **Real-Time Stock Tracking**: Automatic updates from sales and purchase invoices
- **Movement Audit Trail**: Complete history with 6 movement types (IN, OUT, ADJUSTMENT, RETURN_IN, RETURN_OUT, REVERSAL_OUT)
- **Low Stock Alerts**: Automated notifications when items reach reorder points
- **Barcode Support**: Product identification and scanning
- **Inventory Valuation**: Real-time calculation of inventory worth
- **Stock Movement Reversal**: Undo operations for cancelled invoices
- **Negative Stock Prevention**: Validation to prevent overselling
- **Admin Override**: Force operations with comprehensive audit trail

### Returns Management
- **Sales Returns**: Process customer returns with automatic stock increases
- **Purchase Returns**: Return goods to suppliers with stock decreases
- **Refund Tracking**: Monitor pending refund amounts per customer
- **Return Reasons**: Document why items were returned
- **Inventory Integration**: Automatic stock adjustments on return processing

### Analytics Dashboard
- **7-Card Layout**: Overview KPIs, Revenue Analytics, Items & Sales, Inventory Health, Due Reminders, Analytics Table, Visual Charts
- **Real-Time Metrics**: Revenue, profit, payment collection efficiency
- **Date Range Filtering**: Last 7/30/90 days, This year, All time, Custom ranges
- **Customer Analytics**: Revenue by customer, outstanding balances
- **Item Analytics**: Top-performing products and categories
- **Inventory Health**: Stock distribution, turnover rates, aging analysis
- **Performance Optimized**: 30-minute cache with smart invalidation

### Notifications & Reminders
- **Follow-up Reminders**: Daily notifications at 10:00 AM for invoices requiring follow-up
- **Unpaid Purchase Reminders**: Daily alerts at 2:00 PM for outstanding vendor payments
- **Low Stock Alerts**: Automatic notifications for reorder points
- **User Preferences**: Configurable notification settings
- **Background Service**: Automatic rescheduling on app startup

### Business Catalogues
Pre-configured product catalogues for multiple industries:
- Bakery (50+ items)
- Clothing (100+ items)
- Electronics (80+ items)
- Grocery (120+ items)
- Hardware (70+ items)
- Pharmacy (90+ items)
- Stationery (133+ items with pricing)

## Technology Stack

### Frontend
- **Flutter 3.6.0+**: Cross-platform mobile framework
- **Material Design 3**: Modern, responsive UI components
- **Dart**: Primary programming language
- **Provider**: State management with ChangeNotifier pattern
- **Sizer**: Responsive design across devices
- **FL Charts**: Interactive data visualizations

### Backend & Services
- **Firebase Authentication**: Email/Password + Google Sign-In
- **Cloud Firestore**: NoSQL database with real-time sync
- **Firebase Storage**: File and document storage
- **Firebase Analytics**: User behavior tracking
- **Firebase Cloud Messaging**: Push notifications

### Key Packages
- `firebase_core`, `firebase_auth`, `cloud_firestore`: Firebase integration
- `google_sign_in`: OAuth authentication
- `fl_chart`: Charts and graphs
- `pdf`: PDF generation
- `csv`: Data import/export
- `shared_preferences`: Local data persistence
- `url_launcher`: WhatsApp and external links
- `flutter_local_notifications`: Local push notifications
- `uuid`: Unique identifier generation

## Installation & Setup

### Prerequisites
- Flutter SDK (^3.6.0)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android SDK / Xcode (for iOS development)
- Firebase account with active project

### Step 1: Clone the Repository
```bash
git clone https://github.com/yourusername/invoiceflow.git
cd invoiceflow
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Firebase Configuration

#### Android Configuration
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing project `invoiceflow-deafa`
3. Add an Android app to your Firebase project
4. Download `google-services.json`
5. Place it in `android/app/google-services.json`

#### iOS Configuration (Optional)
1. Add an iOS app in Firebase Console
2. Download `GoogleService-Info.plist`
3. Place it in `ios/Runner/GoogleService-Info.plist`

#### Web Configuration
1. Add a Web app in Firebase Console
2. Copy the Firebase configuration
3. Update `lib/firebase_options.dart` with your configuration

### Step 4: Firestore Setup

#### Enable Firestore Database
1. In Firebase Console, go to Firestore Database
2. Click "Create Database"
3. Start in **production mode** or **test mode** (for development)
4. Choose a location for your database

#### Deploy Security Rules
```bash
firebase deploy --only firestore:rules
```

#### Deploy Indexes
```bash
firebase deploy --only firestore:indexes
```

### Step 5: Enable Authentication
1. In Firebase Console, go to Authentication
2. Enable **Email/Password** sign-in method
3. Enable **Google** sign-in method (optional)

### Step 6: Run the Application
```bash
# Debug mode
flutter run

# Release mode (Android)
flutter run --release

# Web
flutter run -d chrome
```

## Project Structure

```
invoiceflow/
├── android/                    # Android-specific configuration
├── ios/                        # iOS-specific configuration
├── lib/
│   ├── main.dart              # Application entry point
│   ├── models/                # Data models
│   │   ├── invoice_model.dart
│   │   ├── customer_model.dart
│   │   ├── inventory_item.dart
│   │   ├── stock_movement.dart
│   │   └── return_model.dart
│   ├── screens/               # UI screens (30+ screens)
│   │   ├── home/
│   │   ├── invoices/
│   │   ├── customers/
│   │   ├── inventory/
│   │   ├── analytics/
│   │   └── profile/
│   ├── services/              # Business logic layer
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── inventory_service.dart
│   │   ├── customer_service.dart
│   │   ├── analytics_service.dart
│   │   ├── return_service.dart
│   │   └── notification_service.dart
│   ├── providers/             # State management
│   │   ├── auth_provider.dart
│   │   ├── invoice_provider.dart
│   │   └── inventory_provider.dart
│   ├── widgets/               # Reusable UI components
│   ├── utils/                 # Helper utilities
│   └── theme/                 # App theming
├── assets/                    # Static assets
├── firebase.json              # Firebase configuration
├── firestore.rules            # Firestore security rules
├── firestore.indexes.json     # Firestore indexes
├── pubspec.yaml               # Dependencies
└── README.md                  # This file
```

## Architecture

InvoiceFlow follows **Clean Architecture** principles with clear separation of concerns:

### Layers
1. **Presentation Layer** (`screens/`, `widgets/`): UI components and user interactions
2. **Business Logic Layer** (`services/`): Business rules and operations
3. **Data Layer** (`models/`, Firebase): Data models and persistence
4. **State Management** (`providers/`): Application state with Provider pattern

### Design Patterns
- **Repository Pattern**: Data access abstraction via services
- **Singleton Pattern**: Service instances (AuthService, FirestoreService, etc.)
- **Observer Pattern**: Real-time updates via Firestore streams
- **Factory Pattern**: Model instantiation from JSON

### Multi-Tenant Architecture
- **User Isolation**: All data scoped to authenticated user UID
- **Firestore Structure**: `users/{uid}/invoices/{invoiceId}`
- **Security Rules**: Server-side enforcement of user-based access
- **Data Privacy**: Complete isolation between user accounts

## Data Models

### Invoice Model
```dart
{
  id: String,
  invoiceNumber: String,         // Format: INV-YYYYMM###
  customerId: String,
  customerName: String,
  customerPhone: String,
  date: Timestamp,
  invoiceType: String,           // 'sales' or 'purchase'
  items: List<InvoiceItem>,
  subtotal: double,              // Computed from items
  total: double,
  amountPaid: double,
  paymentMethod: String,         // 'cash', 'online', 'cheque'
  status: String,                // 'draft', 'posted', 'cancelled'
  followUpDate: Timestamp,
  cancelledAt: Timestamp,
  cancelReason: String,
  refundAdjustment: double,
  modifiedFlag: bool,
  modifiedReason: String
}
```

### Customer Model
```dart
{
  id: String,
  name: String,
  phoneNumber: String,
  email: String,
  address: String,
  totalSpent: double,            // Denormalized
  totalPaid: double,             // Denormalized
  invoiceCount: int,             // Denormalized
  pendingReturnAmount: double,
  lastPurchaseDate: Timestamp,
  createdAt: Timestamp
}
```

### Inventory Item Model
```dart
{
  id: String,
  sku: String,
  name: String,
  category: String,
  unit: String,
  currentStock: double,
  openingStock: double,
  reorderPoint: double,
  avgCost: double,
  barcode: String,
  lastUpdated: Timestamp
}
```

## Development

### Running Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

### Format Code
```bash
flutter format lib/
```

### Build for Development
```bash
# Android
flutter build apk --debug

# iOS
flutter build ios --debug

# Web
flutter build web
```

## Deployment

### Android (APK)
```bash
# Build release APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release
```

### iOS (App Store)
```bash
# Build for iOS
flutter build ios --release

# Build IPA
flutter build ipa --release
```

### Web (Firebase Hosting)
```bash
# Build web app
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

## Firebase Project Information

- **Project ID**: `invoiceflow-deafa`
- **Firestore Database**: `(default)`
- **Firebase Hosting**: Configured for web deployment
- **Security Rules**: User-scoped data access enforced

## Environment Configuration

### Development
- Uses Firebase development project
- Debug logging enabled
- Test notification features available

### Production
- Firebase production project
- Analytics enabled
- Optimized builds with code minification

## Features by Screen

| Screen | Features |
|--------|----------|
| **Home Dashboard** | Recent invoices, Quick actions, Key metrics, Notification status |
| **Invoices List** | Search, Filter by type/status/date, Multi-select, Pagination |
| **Invoice Detail** | Full invoice view, Payment recording, PDF export, WhatsApp share, Returns |
| **Create/Edit Invoice** | Smart number generation, Customer lookup, Item selection, Payment entry |
| **Customers** | Customer list, Search, Outstanding balances, Purchase history, WhatsApp reminders |
| **Inventory** | Real-time stock display, Item details, Low stock highlighting, Stock movements |
| **Analytics** | 7-card dashboard, Revenue charts, Customer analytics, Item performance, Inventory health |
| **Returns** | Create return, Select items, Apply refunds, Track pending returns |
| **Profile** | User settings, Notification preferences, Account management |

## Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter/Dart style guide
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed
- Ensure code passes `flutter analyze`

## Known Limitations

- **Single User**: No multi-user team collaboration features yet
- **Currency**: Fixed to INR (₹), multi-currency support planned
- **Offline Mode**: Limited offline capabilities, primarily cloud-dependent
- **Payment Integration**: Records manual payments only, no direct payment processing
- **iOS Deployment**: Not actively deployed to Apple App Store yet

## Roadmap

- [ ] Multi-currency support
- [ ] Offline-first architecture with sync
- [ ] Payment gateway integration
- [ ] Advanced reporting and scheduled exports
- [ ] Team collaboration features
- [ ] Custom invoice templates
- [ ] Expense tracking and categorization
- [ ] Tax calculation automation

## Support

For issues, questions, or feature requests:
- Open an issue on GitHub
- Contact: support@invoiceflow.com

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- Powered by [Firebase](https://firebase.google.com)
- Icons from [Material Design Icons](https://fonts.google.com/icons)
- Charts powered by [FL Chart](https://github.com/imaNNeo/fl_chart)

---

**Made with ❤️ for small businesses worldwide**
