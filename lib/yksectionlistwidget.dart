library ykfsectionviewmodel;

import 'package:flutter/material.dart';

enum YKSectionListHeaderFooterType {
  header,
  footer,
}

class YKSectionListViewModelOption {

  Widget? Function()? headerCallBack;

  Widget? Function()? footerCallBack;

  bool Function(YKSectionListHeaderFooterType type)? showHeaderFooterWidgetWhenNoDataCallBack;

  EdgeInsets Function()? edgeOfSection;

  YKSectionListViewModelOption({this.headerCallBack, this.footerCallBack, this.showHeaderFooterWidgetWhenNoDataCallBack, this.edgeOfSection});
}


abstract class YKSectionListViewModelAbStract {

  void loadData(void Function(bool noMoreData) noMoreDataCallBack);

  Widget widgetForIndex(int index);

  int numberItem();

  YKSectionListViewModelOption? getOption();
}

class YKSectionListWidgetController {

  void Function()? _refresh;

  Function? get refresh => _refresh;

  final void Function(bool noMoreData) nomoreDataCallBack;

  YKSectionListWidgetController(this.nomoreDataCallBack);
}

class YKSectionListWidget extends StatefulWidget {
  final bool _keepAlive = true;

  YKSectionListWidgetController? controller;

  List<YKSectionListViewModelAbStract> viewModels = [];

  YKSectionListWidget({super.key, required this.viewModels, this.controller});

  @override
  State<YKSectionListWidget> createState() => _YKSectionListWidgetState();
}

class _YKSectionListWidgetState extends State<YKSectionListWidget> with AutomaticKeepAliveClientMixin {

  bool _aleardDispose = false;

  bool _nomoreData = false;

  List<List<Widget>> _list = [];

  @override
  Widget build(BuildContext context) {
    return _main();
  }

  @override
  void initState() {
    super.initState();

    widget.controller?._refresh = () {
      if (!_aleardDispose) {
        _loadAllData();
      }
    };
    _loadAllData();
  }

  @override
  void dispose() {
    _aleardDispose = true;
    super.dispose();
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

    return mainWidget;
  }

  List<Widget> _setup(YKSectionListViewModelAbStract viewModel) {
    List<Widget> widgets = [];

    Widget? header = null;
    Widget? footer = null;
    YKSectionListViewModelOption? option = viewModel.getOption();

    EdgeInsets edge = EdgeInsets.all(0);

    if (option != null) {
      if (option!.edgeOfSection != null) {
        edge = option!.edgeOfSection!();
      }
      if (option!.headerCallBack != null) {
        header = option!.headerCallBack!();
      }
      if (option!.footerCallBack != null) {
        footer = option!.footerCallBack!();
      }
    };

    if (header != null) {
      if (viewModel.numberItem() <= 0) {
        if (option != null && option!.showHeaderFooterWidgetWhenNoDataCallBack != null) {
          if (option!.showHeaderFooterWidgetWhenNoDataCallBack!(YKSectionListHeaderFooterType.header)) {
            widgets.add(header);
          }
        }
      } else {
        widgets.add(header);
      }
    }


    widgets.add(Padding(
        padding: edge,
        child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: viewModel.numberItem(),
            itemBuilder: (context, index) {
              return viewModel.widgetForIndex(index);
            })
    ));

    if (footer != null) {
      if (viewModel.numberItem() <= 0) {
        if (option != null && option!.showHeaderFooterWidgetWhenNoDataCallBack != null) {
          if (option!.showHeaderFooterWidgetWhenNoDataCallBack!(YKSectionListHeaderFooterType.footer)) {
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

    if (!_aleardDispose) {
      widget.controller?.nomoreDataCallBack?.call(_nomoreData);
      setState(() {});
    }
  }

  void _loadAllData() {
    for (var vm in widget.viewModels) {
      vm.loadData((noMoreData) {
        _nomoreData = _nomoreData || noMoreData;
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
