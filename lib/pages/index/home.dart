// ignore_for_file: must_be_immutable

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:hll_gun_calculator/data/index.dart';
import 'package:provider/provider.dart';
import 'package:simple_page_indicator/simple_page_indicator.dart';

import '/data/HomeApp.dart';
import '/provider/home_app_provider.dart';
import '/constants/app.dart';
import '/utils/index.dart';
import '/provider/history_provider.dart';
import '/constants/config.dart';
import '/provider/package_provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late PageController _pageController;

  int initialPage = 0;

  int tabLength = 1;

  UrlUtil urlUtil = UrlUtil();

  @override
  void initState() {
    List<HomeAppData> activeList = App.provider.ofHomeApp(context).activeList;

    // 初始tab
    tabLength = activeList.length;
    _pageController = PageController(
      initialPage: initialPage,
      keepPage: true,
    );
    super.initState();
  }

  /// 打开设置
  void _openSetting() async {
    Navigator.pop(context);
    urlUtil.opEnPage(context, "/setting/");
  }

  /// 打开计算历史
  void _openComputingHistory() {
    Navigator.pop(context);
    urlUtil.opEnPage(context, "/computingHistoryPage");
  }

  /// 打开收藏
  void _openCollect() {
    Navigator.pop(context);
    urlUtil.opEnPage(context, "/collect");
  }

  /// 打开收藏
  void _openVersion() {
    Navigator.pop(context);
    urlUtil.opEnPage(context, "/setting/version");
  }

  /// 首页面板配置
  void _openHomeAppConfig() {
    Navigator.pop(context);
    urlUtil.opEnPage(context, "/setting/homeAppConfig");
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Consumer3<PackageProvider, HistoryProvider, HomeAppProvider>(
        builder: (consumerContext, packageData, historyData, homeAppData, widget) {
          return Title(
            title: packageData.package!.appName.toString(),
            color: Colors.black,
            child: DefaultTabController(
              length: homeAppData.activeList.length,
              child: Scaffold(
                extendBodyBehindAppBar: true,
                appBar: HomeAppBar(
                  contentHeight: MediaQuery.of(context).size.width < AppSize.kRang ? kToolbarHeight : .0,
                  pageController: _pageController,
                ),
                drawer: Drawer(
                  backgroundColor: Theme.of(context).canvasColor,
                  child: SafeArea(
                    maintainBottomViewPadding: true,
                    child: Column(
                      children: [
                        Expanded(
                          flex: 1,
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              ListTile(
                                title: Text(FlutterI18n.translate(context, "setting.cell.history.title")),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openComputingHistory(),
                              ),
                              ListTile(
                                title: Text(FlutterI18n.translate(context, "collect.title")),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openCollect(),
                              ),
                              const Divider(),
                              ListTile(
                                title: Text(FlutterI18n.translate(context, "setting.title")),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openSetting(),
                              ),
                              const Divider(),
                              ListTile(
                                dense: true,
                                title: Text(FlutterI18n.translate(context, "home.function.title")),
                                trailing: IconButton(
                                  onPressed: () => _openHomeAppConfig(),
                                  icon: const Icon(Icons.settings, size: 20),
                                ),
                              ),
                              ...homeAppData.activeList.asMap().entries.map((i) {
                                var menu = i.value, index = i.key;
                                return ListTile(
                                  title: Text(FlutterI18n.translate(context, "${menu.type.name}.title")),
                                  leading: menu.icon,
                                  onTap: () {
                                    setState(() {
                                      _pageController.jumpToPage(index);
                                      Navigator.of(context).pop();
                                    });
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                        ListTile(
                          title: Text(FlutterI18n.translate(context, "setting.versions.title")),
                          subtitle: Text(packageData.currentVersion),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openVersion(),
                        ),
                      ],
                    ),
                  ),
                ),
                body: HomeBody(
                  pageController: _pageController,
                  navs: homeAppData.activeList,
                ),
                bottomSheet: Container(
                  margin: EdgeInsets.only(bottom: 28 + MediaQuery.of(context).viewPadding.bottom),
                  child: SimplePageIndicator(
                    itemCount: homeAppData.activeList.length,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    controller: _pageController,
                    space: 20,
                    maxSize: 4,
                    minSize: 3,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  final PageController pageController;
  late double contentHeight;

  HomeAppBar({
    super.key,
    required this.pageController,
    this.contentHeight = kToolbarHeight,
  });

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(contentHeight);
}

class _HomeAppBarState extends State<HomeAppBar> {
  late HomeAppData homeApp;

  @override
  void initState() {
    homeApp = App.provider.ofHomeApp(context).activeList.first;

    widget.pageController.addListener(() {
      int index = widget.pageController.page!.ceil();
      setState(() {
        homeApp = App.provider.ofHomeApp(context).activeList[index];
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      if (constraints.maxWidth < AppSize.kRang) {
        widget.contentHeight = kToolbarHeight;

        return AppBar(
          forceMaterialTransparency: true,
          flexibleSpace: homeApp.isShowAppBar
              ? FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 10,
                      sigmaY: 10,
                    ),
                    blendMode: BlendMode.srcIn,
                    child: Container(
                      color: Theme.of(context).appBarTheme.backgroundColor!.withOpacity(.9),
                    ),
                  ),
                )
              : null,
          leading: Builder(
            builder: (BuildContext context) {
              if (homeApp.isShowAppBar) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                );
              }

              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              );
            },
          ),
        );
      }

      widget.contentHeight = 0.0;

      return const PreferredSize(
        preferredSize: Size(0.0, 0.0),
        child: SizedBox(),
      );
    });
  }
}

class HomeBody extends StatefulWidget {
  final List<HomeAppData> navs;
  final PageController pageController;

  const HomeBody({
    super.key,
    required this.navs,
    required this.pageController,
  });

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  int tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      return Center(
        child: OverflowBox(
          maxWidth: constraints.maxWidth > AppSize.kRang ? double.parse(AppSize.kRang.toString()) : null,
          child: Row(
            children: [
              if (constraints.maxWidth >= AppSize.kRang)
                NavigationRail(
                  onDestinationSelected: (value) {
                    setState(() {
                      tabIndex = value;
                      widget.pageController.jumpToPage(value);
                    });
                  },
                  leading: const DrawerButton(),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Theme.of(context).bottomAppBarTheme.color,
                  destinations: widget.navs.map((nav) {
                    return NavigationRailDestination(
                      icon: nav.icon,
                      selectedIcon: nav.activeIcon,
                      label: Text(FlutterI18n.translate(context, "${nav.type.name}.title")),
                    );
                  }).toList(),
                  selectedIndex: tabIndex,
                ),
              Expanded(
                flex: 1,
                child: PageView(
                  controller: widget.pageController,
                  children: App.provider.ofHomeApp(context).widgets,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
