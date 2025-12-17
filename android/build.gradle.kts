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
    
    // 优化编译任务
    tasks.withType<JavaCompile> {
        options.isIncremental = true
        options.isFork = true
    }
    
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
        incremental = true
        kotlinOptions {
            jvmTarget = "1.8"
        }
    }
    
    // 统一依赖版本策略
    configurations.all {
        resolutionStrategy {
            // Media3 版本对齐
            eachDependency {
                when (requested.group) {
                    "androidx.media3" -> useVersion("1.5.0")
                    "androidx.core" -> {
                        if (requested.name.startsWith("core")) {
                            useVersion("1.13.1")
                        }
                    }
                    "androidx.lifecycle" -> {
                        if (requested.name.startsWith("lifecycle")) {
                            useVersion("2.8.7")
                        }
                    }
                    "org.jetbrains.kotlin" -> {
                        if (requested.name.startsWith("kotlin-stdlib")) {
                            useVersion("2.0.21")
                        }
                    }
                }
            }
            
            // 强制使用兼容版本
            force("androidx.core:core-ktx:1.13.1")
            force("androidx.appcompat:appcompat:1.7.0")
            force("androidx.media3:media3-exoplayer:1.5.0")
            force("androidx.media3:media3-common:1.5.0")
            force("androidx.media3:media3-ui:1.5.0")
        }
    }
}