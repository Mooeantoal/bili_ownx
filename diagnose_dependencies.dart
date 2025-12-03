import 'dart:io';

void main() async {
  print('=== 依赖冲突诊断工具 ===\n');
  
  // 1. 检查 pubspec.yaml
  await _checkPubspec();
  
  // 2. 运行 flutter pub outdated
  await _runFlutterPubOutdated();
  
  // 3. 运行 flutter pub deps
  await _runFlutterPubDeps();
  
  // 4. 检查 Android Gradle 配置
  await _checkAndroidGradle();
  
  print('\n=== 诊断完成 ===');
}

Future<void> _checkPubspec() async {
  print('1. 检查 pubspec.yaml...');
  
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('❌ pubspec.yaml 文件不存在');
    return;
  }
  
  final content = await pubspecFile.readAsString();
  
  // 检查关键依赖版本
  final dependencies = {
    'dio': r'dio:\s*\^(\d+\.\d+\.\d+)',
    'video_player': r'video_player:\s*\^(\d+\.\d+\.\d+)',
    'permission_handler': r'permission_handler:\s*\^(\d+\.\d+\.\d+)',
    'flutter_local_notifications': r'flutter_local_notifications:\s*\^(\d+\.\d+\.\d+)',
  };
  
  for (final dep in dependencies.entries) {
    final regex = RegExp(dependencies[dep.key]!);
    final match = regex.firstMatch(content);
    if (match != null) {
      print('✅ ${dep.key}: ${match.group(1)}');
    } else {
      print('❌ ${dep.key}: 未找到或版本格式错误');
    }
  }
  print('');
}

Future<void> _runFlutterPubOutdated() async {
  print('2. 检查过时的依赖...');
  
  try {
    final result = await Process.run('flutter', ['pub', 'outdated']);
    if (result.exitCode == 0) {
      print(result.stdout);
    } else {
      print('❌ flutter pub outdated 失败:');
      print(result.stderr);
    }
  } catch (e) {
    print('❌ 运行 flutter pub outdated 时出错: $e');
  }
  print('');
}

Future<void> _runFlutterPubDeps() async {
  print('3. 检查依赖树...');
  
  try {
    final result = await Process.run('flutter', ['pub', 'deps']);
    if (result.exitCode == 0) {
      print(result.stdout);
    } else {
      print('❌ flutter pub deps 失败:');
      print(result.stderr);
    }
  } catch (e) {
    print('❌ 运行 flutter pub deps 时出错: $e');
  }
  print('');
}

Future<void> _checkAndroidGradle() async {
  print('4. 检查 Android Gradle 配置...');
  
  final gradleFile = File('android/app/build.gradle.kts');
  if (!gradleFile.existsSync()) {
    print('❌ build.gradle.kts 文件不存在');
    return;
  }
  
  final content = await gradleFile.readAsString();
  
  // 检查关键配置
  final checks = {
    'dependenciesInfo': r'dependenciesInfo\s*\{',
    'resolutionStrategy': r'resolutionStrategy\s*\{',
    'compileSdk': r'compileSdk\s*=\s*flutter\.compileSdkVersion',
    'minSdk': r'minSdk\s*=\s*flutter\.minSdkVersion',
  };
  
  for (final check in checks.entries) {
    if (content.contains(RegExp(check.value))) {
      print('✅ ${check.key}: 已配置');
    } else {
      print('❌ ${check.key}: 未找到配置');
    }
  }
  print('');
}