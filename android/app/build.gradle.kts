import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The upload key's location and passwords. Never committed (README, Release).
val keystorePropertiesFile: File = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

fun keystoreProperty(name: String): String =
    keystoreProperties.getProperty(name)?.takeIf { it.isNotBlank() }
        ?: throw GradleException("android/key.properties has no $name. See README, Release.")

android {
    namespace = "io.github.youngbossman.traccash"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.youngbossman.traccash"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                // Relative paths resolve from android/app/.
                storeFile = file(keystoreProperty("storeFile"))
                storePassword = keystoreProperty("storePassword")
                keyAlias = keystoreProperty("keyAlias")
                keyPassword = keystoreProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Deliberately no fallback to the debug key. Android installs an update only
            // if it is signed with the same key, so a debug-signed release on a phone
            // could never be upgraded without uninstalling, which deletes every expense.
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

// Release builds are ARM only (README, Build). Flutter's Gradle plugin packages plugins'
// native libraries for every ABI it supports, whatever --target-platform says, so jni's
// libdartjni.so would add an x86_64 folder: an x86_64 device would then install the APK
// and the app would stop at launch, with no libflutter.so for x86_64. Without that folder
// such devices refuse the install. An abiFilters entry can't do this: AGP adds a build
// type's filters to the default config's, where Flutter has put all three. Debug and
// profile builds keep every ABI, so `flutter run` still works on the x86_64 emulator.
androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        variant.packaging.jniLibs.excludes.addAll("**/x86/**", "**/x86_64/**", "**/riscv64/**")
    }
}

// Without key.properties, debug and profile builds work as before, but a release
// build stops here, before compiling, rather than producing an unsigned APK.
gradle.taskGraph.whenReady {
    if (hasTask("${project.path}:preReleaseBuild") && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "Release builds need android/key.properties and the upload keystore. " +
                "See README, Release.",
        )
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
