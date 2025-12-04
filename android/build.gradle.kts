// 构建脚本依赖配置
buildscript {
    val kotlinVersion = "1.8.0"
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.3")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

// 项目仓库配置
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 自定义构建目录配置
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 依赖版本管理策略
subprojects {
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
    
    // 适配Kotlin路径配置
    tasks.withType<JavaCompile> {
        source = source.filter { it.exists() }
    }
    
    tasks.withType<KotlinCompile> {
        source = source.filter { it.exists() }
    }
    
    // 显式设置源代码路径
    val kotlinSrc = project.layout.projectDirectory.dir("src/main/kotlin")
    if (kotlinSrc.asFile.exists()) {
        sourceSets["main"].java.srcDirs(kotlinSrc)
    }
}

// 确保子项目依赖顺序
subprojects {
    project.evaluationDependsOn(":app")
}

// 清理任务
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}