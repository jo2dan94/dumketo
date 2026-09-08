rootProject.name = "multi-app-patches-modern"

pluginManagement {
    // BUILD-MULTIAPP-PORTED.ps1 places the exact official plugin source here.
    includeBuild(".deps/morphe-patches-gradle-plugin")

    repositories {
        mavenLocal()
        gradlePluginPortal()
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

plugins {
    // Resolved from the pinned local composite build above.
    id("app.morphe.patches")
}

// The .mpp is compiled against the exact patcher source shipped by the user's
// current Morphe dev build. This avoids resolving the patcher from GitHub Packages.
includeBuild(".deps/morphe-patcher") {
    dependencySubstitution {
        substitute(module("app.morphe:morphe-patcher")).using(project(":"))
    }
}
