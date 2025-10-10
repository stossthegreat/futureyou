import com.android.build.api.dsl.LibraryExtension
import com.android.build.api.dsl.ApplicationExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Force a consistent Java/Kotlin toolchain across all Android subprojects.
// This avoids JVM target mismatches like 1.8 vs 17 during plugin compilation.
subprojects {
    pluginManager.withPlugin("com.android.application") {
        extensions.configure<ApplicationExtension> {
            compileOptions {
                // Use Java 17 for source/target
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
            // Configure Kotlin JVM target
            (this as org.gradle.api.plugins.ExtensionAware).extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinJvmOptions>("kotlinOptions") {
                jvmTarget = JavaVersion.VERSION_17.toString()
            }
        }
    }

    pluginManager.withPlugin("com.android.library") {
        extensions.configure<com.android.build.api.dsl.LibraryExtension> {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
            (this as org.gradle.api.plugins.ExtensionAware).extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinJvmOptions>("kotlinOptions") {
                jvmTarget = JavaVersion.VERSION_17.toString()
            }
        }
    }
}

// Ensure third-party Android library modules (e.g., Flutter plugins) have a namespace
// required by newer Android Gradle Plugin versions. If a library omits `namespace`,
// derive it from the package declared in its AndroidManifest.xml.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        extensions.configure(LibraryExtension::class.java) {
            val hasNamespace = !namespace.isNullOrBlank()
            if (!hasNamespace) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                val manifestText = if (manifestFile.exists()) manifestFile.readText() else ""
                val match = Regex("""package\s*=\s*["']([^"']+)["']""").find(manifestText)
                val derived = match?.groupValues?.get(1)
                    ?: "com.example.${project.name.replace("[^A-Za-z0-9_.]".toRegex(), "_")}"
                namespace = derived
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
