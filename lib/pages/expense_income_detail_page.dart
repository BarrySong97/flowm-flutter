import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flowm/components/chart/barchart.dart';

class ExpenseIncomeDetailPage extends StatefulWidget {
  const ExpenseIncomeDetailPage({Key? key}) : super(key: key);

  @override
  State<ExpenseIncomeDetailPage> createState() =>
      _ExpenseIncomeDetailPageState();
}

class _ExpenseIncomeDetailPageState extends State<ExpenseIncomeDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _scrollController.addListener(_onScroll);
    // Set status bar color to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _onScroll() {
    final bool isCollapsed = _scrollController.hasClients &&
        _scrollController.offset > (200 - kToolbarHeight);
    if (isCollapsed != _isCollapsed) {
      setState(() {
        _isCollapsed = isCollapsed;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  // Create a boolean to determine if the SliverAppBar is collapsed
                  return Stack(
                    children: [
                      // Gradient background that stays during scroll
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF0ba360),
                              Color(0xFF3cba92),
                            ],
                          ),
                        ),
                      ),
                      // Flexible space content
                      FlexibleSpaceBar(
                        background: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Placeholder for app bar height
                                SizedBox(height: kToolbarHeight),

                                // VanEck title that shows only when expanded
                                AnimatedOpacity(
                                  opacity: _isCollapsed ? 0.0 : 1.0,
                                  duration: const Duration(milliseconds: 250),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'VanEck',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.all(1),
                                        decoration: const BoxDecoration(
                                          color: Colors.white54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Balance amount
                                const Text(
                                  '\$1,376,094,538.48',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Additional info row
                                Row(
                                  children: [
                                    _buildDetailItem('本月收入', '\$32,450.00'),
                                    const SizedBox(width: 16),
                                    _buildDetailItem('本月结余', '\$12,380.85'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    size: 22, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: Colors.white, size: 22),
                  onPressed: () {},
                ),
              ],
              centerTitle: true,
              title: AnimatedOpacity(
                opacity: _isCollapsed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'VanEck',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(1),
                      decoration: const BoxDecoration(
                        color: Colors.white54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabSelector(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const MyBarChart(barColor: Color(0xFF3cba92)),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: 20, // Example: just to show scrolling
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      title: Text('Transaction $index'),
                      subtitle: Text('Details for transaction $index'),
                      leading: const Icon(Icons.payment),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Animated selection indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: _tabController.index *
                (MediaQuery.of(context).size.width - 32) /
                3,
            top: 0,
            bottom: 0,
            width: (MediaQuery.of(context).size.width - 32) / 3,
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          // Tab buttons
          Row(
            children: [
              Expanded(child: _buildTabButton('Profit & Loss', 0)),
              Expanded(child: _buildTabButton('Balance', 1)),
              Expanded(child: _buildTabButton('Token Balance', 2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Container(
        height: 40,
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _tabController.index == index ? Colors.black87 : Colors.grey,
            fontWeight: _tabController.index == index
                ? FontWeight.w600
                : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
