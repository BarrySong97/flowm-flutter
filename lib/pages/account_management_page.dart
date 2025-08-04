import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/account/account_repository.dart';
import '../state/ledger/ledger_repository.dart';
import '../components/account/account_item.dart' as account_ui;
import '../db/tables/account_table.dart';
import '../utils/provider_invalidator.dart';
import '../utils/snackbar_utils.dart';


// 树形节点数据模型，基于真实的Account数据
class TreeNode {
  final account_ui.Account account;
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
  ConsumerState<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends ConsumerState<AccountManagementPage>
    with SingleTickerProviderStateMixin {
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
  Future<void> _loadAccountData() async {
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
    return accounts.map((account) => _buildTreeNodeFromAccount(account)).toList();
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
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '长按账户拖拽到其他账户上，可将其变成子账户，最多2层结构',
                      style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.w500),
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
              onPressed: _loadAccountData,
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        return _buildTreeNode(accounts[index], 0);
      },
    );
  }

  Widget _buildTreeNode(TreeNode node, int depth) {
    return Column(
      key: ValueKey(node.id),
      children: [
        Container(
          margin: EdgeInsets.only(
            bottom: 12,
            left: depth > 0 ? 24 : 0,
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: depth == 0 ? 2 : 1,
            shadowColor: Colors.black.withValues(alpha: 0.05),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: depth > 0 
                  ? Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1)
                  : null,
              ),
              child: Draggable<TreeNode>(
                data: node,
                feedback: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                    child: _buildNodeContent(node, depth, isDragging: true),
                  ),
                ),
                childWhenDragging: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.5),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _buildNodeContent(node, depth, isPlaceholder: true),
                ),
                child: _buildDragTarget(node, depth),
              ),
            ),
          ),
        ),
        if (node.isExpanded && depth == 0)
          // 子账户容器
          Container(
            margin: const EdgeInsets.only(left: 8, bottom: 8),
            child: Column(
              children: node.children.map(
                (child) => _buildTreeNode(child, depth + 1),
              ).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildDragTarget(TreeNode node, int depth) {
    return DragTarget<TreeNode>(
      onWillAcceptWithDetails: (details) {
        final draggedNode = details.data;
        if (draggedNode.id == node.id) {
          return false;
        }

        // 检查层级限制
        return _canAcceptDrop(draggedNode, node, depth);
      },
      onAcceptWithDetails: (details) {
        _handleDrop(details.data, node, _insertPosition);
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
            color: isHovered && _insertPosition == 'inside'
                ? Colors.blue.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isHovered && _insertPosition == 'inside'
                ? Border.all(
                    color: canAccept ? Colors.blue : Colors.red, 
                    width: 2
                  )
                : null,
          ),
          child: _buildNodeContent(node, depth),
        );
      },
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

  Widget _buildNodeContent(TreeNode node, int depth,
      {bool isDragging = false, bool isPlaceholder = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 展开/折叠按钮和连接线
          if (depth == 0) ..._buildParentNodeLeading(node, isPlaceholder),
          if (depth > 0) ..._buildChildNodeLeading(node, isPlaceholder),
          
          if (depth == 0 && node.children.isEmpty)
            const SizedBox(width: 32),
          if (depth > 0)
            const SizedBox(width: 12),
          
          // 账户信息
          Expanded(
            child: Text(
              node.name,
              style: TextStyle(
                fontSize: depth == 0 ? 16 : 15,
                fontWeight: depth == 0 ? FontWeight.w600 : FontWeight.w500,
                color: isPlaceholder 
                    ? Colors.grey 
                    : Colors.black87,
              ),
            ),
          ),
          
          // 拖拽指示器
          if (!isDragging && !isPlaceholder)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.drag_indicator,
                color: Colors.grey,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildParentNodeLeading(TreeNode node, bool isPlaceholder) {
    return [
      if (node.children.isNotEmpty)
        GestureDetector(
          onTap: () {
            setState(() {
              node.isExpanded = !node.isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              node.isExpanded ? Icons.expand_less : Icons.expand_more,
              color: isPlaceholder 
                  ? Colors.grey 
                  : Colors.grey.shade600,
              size: 20,
            ),
          ),
        )
      else
        const SizedBox(width: 32),
    ];
  }
  
  List<Widget> _buildChildNodeLeading(TreeNode node, bool isPlaceholder) {
    return [
      const SizedBox(width: 24),
    ];
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

  Future<void> _handleDrop(TreeNode draggedNode, TreeNode targetNode, String position) async {
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
        fromAccountType: draggedNode.type,
        toAccountType: targetNode.type);

      // 重新加载数据
      await _loadAccountData();

      if (mounted) {
        SnackBarUtils.showOverlaySuccess(
          context, 
          '已将 "${draggedNode.name}" 移动到 "${targetNode.name}" 账户内'
        );
      }
    } catch (e) {
      // 记录错误日志
      if (mounted) {
        SnackBarUtils.showOverlayError(context, '移动账户失败: $e');
      }
    }
  }


  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.help_outline,
                color: Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '使用说明',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(Icons.tab, '使用Tab切换不同账户分类'),
            _buildHelpItem(Icons.expand_more, '点击箭头展开/折叠子账户'),  
            _buildHelpItem(Icons.drag_indicator, '长按拖拽设置子账户关系'),
            _buildHelpItem(Icons.check_circle_outline, '绿色边框表示可接收拖拽'),
            _buildHelpItem(Icons.account_tree, '支持最多2层账户结构'),
            _buildHelpItem(Icons.block, '已有子账户的不能再移动'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '我知道了',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHelpItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
