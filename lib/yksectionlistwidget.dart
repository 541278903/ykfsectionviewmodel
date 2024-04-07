library ykfsectionviewmodel;

import 'package:flutter/material.dart';

enum YKSectionListHeaderFooterType {
  header,
  footer,
}

class YKSectionListViewModel {

  final Function(Function(bool noMoreData) noMoreDataCallBack) loadCallBack;

  final Widget Function(int index) widgetOfIndexCallBack;

  final int Function() numberOfItemCallBack;

  Widget Function()? headerCallCallBack;

  Widget Function()? footerCallCallBack;

  bool Function(YKSectionListHeaderFooterType type)? showHeaderFooterWidgetWhenNoDataCallBack;

  YKSectionListViewModel({required this.loadCallBack, required this.widgetOfIndexCallBack, required this.numberOfItemCallBack,this.headerCallCallBack, this.footerCallCallBack, this.showHeaderFooterWidgetWhenNoDataCallBack});
}

class YKSectionListWidget extends StatefulWidget {
  final bool _keepAlive = true;

  Widget Function(ScrollView scrollView)? setupScrollView;

  List<YKSectionListViewModel> viewModels = [];

  YKSectionListWidget({super.key, required this.viewModels, this.setupScrollView});

  @override
  State<YKSectionListWidget> createState() => _YKSectionListWidgetState();
}

class _YKSectionListWidgetState extends State<YKSectionListWidget> with AutomaticKeepAliveClientMixin {
  List<List<Widget>> _list = [];

  @override
  Widget build(BuildContext context) {
    return _main();
  }

  @override
  void initState() {
    super.initState();
    _refresh();
    _loadAllData();
  }

  Widget _main() {
    List<Widget> alllist = [];

    for (var list in _list) {
      for (Widget widget in list) {
        alllist.add(widget);
      }
    }

    CustomScrollView mainWidget = CustomScrollView(
      slivers: [SliverList(delegate: SliverChildListDelegate(alllist))],
    );

    if (widget.setupScrollView != null) {
      return widget.setupScrollView!(mainWidget);
    } else {
      return mainWidget;
    }
  }

  List<Widget> _setup(YKSectionListViewModel viewModel) {
    List<Widget> widgets = [];

    Widget? header = null;
    if (viewModel.headerCallCallBack != null) {
      header = viewModel.headerCallCallBack!();
    }

    var widget = ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: viewModel.numberOfItemCallBack!(),
        itemBuilder: (context, i) {
          return viewModel.widgetOfIndexCallBack!(i);
        });

    Widget? footer = null;
    if (viewModel.footerCallCallBack != null) {
      footer = viewModel.footerCallCallBack!();
    }

    if (header != null) {
      if (viewModel.numberOfItemCallBack!() <= 0) {
        if (viewModel.showHeaderFooterWidgetWhenNoDataCallBack != null) {
          if (viewModel.showHeaderFooterWidgetWhenNoDataCallBack!(YKSectionListHeaderFooterType.header)) {
            widgets.add(header);
          }
        }
      } else {
        widgets.add(header);
      }
    }
    widgets.add(widget);
    if (footer != null) {
      if (viewModel.numberOfItemCallBack!() <= 0) {
        if (viewModel.showHeaderFooterWidgetWhenNoDataCallBack != null) {
          if (viewModel.showHeaderFooterWidgetWhenNoDataCallBack!(YKSectionListHeaderFooterType.footer)) {
            widgets.add(footer);
          }
        }
      } else {
        widgets.add(footer);
      }
    }
    return widgets;
  }

  _refresh() {
    var vms = widget.viewModels;

    List<List<Widget>> newList = [];
    for (var vm in vms) {
      var widgets = _setup(vm);
      newList.add(widgets);
    }

    _list = newList;

    setState(() {});
  }

  void _loadAllData() {
    for (var vm in widget.viewModels) {

      vm.loadCallBack!((noMoreData) {
        _refresh();
      });
    }
  }

  @override
  void didUpdateWidget(covariant YKSectionListWidget oldWidget) {
    if (oldWidget._keepAlive != widget._keepAlive) {
      // keepAlive 状态需要更新，实现在 AutomaticKeepAliveClientMixin 中
      updateKeepAlive();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  bool get wantKeepAlive => widget._keepAlive;
}
