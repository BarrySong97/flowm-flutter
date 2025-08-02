import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/database/database_provider.dart';
import 'provider_invalidator.dart';
import '../db/tables/account_table.dart';

/// 全局数据刷新服务
///
/// 用于在数据库文件同步完成后，重新初始化数据库连接并刷新所有相关的状态管理
class GlobalRefreshService {
  /// 强制数据库重新读取文件（实验性）
  ///
  /// 尝试在不关闭连接的情况下，强制数据库重新读取文件内容
  static Future<void> refreshDatabaseFile(WidgetRef ref) async {
    final startTime = DateTime.now();
    
    try {
      print('[GlobalRefreshService] 开始强制数据库文件刷新 - ${startTime.toIso8601String()}');

      // 获取当前数据库连接
      final database = ref.read(databaseProvider);
      
      // 尝试执行一些操作来强制数据库重新读取文件
      // 方法1: 执行PRAGMA命令来刷新缓存
      await database.customStatement('PRAGMA cache_size = -2000');
      await database.customStatement('PRAGMA cache_size = -10000'); // 重新设置缓存大小
      
      // 方法2: 执行一个简单的查询来测试连接
      await database.customSelect('SELECT 1').get();
      
      // 方法3: 刷新所有prepared statements
      await database.customStatement('PRAGMA compile_options');
      
      final dbRefreshEndTime = DateTime.now();
      final dbRefreshDuration = dbRefreshEndTime.difference(startTime);
      print('[GlobalRefreshService] 数据库文件刷新完成，耗时: ${dbRefreshDuration.inMilliseconds}ms');

      // 然后使用轻量级刷新
      refreshDataLight(ref);
      
      final totalDuration = DateTime.now().difference(startTime);
      print('[GlobalRefreshService] 强制数据库文件刷新总耗时: ${totalDuration.inMilliseconds}ms');
    } catch (e, stackTrace) {
      final errorDuration = DateTime.now().difference(startTime);
      print('[GlobalRefreshService] 强制数据库文件刷新失败，耗时: ${errorDuration.inMilliseconds}ms，错误: $e');
      print('[GlobalRefreshService] 错误堆栈: $stackTrace');
      
      // 如果失败，回退到完整刷新
      print('[GlobalRefreshService] 回退到完整数据刷新');
      refreshAllData(ref);
    }
  }

  /// 轻量级数据刷新（实验性）
  ///
  /// 尝试不重新创建数据库连接，只刷新provider缓存
  /// 注意：这种方法可能不适用于所有情况，特别是当数据库文件被物理替换时
  static void refreshDataLight(WidgetRef ref) {
    final startTime = DateTime.now();
    
    try {
      print('[GlobalRefreshService] 开始轻量级数据刷新 - ${startTime.toIso8601String()}');

      // 不触发数据库重新连接，只刷新数据层provider
      // 这可能适用于数据库文件没有被替换，只是内容更新的情况
      
      final invalidateStartTime = DateTime.now();
      
      // 只刷新数据初始化状态
      ref.invalidate(databaseInitializationProvider);
      
      // 刷新业务provider，让它们重新查询数据
      invalidateProvidersForTransaction(
        ref,
        fromAccountType: AccountType.ASSET,
        toAccountType: AccountType.EXPENSE,
      );
      
      final invalidateEndTime = DateTime.now();
      final invalidateDuration = invalidateEndTime.difference(invalidateStartTime);

      print('[GlobalRefreshService] 轻量级刷新完成，耗时: ${invalidateDuration.inMilliseconds}ms');
      
      final totalDuration = DateTime.now().difference(startTime);
      print('[GlobalRefreshService] 轻量级数据刷新总耗时: ${totalDuration.inMilliseconds}ms');
    } catch (e, stackTrace) {
      final errorDuration = DateTime.now().difference(startTime);
      print('[GlobalRefreshService] 轻量级刷新失败，耗时: ${errorDuration.inMilliseconds}ms，错误: $e');
      print('[GlobalRefreshService] 错误堆栈: $stackTrace');
      
      // 如果轻量级刷新失败，回退到完整刷新
      print('[GlobalRefreshService] 回退到完整数据刷新');
      refreshAllData(ref);
    }
  }

