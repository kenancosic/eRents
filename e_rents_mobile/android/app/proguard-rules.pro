# Flutter Stripe SDK ProGuard rules
# Keep ALL Stripe classes to prevent R8 from stripping them
-keep class com.stripe.** { *; }

# Suppress warnings for React Native SDK internal references
# (flutter_stripe internally references these but doesn't ship them)
-dontwarn com.reactnativestripesdk.**

# Additional Stripe push provisioning rules
-dontwarn com.stripe.android.pushProvisioning.**

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Google Play Core (deferred components) - suppress warnings for optional classes
# Flutter references these but they're only needed for Play Store deferred components
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**