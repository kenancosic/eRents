# Stripe SDK ProGuard Rules (Based on Stripe AI + crash fixes)
-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.model.** { *; }
-keep class com.stripe.android.view.** { *; }
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class com.stripe.android.stripe3ds2.** { *; }
-keep interface com.stripe.android.** { *; }

# Google Pay (if using)
-keep class com.google.android.gms.wallet.** { *; }
-dontwarn com.google.android.gms.wallet.**

# Don't warn about Stripe classes
-dontwarn com.stripe.android.**
-dontwarn kotlinx.parcelize.Parceler$DefaultImpls
-dontwarn kotlinx.parcelize.Parceler
-dontwarn kotlinx.parcelize.Parcelize

# Critical: Keep all enum classes (prevents NullPointerException)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Critical: Keep Parcelable implementations (prevents crashes)
-keep class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Critical: Keep internal classes that reference each other
-keep class * extends com.stripe.android.** { *; }
-keepclassmembers class * extends com.stripe.android.** { *; }

# Additional protection for internal Stripe classes
-keep class com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-keep class com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-keep class com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-keep class com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-keep class com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider