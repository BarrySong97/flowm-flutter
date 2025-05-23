import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../db/dao/account_dao.dart';
import '../../db/dao/posting_dao.dart';
import '../database/database_provider.dart';
import '../../db/app_database.dart';
import '../../db/tables/account_table.dart';
import 'package:sankey_flutter/sankey_node.dart';
import 'package:sankey_flutter/sankey_link.dart';

/// 资产仓库提供者，用于封装资产相关的数据库操作和业务逻辑
final assetsRepositoryProvider = Provider<AssetsRepository>((ref) {
  final accountDao = ref.watch(accountDaoProvider);
  final postingDao = ref.watch(postingDaoProvider);
  return AssetsRepository(accountDao, postingDao);
});

/// 资产流转数据
class AssetFlow {
  final Account fromAccount;
  final Account toAccount;
  final double amount;
  final DateTime transactionDate;
  final String? description;

  AssetFlow({
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.transactionDate,
    this.description,
  });
}

/// Sankey 图表数据
class SankeyChartData {
  final List<SankeyNode> nodes;
  final List<SankeyLink> links;

  SankeyChartData({
    required this.nodes,
    required this.links,
  });
}

/// 资产仓库类
///
/// 封装与资产分析和管理相关的所有数据库操作，提供更高级别的业务逻辑方法
class AssetsRepository {
  final AccountDao _accountDao;
  final PostingDao _postingDao;

  AssetsRepository(this._accountDao, this._postingDao);

