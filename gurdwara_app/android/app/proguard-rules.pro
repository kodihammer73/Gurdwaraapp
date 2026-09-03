# Flutter's Android embedding and generated plugin registrant are referenced
# by Flutter at runtime. Keep their entry points when R8 optimizes the app.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Firebase and WorkManager components declared through Android manifests.
-keepnames class * extends android.app.Service
-keepnames class * extends android.content.BroadcastReceiver
-keepnames class * extends androidx.work.ListenableWorker

# Preserve runtime annotations used by libraries and generated code.
-keepattributes *Annotation*
