import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/account/account_repository.dart';
import '../state/ledger/ledger_repository.dart';
import '../components/account/account_item.dart' as account_ui;
import '../db/tables/account_table.dart';
import '../utils/provider_invalidator.dart';
import '../utils/snackbar_utils.dart';
import '../components/common/account_creation_bottom_sheet.dart';
import '../components/common/account_update_bottom_sheet.dart';
import '../components/common/account_selector_bottom_sheet.dart';

// 树形节点数据模型，基于真实的Account数据
class TreeNode {
  account_ui.Account account;
  bool isExpanded;
  List<TreeNode> children;
  TreeNode? parent;

  TreeNode({
    required this.account,
    this.isExpanded = false,
    List<TreeNode>? children,
    this.parent,
  }) : children = children ?? <TreeNode>[];

  // 便利方法访问account属性
  int get id => account.id;
  String get name => account.name;
  AccountType get type => account.type;
  double get balance => account.amount;

  TreeNode copyWith({
    account_ui.Account? account,
    bool? isExpanded,
    List<TreeNode>? children,
    TreeNode? parent,
  }) {
    return TreeNode(
      account: account ?? this.account,
      isExpanded: isExpanded ?? this.isExpanded,
      children: children ?? List.from(this.children),
      parent: parent ?? this.parent,
    );
  }
}

class AccountManagementPage extends ConsumerStatefulWidget {
  const AccountManagementPage({super.key});

  @override
  ConsumerState<AccountManagementPage> createState() =>
      _AccountManagementPageState();
}

