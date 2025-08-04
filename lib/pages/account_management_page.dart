import 'package:flutter/material.dart';


// 树形节点数据模型
class TreeNode {
  String id;
  String name;
  String type;
  double balance;
  bool isExpanded;
  List<TreeNode> children;
  TreeNode? parent;

  TreeNode({
    required this.id,
    required this.name,
    required this.type,
    this.balance = 0.0,
    this.isExpanded = false,
    List<TreeNode>? children,
    this.parent,
  }) : children = children ?? <TreeNode>[];

  TreeNode copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    bool? isExpanded,
    List<TreeNode>? children,
    TreeNode? parent,
  }) {
    return TreeNode(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      isExpanded: isExpanded ?? this.isExpanded,
      children: children ?? List.from(this.children),
      parent: parent ?? this.parent,
    );
  }
}

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage>
    with SingleTickerProviderStateMixin {
  List<TreeNode> treeData = [];
  String? _dragOverNodeId;
  String _insertPosition = 'none'; // 'above', 'below', 'inside', 'none'

  late TabController _tabController;

  // 分类数据
  Map<String, List<TreeNode>> categorizedData = {
    '资产账户': [],
    '负债账户': [],
    '投资账户': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeMockData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeMockData() {
    // 资产账户
    categorizedData['资产账户'] = [
      TreeNode(
        id: '1.1',
        name: '现金账户',
        type: 'account',
        balance: 5000.0,
        children: [
          TreeNode(id: '1.1.1', name: '钱包现金', type: 'account', balance: 500.0),
          TreeNode(id: '1.1.2', name: '零钱', type: 'account', balance: 200.0),
        ],
      ),
      TreeNode(
        id: '1.2',
        name: '银行账户',
        type: 'account',
        balance: 25000.0,
        children: [
          TreeNode(
              id: '1.2.1', name: '工商银行', type: 'account', balance: 15000.0),
          TreeNode(
              id: '1.2.2', name: '建设银行', type: 'account', balance: 10000.0),
        ],
      ),
      TreeNode(id: '1.3', name: '支付宝', type: 'account', balance: 3000.0),
      TreeNode(id: '1.4', name: '微信钱包', type: 'account', balance: 1500.0),
    ];

    // 负债账户
    categorizedData['负债账户'] = [
      TreeNode(
        id: '2.1',
        name: '信用卡',
        type: 'account',
        balance: -8000.0,
        children: [
          TreeNode(
              id: '2.1.1', name: '招商银行信用卡', type: 'account', balance: -5000.0),
          TreeNode(
              id: '2.1.2', name: '工商银行信用卡', type: 'account', balance: -3000.0),
        ],
      ),
      TreeNode(id: '2.2', name: '房贷', type: 'account', balance: -500000.0),
      TreeNode(id: '2.3', name: '花呗', type: 'account', balance: -2000.0),
    ];

    // 投资账户
    categorizedData['投资账户'] = [
      TreeNode(id: '3.1', name: '股票账户', type: 'account', balance: 15000.0),
      TreeNode(id: '3.2', name: '基金账户', type: 'account', balance: 8000.0),
      TreeNode(id: '3.3', name: '余额宝', type: 'account', balance: 12000.0),
    ];
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
            Tab(text: '投资账户'),
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
                  _buildAccountList('投资账户'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountList(String category) {
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

  void _handleDrop(TreeNode draggedNode, TreeNode targetNode, String position) {
    if (draggedNode.id == targetNode.id) return;

    setState(() {
      // 从原位置移除
      _removeNodeFromTree(draggedNode);

      // 只支持内部插入
      if (position == 'inside') {
        _insertInside(draggedNode, targetNode);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已将 "${draggedNode.name}" 移动到 "${targetNode.name}" 账户内'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _insertInside(TreeNode draggedNode, TreeNode targetNode) {
    targetNode.children.add(draggedNode);
    draggedNode.parent = targetNode;
    // 如果目标账户未展开，自动展开
    if (!targetNode.isExpanded) {
      targetNode.isExpanded = true;
    }
  }

  void _removeNodeFromTree(TreeNode nodeToRemove) {
    // 在所有分类中查找并删除节点
    for (String category in categorizedData.keys) {
      final accounts = categorizedData[category]!;

      // 检查是否是一级账户
      if (accounts.remove(nodeToRemove)) {
        return;
      }

      // 在子树中查找
      for (var account in accounts) {
        if (_removeNodeFromSubTree(account, nodeToRemove)) {
          return;
        }
      }
    }
  }

  bool _removeNodeFromSubTree(TreeNode parent, TreeNode nodeToRemove) {
    if (parent.children.remove(nodeToRemove)) {
      return true; // 找到并删除了节点
    }

    // 继续在子节点中查找
    for (var child in parent.children) {
      if (_removeNodeFromSubTree(child, nodeToRemove)) {
        return true;
      }
    }

    return false; // 没有找到节点
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
