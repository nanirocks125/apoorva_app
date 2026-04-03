# Apoorva - Jewelry POS 💎
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=nanirocks125_apoorva_app&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=nanirocks125_apoorva_app)
[![codecov](https://codecov.io/gh/nanirocks125/apoorva_app/graph/badge.svg?token=X64FYQNMWV)](https://codecov.io/gh/nanirocks125/apoorva_app)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=nanirocks125_apoorva_app&metric=bugs)](https://sonarcloud.io/summary/new_code?id=nanirocks125_apoorva_app)
[![Code Smells](https://sonarcloud.io/api/project_badges/measure?project=nanirocks125_apoorva_app&metric=code_smells)](https://sonarcloud.io/summary/new_code?id=nanirocks125_apoorva_app)
[![Duplicated Lines (%)](https://sonarcloud.io/api/project_badges/measure?project=nanirocks125_apoorva_app&metric=duplicated_lines_density)](https://sonarcloud.io/summary/new_code?id=nanirocks125_apoorva_app)
[![Lines of Code](https://sonarcloud.io/api/project_badges/measure?project=nanirocks125_apoorva_app&metric=ncloc)](https://sonarcloud.io/summary/new_code?id=nanirocks125_apoorva_app)
[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=nanirocks125_apoorva_app&metric=reliability_rating)](https://sonarcloud.io/summary/new_code?id=nanirocks125_apoorva_app)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=nanirocks125_apoorva_app&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=nanirocks125_apoorva_app)
[![Technical Debt](https://sonarcloud.io/api/project_badges/measure?project=nanirocks125_apoorva_app&metric=sqale_index)](https://sonarcloud.io/summary/new_code?id=nanirocks125_apoorva_app)
[![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=nanirocks125_apoorva_app&metric=sqale_rating)](https://sonarcloud.io/summary/new_code?id=nanirocks125_apoorva_app)
[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=nanirocks125_apoorva_app&metric=vulnerabilities)](https://sonarcloud.io/summary/new_code?id=nanirocks125_apoorva_app)

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
