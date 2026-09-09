plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.blanchisserie.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Requis par flutter_local_notifications (API Java 8+ desugarées).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.blanchisserie.app"
        // Firebase Auth (téléphone/OTP) exige minSdk 23.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // À remplacer par une vraie clé de signature avant publication.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
    implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Le plugin google-services exige google-services.json et fait échouer le
// build s'il est absent. Tant que le projet Firebase réel n'est pas encore
// connecté (voir lib/firebase_options.dart), on l'applique seulement si le
// fichier existe, pour permettre un build de démonstration sans backend.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
