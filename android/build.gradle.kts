// 构建脚本依赖配置
buildscript {
    val kotlinVersion = "1.8.0"
    repositories {
        google()
        mavenCentral()
        // === 新增阿里云镜像源（加速依赖下载）===
        maven { url = uri("https://maven.aliyun.com/repository/public") }
    }
    dependencies {
        // === 更新AGP版本至8.12.0（与Gradle 8.13兼容）===
        classpath("com.android.tools.build:gradle:8.12.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

// 项目仓库配置
allprojects {
    repositories {
        google()
        mavenCentral()
        // === 新增阿里云镜像源 ===
        maven { url = uri("https://maven.aliyun.com/repository/public") }
    }
}

// 自定义构建目录配置（原内容保留）
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 依赖版本管理策略（原内容保留）
subprojects {
    configurations.all {
        resolutionStrategy {
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
            force("androidx.core:core-ktx:1.13.1")
            force("androidx.appcompat:appcompat:1.7.0")
            force("androidx.media3:media3-exoplayer:1.5.0")
            force("androidx.media3:media3-common:1.5.0")
            force("androidx.media3:media3-ui:1.5.0")
        }
    }
    
    // 适配Kotlin路径配置（原内容保留）
    tasks.withType<JavaCompile> {
        source = source.filter { it.exists() }
    }
    
    tasks.withType<KotlinCompile> {
        source = source.filter { it.exists() }
    }
    
    val kotlinSrc = project.layout.projectDirectory.dir("src/main/kotlin")
    if (kotlinSrc.asFile.exists()) {
        sourceSets["main"].java.srcDirs(kotlinSrc)
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
