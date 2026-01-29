allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Ensure the build directory is in the root project folder so Flutter can find the APK
rootProject.layout.buildDirectory.set(file("${project.projectDir}/../build"))

subprojects {
    project.layout.buildDirectory.set(file("${rootProject.layout.buildDirectory.get()}/${project.name}"))
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Fix the Java 8 obsolete warnings
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "17"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
