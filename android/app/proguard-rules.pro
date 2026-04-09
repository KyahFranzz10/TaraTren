# Generic rules for generic signature preservation
-keepattributes Signature, EnclosingMethod, *Annotation*

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Gson rules (used by flutter_local_notifications internally)
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }
# Keep generic signatures of TypeToken and its subclasses
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
