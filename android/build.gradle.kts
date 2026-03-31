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
    afterEvaluate {
        if (plugins.hasPlugin("com.android.application") ||
            plugins.hasPlugin("com.android.library")
        ) {
            extensions.findByName("android")?.let { androidExtension ->
                val fallbackNamespace =
                    project.group.toString().takeIf {
                        it.isNotBlank() && it != "unspecified"
                    } ?: "com.example.${project.name.replace("-", "_")}"

                runCatching {
                    val namespaceGetter = androidExtension.javaClass.methods.firstOrNull {
                        it.name == "getNamespace" && it.parameterCount == 0
                    }
                    val namespaceSetter = androidExtension.javaClass.methods.firstOrNull {
                        it.name == "setNamespace" && it.parameterCount == 1
                    }
                    val currentNamespace = namespaceGetter?.invoke(androidExtension) as? String

                    if (currentNamespace.isNullOrBlank()) {
                        namespaceSetter?.invoke(androidExtension, fallbackNamespace)
                    }
                }
            }
        }
    }

    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