  /// 刷新整个应用的数据
  ///
  /// 当数据库文件被同步/替换后调用此方法，它会：
  /// 1. 触发数据库刷新，这会关闭旧连接并创建新连接
  /// 2. 使所有相关的状态管理 provider 失效，让它们重新获取数据
  static void refreshAllData(WidgetRef ref) {
    final startTime = DateTime.now();
    
    try {
      print('[GlobalRefreshService] 开始全局数据刷新 - ${startTime.toIso8601String()}');

      // 1. 触发数据库刷新（最关键的步骤）
      final dbRefreshStartTime = DateTime.now();
      final currentValue = ref.read(databaseRefreshTriggerProvider);
      ref.read(databaseRefreshTriggerProvider.notifier).state = currentValue + 1;
      final dbRefreshEndTime = DateTime.now();
      final dbRefreshDuration = dbRefreshEndTime.difference(dbRefreshStartTime);

      print('[GlobalRefreshService] 数据库连接刷新触发器已更新: ${currentValue + 1}，耗时: ${dbRefreshDuration.inMilliseconds}ms');

      // 2. 批量刷新核心 providers（减少单独 invalidate 调用）
      final invalidateStartTime = DateTime.now();
      
      // 只刷新最核心的providers，让数据自然流动刷新其他依赖
      ref.invalidate(databaseInitializationProvider);
      ref.invalidate(accountDaoProvider);
      ref.invalidate(transactionDaoProvider);
      ref.invalidate(postingDaoProvider);
      
      final invalidateEndTime = DateTime.now();
      final invalidateDuration = invalidateEndTime.difference(invalidateStartTime);

      print('[GlobalRefreshService] 核心 providers 已刷新，耗时: ${invalidateDuration.inMilliseconds}ms');

      // 3. 简化业务provider刷新 - 只刷新最常用的组合
      final businessProviderStartTime = DateTime.now();
      
      // 只刷新主要的业务场景，减少不必要的刷新
      invalidateProvidersForTransaction(
        ref,
        fromAccountType: AccountType.ASSET,
        toAccountType: AccountType.EXPENSE, // 最常见的支出场景
      );
      
      final businessProviderEndTime = DateTime.now();
      final businessProviderDuration = businessProviderEndTime.difference(businessProviderStartTime);

      print('[GlobalRefreshService] 业务 providers 已刷新，耗时: ${businessProviderDuration.inMilliseconds}ms');
      
      final totalDuration = DateTime.now().difference(startTime);
      print('[GlobalRefreshService] 全局数据刷新完成，总耗时: ${totalDuration.inMilliseconds}ms');
    } catch (e, stackTrace) {
      final errorDuration = DateTime.now().difference(startTime);
      print('[GlobalRefreshService] 数据刷新过程中发生错误，耗时: ${errorDuration.inMilliseconds}ms，错误: $e');
      print('[GlobalRefreshService] 错误堆栈: $stackTrace');
      rethrow;
    }
  }

  /// 异步版本的全局数据刷新
  ///
  /// 等待一个微任务周期后执行刷新，确保当前的同步操作完全完成
  static Future<void> refreshAllDataAsync(WidgetRef ref) async {
    final startTime = DateTime.now();
    print('[GlobalRefreshService] 开始异步全局数据刷新 - ${startTime.toIso8601String()}');
    
    await Future.microtask(() {
      refreshAllData(ref);
    });
    
    final totalDuration = DateTime.now().difference(startTime);
    print('[GlobalRefreshService] 异步全局数据刷新完成，总耗时: ${totalDuration.inMilliseconds}ms');
  }
}
