# flutter_local_notifications - BroadcastReceiverの難読化を防ぐ
-keep class com.dexterous.** { *; }

# Isar - ネイティブライブラリ抽出クラスを保持
-keep class dev.isar.** { *; }

# Flutter plugins - 汎用的な保持
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
