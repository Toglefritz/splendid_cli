plugins {
    id("java")
    id("org.jetbrains.kotlin.jvm") version "2.0.21"
    id("org.jetbrains.intellij.platform") version "2.2.1"
}

group = "com.splendidcli"
version = "1.0.0"

repositories {
    mavenCentral()
    
    intellijPlatform {
        defaultRepositories()
    }
}

dependencies {
    intellijPlatform {
        // Compile against Android Studio Ladybug (stable Kotlin version)
        // But declare compatibility with 2025.2+ so it works in your installed version
        androidStudio("2024.2.1.11")
        
        bundledPlugin("com.intellij.java")
        
        pluginVerifier()
        zipSigner()
    }
}

// Set the JVM compatibility versions
java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

tasks {
    patchPluginXml {
        // Declare compatibility with Android Studio 2024.2 through 2025.2+
        sinceBuild.set("242")
        untilBuild.set("999.*")
    }

    signPlugin {
        certificateChain.set(System.getenv("CERTIFICATE_CHAIN"))
        privateKey.set(System.getenv("PRIVATE_KEY"))
        password.set(System.getenv("PRIVATE_KEY_PASSWORD"))
    }

    publishPlugin {
        token.set(System.getenv("PUBLISH_TOKEN"))
    }
}

intellijPlatform {
    pluginConfiguration {
        ideaVersion {
            sinceBuild = "242"
            untilBuild = "999.*"
        }
    }
    
    buildSearchableOptions = false
    sandboxContainer = layout.buildDirectory.dir("idea-sandbox")
}
