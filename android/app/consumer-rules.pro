# Consumer ProGuard rules for bili_ownx

# Keep Flutter-specific classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep custom application class
-keep class com.example.bili_ownx.** { *; }

# Keep model classes
-keep class com.example.bili_ownx.models.** { *; }

# Keep data classes used in serialization
-keep class com.example.bili_ownx.data.** { *; }

# Keep Kotlin metadata
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Keep Retrofit and networking classes if used
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }

# Keep JSON parsing classes
-keep class com.google.gson.** { *; }
-keep class org.json.** { *; }

# Keep media player related classes
-keep class androidx.media3.** { *; }
-keep class com.google.android.exoplayer2.** { *; }

# Keep download manager classes
-keep class android.app.DownloadManager { *; }

# Keep file provider classes
-keep class androidx.core.content.FileProvider { *; }

# Suppress warnings about missing classes
-dontnote androidx.media3.common.**
-dontnote okhttp3.**
-dontnote retrofit2.**