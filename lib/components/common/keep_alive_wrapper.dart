import 'package:flutter/material.dart';

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

class LazyLoadPageWrapper extends StatefulWidget {
  final Widget Function() builder;
  final bool isCurrentPage;

  const LazyLoadPageWrapper({
    Key? key,
    required this.builder,
    required this.isCurrentPage,
  }) : super(key: key);

  @override
  State<LazyLoadPageWrapper> createState() => _LazyLoadPageWrapperState();
}

class _LazyLoadPageWrapperState extends State<LazyLoadPageWrapper> {
  Widget? _child;

  @override
  void didUpdateWidget(LazyLoadPageWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentPage && _child == null) {
      _child = widget.builder();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_child == null) {
      return const SizedBox.shrink();
    }
    return _child!;
  }
}

class LazyPageWidget extends StatefulWidget {
  final Widget Function() builder;
  final int index;
  final PageController controller;

  const LazyPageWidget({
    Key? key,
    required this.builder,
    required this.index,
    required this.controller,
  }) : super(key: key);

  @override
  State<LazyPageWidget> createState() => _LazyPageWidgetState();
}

class _LazyPageWidgetState extends State<LazyPageWidget>
    with SingleTickerProviderStateMixin {
  Widget? _child;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // 检查是否是当前页面
    if (widget.controller.initialPage == widget.index ||
        (widget.controller.hasClients &&
            widget.controller.page?.round() == widget.index)) {
      _loadContent();
    }

    widget.controller.addListener(_onScroll);
  }

  void _loadContent() {
    if (_child != null) return;

    setState(() {
      _child = KeepAliveWrapper(
        child: widget.builder(),
      );
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final page = widget.controller.page?.round() ?? 0;
    if (page == widget.index && _child == null) {
      _loadContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_child == null) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _animation,
      child: _child!,
    );
  }
}
