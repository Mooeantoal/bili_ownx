// === Gradle插件导入 ===
import org.gradle.api.tasks.compile.JavaCompile
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.gradle.api.plugins.JavaPluginExtension

// 构建脚本依赖配置
buildscript {
    val kotlinVersion = "1.8.0"
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://maven.aliyun.com/repository/public") }
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.12.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

// 项目仓库配置
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://maven.aliyun.com/repository/public") }
    }
}

// 自定义构建目录配置（保留原内容）
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 依赖版本管理策略（保留原内容）
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
    
    tasks.withType<JavaCompile> {
        // Source filtering removed - not needed for standard build
    }
    
    tasks.withType<KotlinCompile> {
        // Source filtering removed - not needed for standard build
    }
    
    val kotlinSrc = project.layout.projectDirectory.dir("src/main/kotlin")
    if (kotlinSrc.asFile.exists()) {
        project.pluginManager.withPlugin("java") {
            extensions.getByType<JavaPluginExtension>().apply {
                sourceSets.getByName("main").java.srcDir(kotlinSrc)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
