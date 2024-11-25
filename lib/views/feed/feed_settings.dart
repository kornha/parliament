import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/modal_container.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/confidence.dart';
import 'package:political_think/common/models/zuser.dart';
import 'package:political_think/common/services/database.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class FeedSettings extends ConsumerStatefulWidget {
  final Function? onFilterChange;

  const FeedSettings({
    Key? key,
    this.onFilterChange,
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FeedSettingsState();
}

class _FeedSettingsState extends ConsumerState<FeedSettings> {
  Confidence? _confidence;
  int? _minPosts;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userRef = ref.selfUserWatch();
    ZUser? user = userRef.value;

    if (_confidence == user?.settings.minNewsworthiness) {
      _confidence = null;
    }

    return userRef.hasError
        ? const ZError()
        : user == null
            ? const Loading(type: LoadingType.standard)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  context.sd,
                  Text("Min. Newsworthiness", style: context.m),
                  SfSlider(
                    min: 0.0,
                    max: 1.0,
                    interval: 0.25,
                    showTicks: true,
                    showLabels: true,
                    value: _confidence?.value ??
                        user.settings.minNewsworthiness.value,
                    onChanged: (newValue) {
                      setState(() {
                        _confidence = Confidence(value: newValue);
                      });
                    },
                    onChangeEnd: (value) async {
                      value = double.parse(value.toStringAsFixed(2));
                      await Database.instance().updateUser(
                          user.uid, {"settings.minNewsworthiness": value});
                      widget.onFilterChange?.call();
                    },
                    tooltipTextFormatterCallback: (actualValue, formattedText) {
                      return actualValue
                          .toStringAsFixed(2); // Adjusts tooltip precision
                    },
                  ),
                  context.sf,
                  Text("Min. Posts", style: context.m),
                  SfSlider(
                    min: 0,
                    max: 10,
                    interval: 2,
                    showTicks: true,
                    showLabels: true,
                    value: (_minPosts ?? user.settings.minPosts).toDouble(),
                    onChanged: (newValue) {
                      setState(() {
                        _minPosts = newValue.toInt();
                      });
                    },
                    onChangeEnd: (value) async {
                      value = value.toInt();
                      await Database.instance().updateUser(
                        user.uid,
                        {"settings.minPosts": value},
                      );
                      widget.onFilterChange?.call();
                    },
                    tooltipTextFormatterCallback: (actualValue, formattedText) {
                      return actualValue
                          .toInt()
                          .toString(); // Integer precision for tooltip
                    },
                  ),
                  context.sd,
                ],
              );
  }
}
