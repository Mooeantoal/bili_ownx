import 'dart:io';
import 'dart:convert';

/// 基于参考信息 GRADLE_BUILD_FIX_SUMMARY.md 的构建状态检查工具
void main() async {
  print('=== 基于参考信息的 Gradle 修复状态检查 ===\n');
  
  final status = {
    'referenceDoc': 'GRADLE_BUILD_FIX_SUMMARY.md',
    'checkTime': DateTime.now().toIso8601String(),
    'checks': <String, dynamic>{}
  };
  
  // 1. 检查参考文档存在性
  await _checkReferenceDoc(status);
  
  // 2. 检查依赖版本（参考信息推荐版本）
  await _checkDependencyVersions(status);
  
  // 3. 检查 Android Gradle 配置（参考信息修复配置）
  await _checkAndroidGradleConfig(status);
  
  // 4. 检查修复工具（参考信息中的工具）
  await _checkFixTools(status);
  
  // 5. 生成状态报告
  _generateStatusReport(status);
}

Future<void> _checkReferenceDoc(Map<String, dynamic> status) async {
  print('1. 检查参考文档...');
  
  final refDoc = File('GRADLE_BUILD_FIX_SUMMARY.md');
  if (refDoc.existsSync()) {
    status['checks']['referenceDoc'] = {
      'status': '✅ 存在',
      'path': refDoc.path,
      'size': '${refDoc.lengthSync()} bytes'
    };
    print('  ✅ 参考文档存在: GRADLE_BUILD_FIX_SUMMARY.md');
  } else {
    status['checks']['referenceDoc'] = {
      'status': '❌ 缺失',
      'message': '参考文档不存在，无法验证修复方案'
    };
    print('  ❌ 参考文档缺失: GRADLE_BUILD_FIX_SUMMARY.md');
  }
  print('');
}

Future<void> _checkDependencyVersions(Map<String, dynamic> status) async {
  print('2. 检查依赖版本（基于参考信息推荐）...');
  
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    status['checks']['dependencies'] = {'status': '❌ pubspec.yaml 不存在'};
    print('  ❌ pubspec.yaml 文件不存在');
    print('');
    return;
  }
  
  final content = await pubspecFile.readAsString();
  final dependencyChecks = <String, dynamic>{};
  
  // 参考信息中推荐的关键依赖版本
  final recommendedVersions = {
    'dio': '^5.7.0',
    'shared_preferences': '^2.3.2',
    'flutter_local_notifications': '^17.2.3',
    'permission_handler': '^11.3.1',
  };
  
  for (final entry in recommendedVersions.entries) {
    final pattern = RegExp('${entry.key}:\\s*\\^?(\\d+\\.\\d+\\.\\d+)');
    final match = pattern.firstMatch(content);
    
    if (match != null) {
      final currentVersion = '^${match.group(1)}';
      if (currentVersion == entry.value) {
        dependencyChecks[entry.key] = {
          'status': '✅ 符合参考信息',
          'current': currentVersion,
          'recommended': entry.value
        };
        print('  ✅ ${entry.key}: $currentVersion (符合参考信息推荐)');
      } else {
        dependencyChecks[entry.key] = {
          'status': '⚠️ 版本不匹配',
          'current': currentVersion,
          'recommended': entry.value
        };
        print('  ⚠️  ${entry.key}: $currentVersion (参考信息推荐: ${entry.value})');
      }
    } else {
      dependencyChecks[entry.key] = {
        'status': '❌ 未找到',
        'recommended': entry.value
      };
      print('  ❌ ${entry.key}: 未找到 (参考信息推荐: ${entry.value})');
    }
  }
  
  status['checks']['dependencies'] = dependencyChecks;
  print('');
}

