# Most Firebase/Play Services/Play Billing AARs ship their own consumer
# ProGuard rules (merged automatically by AGP), so this file only covers
# gaps that have historically bitten Flutter + R8 full-mode builds.

# Play Billing (in_app_purchase) — reflection-based callbacks.
-keep class com.android.billingclient.api.** { *; }

# Firebase Auth / Firestore — keep model-ish classes safe from renaming
# even though this app uses raw Maps, not annotated POJOs.
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Sign-In.
-keep class com.google.android.gms.auth.** { *; }

# google_mobile_ads / UMP consent SDK.
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.ump.** { *; }
-dontwarn com.google.android.gms.ads.**

# flutter_local_notifications uses reflection to find a launch activity.
-keep class com.dexterous.** { *; }
