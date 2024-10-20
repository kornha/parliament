import 'package:flutter/material.dart';
import 'package:political_think/common/components/ztab_bar.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/statement.dart';
import 'package:political_think/views/statement/statement_view.dart';

class StatementTabView extends StatefulWidget {
  final List<Statement>? statements;
  const StatementTabView({
    super.key,
    this.statements,
  });

  @override
  State<StatementTabView> createState() => _StatementTabViewState();
}

class _StatementTabViewState extends State<StatementTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Tab> tabs =
      StatementType.values.map((e) => Tab(text: "${e.name}s")).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZTabBar(tabController: _tabController, tabs: tabs),
        context.sh,
        IndexedStack(
          index: _tabController.index,
          children: StatementType.values
              .map((e) => _buildDynamicListView(e))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDynamicListView(StatementType type) {
    List<Statement> values = (widget.statements ?? [])
        .where((element) => element.type == type)
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: values.map((e) => StatementView(stid: e.stid)).toList(),
    );
  }
}
