import com.android.build.gradle.LibraryExtension

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

// Ensure third-party Android library modules (e.g., Flutter plugins) have a namespace
// required by newer Android Gradle Plugin versions. If a library omits `namespace`,
// derive it from the package declared in its AndroidManifest.xml.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        extensions.configure(LibraryExtension::class.java) {
            val hasNamespace = namespace.isPresent && !namespace.get().isNullOrBlank()
            if (!hasNamespace) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                val manifestText = if (manifestFile.exists()) manifestFile.readText() else ""
                val match = Regex("""package\s*=\s*["']([^"']+)["']""").find(manifestText)
                val derived = match?.groupValues?.get(1)
                    ?: "com.example.${project.name.replace("[^A-Za-z0-9_.]".toRegex(), "_")}"
                namespace.set(derived)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