class _AccountManagementPageState extends ConsumerState<AccountManagementPage>
    with TickerProviderStateMixin {
  List<TreeNode> treeData = [];
  int? _dragOverNodeId;
  String _insertPosition = 'none'; // 'above', 'below', 'inside', 'none'

  late TabController _tabController;

  // 分类数据
  Map<String, List<TreeNode>> categorizedData = {
    '资产账户': [],
    '负债账户': [],
    '支出账户': [],
    '收入账户': [],
  };

  // 加载状态
  bool _isLoading = true;
  String? _errorMessage;

  // 保存展开状态
  final Map<int, bool> _expandedState = {};

  // 排序状态
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAccountData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 加载真实账户数据
  Future<void> _loadAccountData({bool preserveExpansion = false}) async {
    // 如果需要保持展开状态，先保存当前状态
    if (preserveExpansion && !_isLoading) {
      _saveExpandedState();
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final futures = await Future.wait([
        ref.read(assetsAccountTreeProvider.future),
        ref.read(liabilityAccountTreeProvider.future),
        ref.read(expenseAccountTreeProvider.future),
        ref.read(incomeAccountTreeProvider.future),
      ]);

      if (mounted) {
        setState(() {
          categorizedData['资产账户'] = _buildTreeFromAccounts(futures[0]);
          categorizedData['负债账户'] = _buildTreeFromAccounts(futures[1]);
          categorizedData['支出账户'] = _buildTreeFromAccounts(futures[2]);
          categorizedData['收入账户'] = _buildTreeFromAccounts(futures[3]);
          _isLoading = false;
        });

        // 如果需要保持展开状态，恢复之前的状态
        if (preserveExpansion) {
          _restoreExpandedState();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载账户数据失败: $e';
          _isLoading = false;
        });
        SnackBarUtils.showOverlayError(context, '加载账户数据失败');
      }
    }
  }

  // 将Account列表转换为TreeNode树形结构
  List<TreeNode> _buildTreeFromAccounts(List<account_ui.Account> accounts) {
    return accounts
        .map((account) => _buildTreeNodeFromAccount(account))
        .toList();
  }

  // 递归构建TreeNode
  TreeNode _buildTreeNodeFromAccount(account_ui.Account account) {
    TreeNode node = TreeNode(account: account);

    if (account.children != null && account.children!.isNotEmpty) {
      for (var child in account.children!) {
        TreeNode childNode = _buildTreeNodeFromAccount(child);
        childNode.parent = node;
        node.children.add(childNode);
      }
    }

    return node;
  }

  // 保存当前展开状态
  void _saveExpandedState() {
    _expandedState.clear();
    for (String category in categorizedData.keys) {
      for (TreeNode node in categorizedData[category]!) {
        _saveNodeExpandedState(node);
      }
    }
  }

  void _saveNodeExpandedState(TreeNode node) {
    _expandedState[node.id] = node.isExpanded;
    for (TreeNode child in node.children) {
      _saveNodeExpandedState(child);
    }
  }

  // 恢复展开状态
  void _restoreExpandedState() {
    for (String category in categorizedData.keys) {
      for (TreeNode node in categorizedData[category]!) {
        _restoreNodeExpandedState(node);
      }
    }
  }

  void _restoreNodeExpandedState(TreeNode node) {
    if (_expandedState.containsKey(node.id)) {
      node.isExpanded = _expandedState[node.id]!;
    }
    for (TreeNode child in node.children) {
      _restoreNodeExpandedState(child);
    }
  }

  // 根据当前tab索引获取对应的AccountSelectorType
  AccountSelectorType _getCurrentAccountSelectorType() {
    switch (_tabController.index) {
      case 0: // 资产账户
        return AccountSelectorType.asset;
      case 1: // 负债账户
        return AccountSelectorType.liability;
      case 2: // 支出账户
        return AccountSelectorType.expense;
      case 3: // 收入账户
        return AccountSelectorType.income;
      default:
        return AccountSelectorType.asset; // 默认为资产账户
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账户管理'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAccountCreationBottomSheet();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          dividerColor: Colors.transparent, // 消除tab下面的border
          splashFactory: NoSplash.splashFactory, // 禁用点击时的绿色splash效果
          overlayColor: WidgetStateProperty.all(Colors.transparent), // 禁用悬停效果
          tabs: const [
            Tab(text: '资产账户'),
            Tab(text: '负债账户'),
            Tab(text: '支出账户'),
            Tab(text: '收入账户'),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF5F6FB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '长按账户拖拽到其他账户上，可将其变成子账户，最多2层结构；点击账户可以编辑',
                      style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAccountList('资产账户'),
                  _buildAccountList('负债账户'),
                  _buildAccountList('支出账户'),
                  _buildAccountList('收入账户'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountList(String category) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadAccountData(),
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    final accounts = categorizedData[category] ?? [];

    if (accounts.isEmpty) {
      return const Center(
        child: Text(
          '暂无账户',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    // 使用类似assets_page的CustomScrollView结构
    return CustomScrollView(
      slivers: [
        // 排序控制区域
        SliverPadding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$category列表',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                GestureDetector(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      Icon(
                        _isAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      Text(
                        _isAscending ? '升序' : '降序',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _isAscending = !_isAscending;
                    });
                  },
                )
              ],
            ),
          ),
        ),
        // 账户列表
        SliverPadding(
          padding: const EdgeInsets.only(
              top: 16, bottom: 16.0, left: 16, right: 16),
          sliver: _buildAccountSliverList(accounts),
        ),
      ],
    );
  }

  /// 构建账户Sliver列表 
  SliverList _buildAccountSliverList(List<TreeNode> accounts) {
    final double totalTopLevelAmount = accounts
        .fold(0.0, (sum, node) => sum + node.account.amount.abs());

    // 直接在原有节点上更新百分比信息，避免创建新对象导致状态丢失
    for (var node in accounts) {
      double percentage = totalTopLevelAmount == 0
          ? 0.0
          : (node.account.amount.abs() / totalTopLevelAmount) * 100;
      
      // 更新账户的百分比信息
      node.account = account_ui.Account(
        id: node.account.id,
        name: node.account.name,
        amount: node.account.amount,
        type: node.account.type,
        icon: node.account.icon,
        children: node.account.children,
        currencySymbol: node.account.currencySymbol,
        percentage: percentage,
      );
    }

    // 根据排序状态排序（直接排序原数组，保持TreeNode对象不变）
    accounts.sort((a, b) {
      if (_isAscending) {
        return a.account.amount.compareTo(b.account.amount);
      } else {
        return b.account.amount.compareTo(a.account.amount);
      }
    });

    return SliverList.builder(
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final node = accounts[index];
        return _buildEnhancedTreeNode(node, 0);
      },
    );
  }

  Widget _buildEnhancedTreeNode(TreeNode node, int depth) {
    return Column(
      children: [
        // 主账户项，使用AccountItem样式但支持拖拽
        _buildAccountItemWithDrag(node, depth),
        // 展开的子账户 - 只有顶级账户(depth == 0)才能展开，仅高度动画
        if (depth == 0 && node.children.isNotEmpty)
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              heightFactor: node.isExpanded ? 1.0 : 0.0,
              widthFactor: 1.0, // 宽度保持不变
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: node.children.map((child) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                    child: _buildAccountItemWithDrag(child, depth + 1),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAccountItemWithDrag(TreeNode node, int depth) {
    bool canDrag = node.children.isEmpty; // 只有没有子节点的账户可以拖拽

    Widget accountCard = Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: depth == 0 ? 2 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: _buildAccountRowContent(node, depth),
    );

    if (canDrag) {
      return LongPressDraggable<TreeNode>(
        data: node,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          shadowColor: Colors.black.withValues(alpha: 0.2),
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 64,
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              child: _buildAccountRowContent(node, depth, isDragging: true),
            ),
          ),
        ),
        childWhenDragging: Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          elevation: 0,
          color: Colors.grey.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(
              color: Colors.grey.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: _buildAccountRowContent(node, depth, isPlaceholder: true),
        ),
        child: _buildDragTargetWrapper(accountCard, node, depth),
      );
    } else {
      return _buildDragTargetWrapper(accountCard, node, depth);
    }
  }

  Widget _buildDragTargetWrapper(Widget child, TreeNode node, int depth) {
    return DragTarget<TreeNode>(
      onWillAcceptWithDetails: (details) {
        final draggedNode = details.data;
        return _canAcceptDrop(draggedNode, node, depth);
      },
      onAcceptWithDetails: (details) {
        _handleDrop(details.data, node, 'inside');
        setState(() {
          _dragOverNodeId = null;
          _insertPosition = 'none';
        });
      },
      onMove: (details) {
        _updateDropPosition(details, node);
      },
      onLeave: (data) {
        setState(() {
          _dragOverNodeId = null;
          _insertPosition = 'none';
        });
      },
      builder: (context, candidateData, rejectedData) {
        bool isHovered = _dragOverNodeId == node.id;
        bool canAccept = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isHovered && _insertPosition == 'inside'
                ? Border.all(
                    color: canAccept ? Colors.blue : Colors.red, 
                    width: 2,
                  )
                : null,
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildAccountRowContent(TreeNode node, int depth, {bool isDragging = false, bool isPlaceholder = false}) {
    bool hasChildren = node.children.isNotEmpty;
    
    return InkWell(
      onTap: () {
        if (depth == 0 && hasChildren) {
          setState(() {
            node.isExpanded = !node.isExpanded;
          });
        } else {
          _showAccountUpdateBottomSheet(node);
        }
      },
      onLongPress: (depth == 0 && hasChildren) ? () => _showAccountUpdateBottomSheet(node) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // 展开/折叠按钮 - 只有顶级账户(depth == 0)且有子账户时才显示
            if (depth == 0 && hasChildren) ...[
              GestureDetector(
                onTap: () {
                  setState(() {
                    node.isExpanded = !node.isExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: AnimatedRotation(
                    turns: node.isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      color: isPlaceholder ? Colors.grey : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ] else if (depth == 0) ...[
              const SizedBox(width: 44), // 占位空间，仅对顶级账户
            ],
            
            // 账户图标
            if (node.account.icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  node.account.icon,
                  size: 20,
                  color: isPlaceholder ? Colors.grey : Colors.grey.shade600,
                ),
              ),
            ],
            
            // 账户名称和金额
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.account.name,
                    style: TextStyle(
                      fontSize: depth == 0 ? 16 : 15,
                      fontWeight: depth == 0 ? FontWeight.w600 : FontWeight.w500,
                      color: isPlaceholder ? Colors.grey : Colors.black87,
                    ),
                  ),
                  if (node.account.percentage != null && depth == 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${node.account.percentage!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPlaceholder ? Colors.grey : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // 金额显示
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${node.account.currencySymbol}${node.account.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: depth == 0 ? 16 : 15,
                    fontWeight: FontWeight.w600,
                    color: isPlaceholder 
                        ? Colors.grey 
                        : node.account.amount >= 0 
                            ? Colors.green.shade600 
                            : Colors.red.shade600,
                  ),
                ),
              ],
            ),
            
            // 拖拽指示器
            if (!isDragging && !isPlaceholder && !hasChildren) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.drag_indicator,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  // 检查是否可以接受拖拽放置
  bool _canAcceptDrop(
      TreeNode draggedNode, TreeNode targetNode, int targetDepth) {
    // 1. 不能拖拽到自己
    if (draggedNode.id == targetNode.id) return false;

    // 2. 不能拖拽到自己的子节点中（防止循环引用）
    if (_isDescendant(targetNode, draggedNode)) return false;

    // 3. 检查目标是否是一级账户
    bool isTopLevelAccount = false;
    for (String category in categorizedData.keys) {
      if (categorizedData[category]!.contains(targetNode)) {
        isTopLevelAccount = true;
        break;
      }
    }

    // 4. 只有一级账户可以接受子节点
    if (!isTopLevelAccount) return false;

    // 5. 检查被拖拽的节点是否已有子节点（防止超过两级结构）
    if (draggedNode.children.isNotEmpty) {
      return false; // 已有子节点的账户不能再作为子账户
    }

    return true;
  }

  // 检查targetNode是否是draggedNode的后代
  bool _isDescendant(TreeNode targetNode, TreeNode draggedNode) {
    for (var child in draggedNode.children) {
      if (child.id == targetNode.id) return true;
      if (_isDescendant(targetNode, child)) return true;
    }
    return false;
  }


  void _updateDropPosition(DragTargetDetails details, TreeNode targetNode) {
    setState(() {
      _dragOverNodeId = targetNode.id;

      // 检查目标是否是一级账户（在categorizedData中的直接子项）
      bool isTopLevelAccount = false;
      for (String category in categorizedData.keys) {
        if (categorizedData[category]!.contains(targetNode)) {
          isTopLevelAccount = true;
          break;
        }
      }

      // 一级账户可以接受内部插入，二级账户不能再有子账户
      if (isTopLevelAccount) {
        _insertPosition = 'inside';
      } else {
        // 二级账户不能作为父节点，但仍然可以显示拖拽状态
        _insertPosition = 'none';
      }
    });
  }

  Future<void> _handleDrop(
      TreeNode draggedNode, TreeNode targetNode, String position) async {
    if (draggedNode.id == targetNode.id) return;

    try {
      // 调用真实的数据库更新
      await ref.read(accountRepositoryProvider).editAccount(
            accountId: draggedNode.id,
            name: draggedNode.name,
            type: draggedNode.type,
            ledgerId: (await ref.read(selectedLedgerProvider.future))!.ledgerId,
            parentId: position == 'inside' ? targetNode.id : null,
          );

      // 刷新账户数据
      invalidateProvidersForTransaction(ref,
          fromAccountType: draggedNode.type, toAccountType: targetNode.type);

      // 重新加载数据
      await _loadAccountData(preserveExpansion: true);

      if (mounted) {
        SnackBarUtils.showOverlaySuccess(
            context, '已将 "${draggedNode.name}" 移动到 "${targetNode.name}" 账户内');
      }
    } catch (e) {
      // 记录错误日志
      if (mounted) {
        SnackBarUtils.showOverlayError(context, '移动账户失败: $e');
      }
    }
  }

  // 显示账户创建底部表单
  void _showAccountCreationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AccountCreationBottomSheet(
          defaultAccountType: _getCurrentAccountSelectorType(),
        ),
      ),
    ).then((_) {
      // 账户创建后刷新数据
      _loadAccountData(preserveExpansion: true);
    });
  }

  // 显示账户更新底部表单
  void _showAccountUpdateBottomSheet(TreeNode node) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AccountUpdateBottomSheet(accountToUpdate: node.account),
      ),
    ).then((_) {
      // 账户更新后刷新数据
      _loadAccountData(preserveExpansion: true);
    });
  }
}
