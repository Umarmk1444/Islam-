# Flutter Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }

# Just Audio & Audio Service
-keep class com.ryanheise.** { *; }

# Workmanager & Alarm Manager
-keep class dev.fluttercommunity.plus.** { *; }
-keep class androidx.work.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Play Core and Deferred Components (Suppress warnings)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn androidx.**
-dontwarn org.conscrypt.**
-dontwarn okio.**

