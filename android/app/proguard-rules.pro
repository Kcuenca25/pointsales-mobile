# Mantener clases de jTDS/JDBC
-keep class net.sourceforge.jtds.** { *; }
-dontwarn net.sourceforge.jtds.**

# Mantener clases de jcifs
-keep class jcifs.** { *; }
-dontwarn jcifs.**

# Mantener clases de GSS
-keep class org.ietf.jgss.** { *; }
-dontwarn org.ietf.jgss.**

# Mantener clases de SQL
-keep class java.sql.** { *; }
-keep class javax.sql.** { *; }
-dontwarn java.sql.**
-dontwarn javax.sql.**

# Otras reglas comunes para Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Mantener anotaciones
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes Signature
-keepattributes InnerClasses

# Mantener recursos
-keepclassmembers class **.R$* {
    public static <fields>;
}