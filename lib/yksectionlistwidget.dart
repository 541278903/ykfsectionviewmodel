library ykfsectionviewmodel;

import 'package:flutter/material.dart';

enum YKSectionListHeaderFooterType {
  header,
  footer,
}

enum YKSectionListRefreshType {
  header,
  footer
}

class YKSectionListViewModelOption {

  Widget? Function()? headerCallBack;

  Widget? Function()? footerCallBack;

  bool Function(YKSectionListHeaderFooterType type)? showHeaderFooterWidgetWhenNoDataCallBack;

  EdgeInsets Function()? edgeOfSection;

  bool Function()? needRefreshInFooterMode;

  YKSectionListViewModelOption({this.headerCallBack, this.footerCallBack, this.showHeaderFooterWidgetWhenNoDataCallBack, this.edgeOfSection, this.needRefreshInFooterMode});
}


mixin YKSectionListViewModelAbStract {

  void loadData(YKSectionListRefreshType type, void Function(bool noMoreData) noMoreDataCallBack);

  Widget widgetForIndex(int index);

  int numberItem();

  YKSectionListViewModelOption? getOption();
}


class YKSectionListWidgetController {

  YKSectionListWidget? _widget;

  void refresh(void Function() endRefresh) {
    _widget?._state._load(YKSectionListRefreshType.header, (nomoreData) {
      endRefresh.call();
    });
  }

  void loadMore(void Function(bool nomoreData) endRefresh) {
    _widget?._state._load(YKSectionListRefreshType.footer, (nomoreData) {
      endRefresh.call(nomoreData);
    });
  }

  void resetViewModels(List<YKSectionListViewModelAbStract> viewModels, void Function()? endRefresh) {
    _widget?.viewModels = viewModels;
    refresh(() {
      endRefresh?.call();
    });
  }
}

class YKSectionListWidget extends StatefulWidget {

  final bool _keepAlive = true;

  YKSectionListWidgetController? _controller;

  List<YKSectionListViewModelAbStract> viewModels = [];

  YKSectionListWidget({super.key, required this.viewModels, YKSectionListWidgetController? controller}) {
    _controller = controller;
    _controller?._widget = this;
  }

  final _YKSectionListWidgetState _state = _YKSectionListWidgetState();

  @override
  State<YKSectionListWidget> createState() => _state;
}

class _YKSectionListWidgetState extends State<YKSectionListWidget> with AutomaticKeepAliveClientMixin {

  bool _aleardDispose = false;

  bool _nomoreData = false;

  List<List<Widget>> _list = [];

  void Function(bool nomoreData)? _endRefreshCallBack;

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return _main();
  }

  @override
  void initState() {
    super.initState();

    _loadAllData(YKSectionListRefreshType.header, null);
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

  _refresh(bool refreshCallBack) {
    var vms = widget.viewModels;

    List<List<Widget>> newList = [];
    for (var vm in vms) {
      var widgets = _setup(vm);
      newList.add(widgets);
    }

    _list = newList;

    if (!_aleardDispose) {
      if (refreshCallBack) {
        _endRefreshCallBack?.call(_nomoreData);
      }
      _loading = false;
      setState(() {});
    }
  }

  void _loadAllData(YKSectionListRefreshType type, void Function(bool nomoreData)? endRefresh) {
    if (_loading) {
      return;
    }
    _endRefreshCallBack = endRefresh;
    _loading = true;

    _nomoreData = false;
    List<YKSectionListViewModelAbStract> reloadVms = [];
    List<String> vmhaslist = [];
    for (var vm in widget.viewModels) {

      if (type == YKSectionListRefreshType.footer) {
        final inFooter = vm.getOption()?.needRefreshInFooterMode?.call() ?? false;
        if (inFooter) {
          vmhaslist.add(vm.hashCode.toString());
          reloadVms.add(vm);
        }
      } else {
        vmhaslist.add(vm.hashCode.toString());
        reloadVms.add(vm);
      }
    }

    if (reloadVms.isNotEmpty) {

      for (var vm in reloadVms) {
        vm.loadData(type, (noMoreData) {
          if (type == YKSectionListRefreshType.footer) {
            _nomoreData = _nomoreData || noMoreData;
          }
          vmhaslist.removeWhere((element) => element == vm.hashCode.toString());
          _refresh(vmhaslist.isEmpty);
        });
      }
    } else {
      _refresh(vmhaslist.isEmpty);
    }
  }

  void _load(YKSectionListRefreshType type, void Function(bool nomoreData) endRefresh) {
    if (!_aleardDispose) {
      _loadAllData(type, endRefresh);
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