Future<void> _checkAndroidGradleConfig(Map<String, dynamic> status) async {
  print('3. 检查 Android Gradle 配置（基于参考信息修复方案）...');
  
  final gradleFile = File('android/app/build.gradle.kts');
  if (!gradleFile.existsSync()) {
    status['checks']['androidConfig'] = {'status': '❌ build.gradle.kts 不存在'};
    print('  ❌ android/app/build.gradle.kts 文件不存在');
    print('');
    return;
  }
  
  final content = await gradleFile.readAsString();
  final configChecks = <String, dynamic>{};
  
  // 参考信息中的关键配置检查
  final criticalConfigs = {
    'dependenciesInfo': {
      'pattern': r'dependenciesInfo\s*\{',
      'description': 'AAR 元数据冲突修复'
    },
    'includeInApk': {
      'pattern': r'includeInApk\s*=\s*false',
      'description': '禁用 APK 依赖元数据'
    },
    'includeInBundle': {
      'pattern': r'includeInBundle\s*=\s*false',
      'description': '禁用 Bundle 依赖元数据'
    },
    'resolutionStrategy': {
      'pattern': r'resolutionStrategy\s*\{',
      'description': '依赖版本冲突修复'
    },
    'coreKtxForce': {
      'pattern': r'androidx\.core:core-ktx:1\.12\.0',
      'description': '强制 core-ktx 版本'
    },
    'appcompatForce': {
      'pattern': r'androidx\.appcompat:appcompat:1\.6\.1',
      'description': '强制 appcompat 版本'
    },
    'lifecycleForce': {
      'pattern': r'androidx\.lifecycle:lifecycle-runtime:2\.7\.0',
      'description': '强制 lifecycle 版本'
    }
  };
  
  for (final entry in criticalConfigs.entries) {
    if (content.contains(RegExp(entry.value['pattern']))) {
      configChecks[entry.key] = {
        'status': '✅ 已配置',
        'description': entry.value['description']
      };
      print('  ✅ ${entry.value['description']}');
    } else {
      configChecks[entry.key] = {
        'status': '❌ 缺失',
        'description': entry.value['description']
      };
      print('  ❌ ${entry.value['description']} (参考信息要求)');
    }
  }
  
  // 检查 gradle.properties
  final gradlePropsFile = File('android/gradle.properties');
  if (gradlePropsFile.existsSync()) {
    final propsContent = await gradlePropsFile.readAsString();
    final propsChecks = <String, dynamic>{};
    
    final propConfigs = {
      'buildConfig': {
        'pattern': r'android\.defaults\.buildfeatures\.buildconfig=true',
        'description': '启用 BuildConfig'
      },
      'r8FullMode': {
        'pattern': r'android\.enableR8\.fullMode=true',
        'description': '启用 R8 完整模式'
      },
      'parallelBuild': {
        'pattern': r'org\.gradle\.parallel=true',
        'description': '启用并行构建'
      },
      'gradleCaching': {
        'pattern': r'org\.gradle\.caching=true',
        'description': '启用 Gradle 缓存'
      }
    };
    
    for (final entry in propConfigs.entries) {
      if (propsContent.contains(RegExp(entry.value['pattern']))) {
        propsChecks[entry.key] = {
          'status': '✅ 已配置',
          'description': entry.value['description']
        };
        print('    ✅ ${entry.value['description']}');
      } else {
        propsChecks[entry.key] = {
          'status': '⚠️ 缺失',
          'description': entry.value['description']
        };
        print('    ⚠️  ${entry.value['description']} (参考信息推荐)');
      }
    }
    
    configChecks['gradleProperties'] = propsChecks;
  }
  
  status['checks']['androidConfig'] = configChecks;
  print('');
}

Future<void> _checkFixTools(Map<String, dynamic> status) async {
  print('4. 检查修复工具（基于参考信息）...');
  
  final tools = {
    'fix_gradle_build.sh': 'Linux/macOS 修复脚本',
    'fix_gradle_build.bat': 'Windows 修复脚本',
    'diagnose_dependencies.dart': '依赖诊断工具',
  };
  
  final toolChecks = <String, dynamic>{};
  
  for (final entry in tools.entries) {
    final toolFile = File(entry.key);
    if (toolFile.existsSync()) {
      toolChecks[entry.key] = {
        'status': '✅ 可用',
        'description': entry.value,
        'size': '${toolFile.lengthSync()} bytes'
      };
      print('  ✅ ${entry.value}: ${entry.key}');
    } else {
      toolChecks[entry.key] = {
        'status': '❌ 缺失',
        'description': entry.value
      };
      print('  ❌ ${entry.value}: ${entry.key} (参考信息工具)');
    }
  }
  
  status['checks']['fixTools'] = toolChecks;
  print('');
}

void _generateStatusReport(Map<String, dynamic> status) {
  print('=== 生成状态报告 ===');
  
  // 计算总体状态
  int totalChecks = 0;
  int passedChecks = 0;
  int warningChecks = 0;
  
  status['checks'].forEach((key, value) {
    if (value is Map) {
      value.forEach((subKey, subValue) {
        if (subValue is Map && subValue.containsKey('status')) {
          totalChecks++;
          final statusStr = subValue['status'] as String;
          if (statusStr.contains('✅')) {
            passedChecks++;
          } else if (statusStr.contains('⚠️')) {
            warningChecks++;
          }
        }
      });
    }
  });
  
  final overallStatus = passedChecks == totalChecks ? '✅ 完全符合参考信息' :
                       warningChecks > 0 ? '⚠️ 部分符合参考信息' : '❌ 需要修复';
  
  print('\n📊 总体状态: $overallStatus');
  print('   - 总检查项: $totalChecks');
  print('   - 通过项: $passedChecks');
  print('   - 警告项: $warningChecks');
  print('   - 失败项: ${totalChecks - passedChecks - warningChecks}');
  
  // 生成 JSON 报告
  final report = {
    ...status,
    'summary': {
      'overallStatus': overallStatus,
      'totalChecks': totalChecks,
      'passedChecks': passedChecks,
      'warningChecks': warningChecks,
      'failedChecks': totalChecks - passedChecks - warningChecks
    }
  };
  
  final reportFile = File('gradle-fix-status-report.json');
  reportFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  
  print('\n📄 详细报告已保存到: gradle-fix-status-report.json');
  
  // 生成建议
  print('\n💡 基于参考信息的建议:');
  if (passedChecks < totalChecks) {
    print('   1. 请参考 GRADLE_BUILD_FIX_SUMMARY.md 进行修复');
    print('   2. 确保所有依赖版本符合参考信息推荐');
    print('   3. 应用参考信息中的 Android Gradle 配置');
    print('   4. 使用参考信息中的修复工具');
  } else {
    print('   ✅ 所有配置都符合参考信息要求，构建应该能正常进行');
  }
  
  print('\n=== 检查完成 ===');
}