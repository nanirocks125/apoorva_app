# Apoorva - Jewelry POS 💎

[![codecov](https://codecov.io/gh/nanirocks125/apoorva_app/graph/badge.svg?token=X64FYQNMWV)](https://codecov.io/gh/nanirocks125/apoorva_app)

A specialized POS system for Apoorva One-Gram Jewelry, Mangalagiri.


# Generate Icons for Dev Flavor
dart run flutter_launcher_icons --file lib/flutter_launcher_icons_dev.yaml

# Generate Icons for Prod Flavor
dart run flutter_launcher_icons --file lib/flutter_launcher_icons_prod.yaml

# Run Development App (Apoorva Dev)
flutter run --flavor dev

# Run Production App (Apoorva POS)
flutter run --flavor prod

# Build Production APK
flutter build apk --flavor prod --release

# Build Production App Bundle (for Play Store)
flutter build appbundle --flavor prod --release

# Build Dev APK (for testing)
flutter build apk --flavor dev --release

# Deep Clean (Run this if you face Build/Gradle errors)
flutter clean && flutter pub get

# Auto-fix Lint issues and Unused imports
dart fix --apply

# Format all files
flutter format .
