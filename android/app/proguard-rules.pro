-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
# Ignore missing JPX decoder (JPEG2000)
-dontwarn com.gemalto.jp2.**

# Keep PDFBox safe
-keep class com.tom_roush.pdfbox.** { *; }

# Preserve line numbers for better crash reports (optional)
-keepattributes SourceFile,LineNumberTable

# Ignore warnings from missing classes in plugins (prevents build failures)
-ignorewarnings