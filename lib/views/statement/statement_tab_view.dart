import 'package:flutter/material.dart';
import 'package:political_think/common/components/ztab_bar.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/statement.dart';
import 'package:political_think/views/statement/statement_view.dart';

class StatementTabView extends StatefulWidget {
  // TODO: currently takes in statements as it allows parents to control
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
  int _maxCount = 0;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // HACK! Need to calculate max number of a given statement type to get height
    for (var type in StatementType.values) {
      int count = (widget.statements ?? [])
          .where((element) => element.type == type)
          .length;
      if (count > _maxCount) {
        _maxCount = count;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZTabBar(tabController: _tabController, tabs: tabs),
        context.sh,
        // HACK, we precaculate the max height of the listview for TabBarView
        // sqd is a close estimate of the height of a single statement widget
        ConstrainedBox(
          constraints: BoxConstraints(
            // magic number soc ~= max size of a statement widget
            maxHeight: _maxCount * context.soc.height!,
          ),
          child: TabBarView(
            controller: _tabController,
            children: StatementType.values
                .map((e) => _buildDynamicListView(e))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicListView(StatementType type) {
    List<Statement> values = (widget.statements ?? [])
        .where((element) => element.type == type)
        .toList();
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: values.length,
      itemBuilder: (context, index) {
        return StatementView(stid: values[index].stid);
      },
    );
  }
}