  /// 获取指定账户的资产流转数据并转换为 Sankey 图表格式
  ///
  /// [accountId] 目标账户ID
  /// [flow] 流转方向，'in' 表示流入，'out' 表示流出
  /// [limit] 限制返回的交易数量，默认为100
  /// [startDate] 开始日期
  /// [endDate] 结束日期
  Future<SankeyChartData> getAccountFlowForSankey({
    required int accountId,
    required String flow, // 'in' | 'out'
    int limit = 100,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // 获取目标账户信息
    final targetAccount = await _accountDao.getAccountById(accountId);
    if (targetAccount == null) {
      return SankeyChartData(nodes: [], links: []);
    }

    // 获取相关的资产流转数据
    final flows = await _getAssetFlows(
      accountId: accountId,
      flow: flow,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );

    // 转换为 Sankey 图表数据
    return await _convertToSankeyData(flows, targetAccount, flow);
  }

  /// 获取资产流转数据
  Future<List<AssetFlow>> _getAssetFlows({
    required int accountId,
    required String flow,
    int limit = 100,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String dateFilter = '';
    List<Variable> variables = [Variable.withInt(accountId)];

    if (startDate != null && endDate != null) {
      dateFilter = ' AND t.transaction_date BETWEEN ? AND ?';
      variables.addAll([
        Variable.withDateTime(startDate),
        Variable.withDateTime(endDate),
      ]);
    }

    String query;
    if (flow == 'in') {
      // 查询流入：目标账户作为借方（正数金额）
      query = '''
        SELECT 
          p1.posting_id as source_posting_id,
          p1.account_id as source_account_id,
          a1.account_name as source_account_name,
          a1.account_type as source_account_type,
          a1.parent_account_id as source_parent_account_id,
          a1.full_path as source_full_path,
          p2.posting_id as target_posting_id,
          p2.account_id as target_account_id,
          a2.account_name as target_account_name,
          a2.account_type as target_account_type,
          a2.parent_account_id as target_parent_account_id,
          a2.full_path as target_full_path,
          ABS(p2.amount) as amount,
          t.transaction_date,
          t.description
        FROM postings p1
        JOIN transactions t ON p1.transaction_id = t.transaction_id
        JOIN postings p2 ON p1.transaction_id = p2.transaction_id
        JOIN accounts a1 ON p1.account_id = a1.account_id
        JOIN accounts a2 ON p2.account_id = a2.account_id
        WHERE p2.account_id = ? 
          AND p2.amount > 0 
          AND p1.amount < 0
          AND p1.account_id != p2.account_id
          $dateFilter
        ORDER BY t.transaction_date DESC
        LIMIT $limit
      ''';
    } else {
      // 查询流出：目标账户作为贷方（负数金额）
      query = '''
        SELECT 
          p1.posting_id as source_posting_id,
          p1.account_id as source_account_id,
          a1.account_name as source_account_name,
          a1.account_type as source_account_type,
          a1.parent_account_id as source_parent_account_id,
          a1.full_path as source_full_path,
          p2.posting_id as target_posting_id,
          p2.account_id as target_account_id,
          a2.account_name as target_account_name,
          a2.account_type as target_account_type,
          a2.parent_account_id as target_parent_account_id,
          a2.full_path as target_full_path,
          ABS(p1.amount) as amount,
          t.transaction_date,
          t.description
        FROM postings p1
        JOIN transactions t ON p1.transaction_id = t.transaction_id
        JOIN postings p2 ON p1.transaction_id = p2.transaction_id
        JOIN accounts a1 ON p1.account_id = a1.account_id
        JOIN accounts a2 ON p2.account_id = a2.account_id
        WHERE p1.account_id = ? 
          AND p1.amount < 0 
          AND p2.amount > 0
          AND p1.account_id != p2.account_id
          $dateFilter
        ORDER BY t.transaction_date DESC
        LIMIT $limit
      ''';
    }

    final results =
        await _accountDao.customSelect(query, variables: variables).get();

    return results.map((row) {
      final sourceAccount = Account(
        accountId: row.read<int>('source_account_id'),
        ledgerId: 0, // 这里可以根据需要优化
        parentAccountId: row.read<int?>('source_parent_account_id'),
        accountName: row.read<String>('source_account_name'),
        fullPath: row.read<String>('source_full_path'),
        accountType: AccountType.values.firstWhere(
          (e) => e.name == row.read<String>('source_account_type'),
        ),
        isActive: true,
        createdAt: DateTime.now(),
      );

      final targetAccount = Account(
        accountId: row.read<int>('target_account_id'),
        ledgerId: 0,
        parentAccountId: row.read<int?>('target_parent_account_id'),
        accountName: row.read<String>('target_account_name'),
        fullPath: row.read<String>('target_full_path'),
        accountType: AccountType.values.firstWhere(
          (e) => e.name == row.read<String>('target_account_type'),
        ),
        isActive: true,
        createdAt: DateTime.now(),
      );

      return AssetFlow(
        fromAccount: sourceAccount,
        toAccount: targetAccount,
        amount: row.read<double>('amount'),
        transactionDate: row.read<DateTime>('transaction_date'),
        description: row.read<String?>('description'),
      );
    }).toList();
  }

  /// 将资产流转数据转换为 Sankey 图表数据（支持层级关系）
  Future<SankeyChartData> _convertToSankeyData(
    List<AssetFlow> flows,
    Account targetAccount,
    String flow,
  ) async {
    print('\n=== AssetsRepository 金额计算调试 ===');
    print(
        '目标账户: ${targetAccount.accountName} (ID: ${targetAccount.accountId})');
    print('流向: $flow');
    print('原始流转数据 (${flows.length}条):');

    for (int i = 0; i < flows.length; i++) {
      final assetFlow = flows[i];
      print(
          '  ${i + 1}. ${assetFlow.fromAccount.accountName} → ${assetFlow.toAccount.accountName}: ¥${assetFlow.amount.toStringAsFixed(2)}');
    }

    if (flows.isEmpty) {
      print('无流转数据');
      return SankeyChartData(nodes: [], links: []);
    }

    // 收集所有相关的账户
    final Set<int> allAccountIds = {};
    final Map<int, Account> accountMap = {};
    final Map<String, double> linkAmounts = {}; // 用于聚合相同链接的金额
    final Map<int, double> nodeAmounts = {}; // 用于计算节点金额

    // 添加目标账户
    allAccountIds.add(targetAccount.accountId);
    accountMap[targetAccount.accountId] = targetAccount;

    // 收集所有相关账户
    for (final assetFlow in flows) {
      allAccountIds.add(assetFlow.fromAccount.accountId);
      allAccountIds.add(assetFlow.toAccount.accountId);
      accountMap[assetFlow.fromAccount.accountId] = assetFlow.fromAccount;
      accountMap[assetFlow.toAccount.accountId] = assetFlow.toAccount;
    }

    // 获取所有父级账户
    await _loadParentAccounts(allAccountIds, accountMap);

    // 创建层级链接
    final hierarchicalLinks = _createHierarchicalLinks(
        flows, accountMap, targetAccount.accountId, flow);

    print('\n层级链接 (${hierarchicalLinks.length}条):');
    for (int i = 0; i < hierarchicalLinks.length; i++) {
      final link = hierarchicalLinks[i];
      final sourceName = accountMap[link.sourceId]?.accountName ?? 'Unknown';
      final targetName = accountMap[link.targetId]?.accountName ?? 'Unknown';
      print(
          '  ${i + 1}. $sourceName (${link.sourceId}) → $targetName (${link.targetId}): ¥${link.amount.toStringAsFixed(2)}');
    }

    // 聚合相同的链接和计算节点金额
    for (final link in hierarchicalLinks) {
      final linkKey = '${link.sourceId}->${link.targetId}';
      linkAmounts[linkKey] = (linkAmounts[linkKey] ?? 0) + link.amount;

      // 计算节点金额
      if (flow == 'in') {
        // 流入场景：源账户显示流出金额
        nodeAmounts[link.sourceId] =
            (nodeAmounts[link.sourceId] ?? 0) + link.amount;
      } else {
        // 流出场景：目标账户显示流入金额
        nodeAmounts[link.targetId] =
            (nodeAmounts[link.targetId] ?? 0) + link.amount;
      }
    }

    print('\n聚合后的链接:');
    linkAmounts.forEach((linkKey, amount) {
      final parts = linkKey.split('->');
      final sourceId = int.parse(parts[0]);
      final targetId = int.parse(parts[1]);
      final sourceName = accountMap[sourceId]?.accountName ?? 'Unknown';
      final targetName = accountMap[targetId]?.accountName ?? 'Unknown';
      print('  $sourceName → $targetName: ¥${amount.toStringAsFixed(2)}');
    });

    // 移除为账户设置余额的逻辑，只显示实际流转金额

    print('\n最终节点金额:');
    nodeAmounts.forEach((accountId, amount) {
      final accountName = accountMap[accountId]?.accountName ?? 'Unknown';
      print('  $accountName: ¥${amount.toStringAsFixed(2)}');
    });

    // 创建 SankeyNode 列表，只显示实际流转金额
    final nodes = accountMap.values.map((account) {
      final amount = nodeAmounts[account.accountId] ?? 0.0;

      // 账户名称只显示两个字
      String accountName = account.accountName;
      if (accountName.length > 2) {
        accountName = accountName.substring(0, 2);
      }

      // 目标账户不显示金额，其他账户显示实际流转金额
      String formattedAmount = '';
      if (account.accountId != targetAccount.accountId && amount > 0) {
        if (amount >= 1000000) {
          // 百万级，固定两位小数
          final millions = amount / 1000000;
          formattedAmount = ' (¥${millions.toStringAsFixed(2)}M)';
        } else if (amount >= 1000) {
          // 千级，固定两位小数
          final thousands = amount / 1000;
          formattedAmount = ' (¥${thousands.toStringAsFixed(2)}K)';
        } else {
          // 小额，固定两位小数
          formattedAmount = ' (¥${amount.toStringAsFixed(2)})';
        }
      }

      return SankeyNode(
        id: account.accountId,
        label: '$accountName$formattedAmount',
      );
    }).toList();

    // 创建节点ID到节点的映射
    final Map<int, SankeyNode> nodeMap = {
      for (final node in nodes) node.id: node
    };

    // 创建 SankeyLink 列表
    final links = <SankeyLink>[];
    linkAmounts.forEach((linkKey, amount) {
      final parts = linkKey.split('->');
      final sourceId = int.parse(parts[0]);
      final targetId = int.parse(parts[1]);

      final sourceNode = nodeMap[sourceId];
      final targetNode = nodeMap[targetId];

      if (sourceNode != null && targetNode != null) {
        links.add(SankeyLink(
          source: sourceNode,
          target: targetNode,
          value: amount,
        ));
      }
    });

    return SankeyChartData(
      nodes: nodes,
      links: links,
    );
  }

  /// 加载父级账户信息
  Future<void> _loadParentAccounts(
      Set<int> accountIds, Map<int, Account> accountMap) async {
    final parentIds = <int>{};

    // 收集所有父级账户ID
    for (final account in accountMap.values) {
      if (account.parentAccountId != null) {
        parentIds.add(account.parentAccountId!);
      }
    }

    // 递归加载父级账户
    while (parentIds.isNotEmpty) {
      final currentBatchIds = parentIds.toList();
      parentIds.clear();

      for (final parentId in currentBatchIds) {
        if (!accountMap.containsKey(parentId)) {
          final parentAccount = await _accountDao.getAccountById(parentId);
          if (parentAccount != null) {
            accountMap[parentId] = parentAccount;
            if (parentAccount.parentAccountId != null) {
              parentIds.add(parentAccount.parentAccountId!);
            }
          }
        }
      }
    }
  }

  /// 创建层级链接
  List<HierarchicalLink> _createHierarchicalLinks(
    List<AssetFlow> flows,
    Map<int, Account> accountMap,
    int targetAccountId,
    String flow,
  ) {
    final List<HierarchicalLink> links = [];

    for (final assetFlow in flows) {
      if (flow == 'in') {
        // 流入：其他账户 -> 层级 -> 目标账户
        final sourceAccount = assetFlow.fromAccount;
        final amount = assetFlow.amount;

        // 创建从源账户到其父级账户的链接（如果有父级）
        int currentAccountId = sourceAccount.accountId;
        double currentAmount = amount;

        while (true) {
          final currentAccount = accountMap[currentAccountId];
          if (currentAccount?.parentAccountId != null) {
            // 子级 -> 父级
            links.add(HierarchicalLink(
              sourceId: currentAccountId,
              targetId: currentAccount!.parentAccountId!,
              amount: currentAmount,
            ));
            currentAccountId = currentAccount.parentAccountId!;
          } else {
            // 最终 -> 目标账户
            links.add(HierarchicalLink(
              sourceId: currentAccountId,
              targetId: targetAccountId,
              amount: currentAmount,
            ));
            break;
          }
        }
      } else {
        // 流出：目标账户 -> 层级 -> 其他账户
        final destinationAccount = assetFlow.toAccount;
        final amount = assetFlow.amount;

        // 获取目标账户到最终账户的层级路径
        final destinationPath =
            _getAccountPath(destinationAccount.accountId, accountMap);

        // 从目标账户开始流向最终账户的层级
        int previousAccountId = targetAccountId;

        // 反向遍历路径（从最深层级到根），创建链接
        for (int i = destinationPath.length - 1; i >= 0; i--) {
          final currentAccountId = destinationPath[i];

          links.add(HierarchicalLink(
            sourceId: previousAccountId,
            targetId: currentAccountId,
            amount: amount,
          ));

          previousAccountId = currentAccountId;
        }
      }
    }

    return links;
  }

  /// 获取从账户到根的路径（从子到父）
  List<int> _getAccountPath(int accountId, Map<int, Account> accountMap) {
    final List<int> path = [];
    int? currentId = accountId;

    while (currentId != null) {
      path.add(currentId);
      final account = accountMap[currentId];
      currentId = account?.parentAccountId;
    }

    return path;
  }
}

/// 层级链接辅助类
class HierarchicalLink {
  final int sourceId;
  final int targetId;
  final double amount;

  HierarchicalLink({
    required this.sourceId,
    required this.targetId,
    required this.amount,
  });
}

/*
使用示例：

// 在您的 Widget 中使用 ConsumerWidget
class AssetFlowChart extends ConsumerWidget {
  final int accountId;
  final String flow; // 'in' 或 'out'

  const AssetFlowChart({
    Key? key,
    required this.accountId,
    required this.flow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsRepository = ref.watch(assetsRepositoryProvider);

    return FutureBuilder<SankeyChartData>(
      future: assetsRepository.getAccountFlowForSankey(
        accountId: accountId,
        flow: flow,
        limit: 50, // 可选：限制交易数量
        startDate: DateTime.now().subtract(Duration(days: 30)), // 可选：开始日期
        endDate: DateTime.now(), // 可选：结束日期
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        
        if (snapshot.hasError) {
          return Text('错误: ${snapshot.error}');
        }
        
        if (!snapshot.hasData || snapshot.data!.nodes.isEmpty) {
          return Text('暂无数据');
        }

        final sankeyData = snapshot.data!;
        
        // 使用您现有的 SankeyChart 组件
        return SankeyDiagramWidget(
          data: SankeyDataSet(
            nodes: sankeyData.nodes,
            links: sankeyData.links,
          ),
          nodeColors: generateDefaultNodeColorMap(sankeyData.nodes),
          selectedNodeId: null,
          onNodeTap: (nodeId) {
            // 处理节点点击事件
            print('点击了节点: $nodeId');
          },
          size: Size(400, 300),
        );
      },
    );
  }
}

// 在页面中使用：
AssetFlowChart(
  accountId: 123, // 您的账户ID
  flow: 'in', // 或 'out'
)
*/
