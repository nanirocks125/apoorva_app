plugins {
    id("com.google.gms.google-services") version "4.4.1" apply false // Updated to 4.4.0 for Gradle 8 support
}

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

// --- THE FIX STARTS HERE ---
subprojects {
    afterEvaluate {
        val project = this
        if (project.extensions.findByName("android") != null) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            
            // Fix 1: Ensure namespace is set for older plugins
            if (android.namespace == null) {
                android.namespace = project.group.toString()
            }

            // Fix 2: Force API 36 across all plugins to stop the Metadata error
            android.compileSdkVersion(36)
            android.buildToolsVersion("36.0.0") 
        }
    }
}
// --- THE FIX ENDS HERE ---

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}