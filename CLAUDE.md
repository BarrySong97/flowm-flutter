# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flowm is a Flutter-based personal finance management application that tracks assets, liabilities, income, and expenses using double-entry accounting principles. The app supports mobile platforms (iOS/Android) with native widgets for home screen integration.

## Development Commands

### Core Development
- `flutter pub get` - Install dependencies
- `flutter run` - Run app in debug mode
- `flutter run --release` - Run app in release mode
- `flutter build ios --release` - Build iOS release version
- `flutter build apk --release` - Build Android release APK

### Code Generation
- `flutter pub run build_runner build --delete-conflicting-outputs` - Generate Drift database code and other generated files
- `flutter pub run build_runner watch` - Watch for changes and auto-generate code

### iOS Deployment
- `ios-deploy --bundle build/ios/iphoneos/Runner.app` - Deploy to iOS device

### Testing & Quality
- `flutter test` - Run unit tests
- `flutter analyze` - Static code analysis

## Architecture Overview

### Database Layer (Drift ORM)
- **Location**: `lib/db/`
- **Database**: SQLite with Drift ORM for type-safe database operations
- **Key Files**:
  - `app_database.dart` - Main database class with migration strategy
  - `tables/` - Table definitions for accounts, transactions, postings, etc.
  - `dao/` - Data access objects for database operations
- **Double-Entry Accounting**: Uses accounts, transactions, and postings tables to maintain financial integrity

### State Management (Riverpod)
- **Location**: `lib/state/`
- **Pattern**: Feature-based organization with providers and repositories
- **Key Directories**:
  - `account/`, `assets/`, `expense/`, `income/`, `liabilities/` - Feature-specific state
  - `transaction/` - Transaction management and calendar providers
  - `database/` - Database provider setup

### Navigation (GoRouter)
- **File**: `lib/navigation/app_router.dart`
- **Pattern**: Route-based navigation with custom transitions
- **Structure**: Splash → Main Screen with tab navigation

### UI Architecture
- **Pages**: `lib/pages/` - Main application screens
- **Components**: `lib/components/` - Reusable UI components organized by feature
- **Theme**: `lib/config/theme.dart` - Centralized theme configuration

### Platform Integration
- **iOS Widgets**: `ios/FlowmWidget/` - SwiftUI widgets for home screen
- **Android Widgets**: `android/app/src/main/kotlin/` - Android widgets for home screen
- **Native Bridge**: Uses `home_widget` package for cross-platform widget communication

## Key Features

1. **Financial Tracking**: Assets, liabilities, income, and expenses with double-entry accounting
2. **Data Visualization**: Charts and graphs using Syncfusion and FL Chart
3. **Calendar Integration**: Transaction viewing by date using Table Calendar
4. **Multi-platform Widgets**: Native home screen widgets on iOS and Android
5. **Local Database**: Offline-first with SQLite and Drift ORM

## Development Notes

- Uses Chinese localization as primary language (`zh_CN`)
- Implements responsive design with custom color scheme
- Database schema includes performance-optimized indexes for financial queries
- State management follows reactive patterns with Riverpod providers
- Navigation uses custom slide transitions for better UX