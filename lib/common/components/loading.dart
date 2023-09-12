import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Loading extends StatelessWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: SpinKitDualRing(
          size: 55,
          duration: const Duration(milliseconds: 1200),
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
