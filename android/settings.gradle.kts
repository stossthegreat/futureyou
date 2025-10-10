pluginManagement {
    // Resolve Flutter SDK path from local.properties when available,
    // otherwise fall back to common CI environment variables.
    val flutterSdkPath: String =
        run {
            val properties = java.util.Properties()
            val localPropertiesFile = file("local.properties")
            val fromLocalProperties: String? =
                if (localPropertiesFile.exists()) {
                    localPropertiesFile.inputStream().use { properties.load(it) }
                    properties.getProperty("flutter.sdk")
                } else {
                    null
                }

            fromLocalProperties
                ?: System.getenv("FLUTTER_HOME")
                ?: System.getenv("FLUTTER_ROOT")
                ?: throw GradleException(
                    "flutter.sdk not set in local.properties and FLUTTER_HOME/FLUTTER_ROOT not set"
                )
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
