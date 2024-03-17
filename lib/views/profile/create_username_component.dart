import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/components/ztextfield.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/zuser.dart';
import 'package:political_think/common/services/database.dart';
import 'package:political_think/common/services/functions.dart';

//TODO: Class is tightly coupled with parent based on the onSave and onClose callbacks,
// as well as state as to wether this is shown because user clicked edit or there is no username
class CreateUsernameComponent extends ConsumerStatefulWidget {
  final void Function(String text)? onSave;
  final void Function()? onSaveSuccess;
  final void Function()? onSaveError;
  final void Function()? onClose;

  const CreateUsernameComponent({
    super.key,
    this.onSave,
    this.onClose,
    this.onSaveSuccess,
    this.onSaveError,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateUsernameComponentState();
}

class _CreateUsernameComponentState
    extends ConsumerState<CreateUsernameComponent> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _loading = false;
  bool _available = false;
  bool hasFocus = false;

  bool get showCheck =>
      _available &&
      !_loading &&
      _controller.text.isNotEmpty &&
      _controller.text != ref.user().username;
  bool get showUnavailable =>
      !_available && !_loading && _controller.text.isNotEmpty;
  bool get showClosed =>
      ref.user().username != null &&
      !showCheck &&
      !showUnavailable &&
      !_loading &&
      (!hasFocus || _controller.text.isEmpty);

  @override
  void initState() {
    super.initState();
    // we request focus if we assume the user came here to change their name
    if (ref.user().username != null) {
      _focusNode.requestFocus();
    }

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        if (!mounted) return;
        setState(() {
          hasFocus = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text("@", style: context.h3),
        Expanded(
          child: ZTextfield(
            textCapitalization: TextCapitalization.none,
            focusNode: _focusNode,
            keyboardType: TextInputType.text,
            controller: _controller,
            hintText: ref.user().username ?? "your_username",
            onChanged: _onSearchChanged,
          ),
        ),
        Visibility(
          visible: _loading,
          child: const Loading(type: LoadingType.standard),
        ),
        Visibility(
          visible: showCheck,
          child: IconButton(
            icon: const Icon(ZIcons.check),
            color: context.secondaryColor,
            onPressed: () {
              // update the user's username
              Functions.instance().setUsername(_controller.text).then((value) {
                if (widget.onSaveSuccess != null) widget.onSaveSuccess!();
              }).onError((error, stackTrace) {
                if (widget.onSaveError != null) widget.onSaveError!();
              });
              if (widget.onSave != null) {
                widget.onSave!(_controller.text);
              }
            },
          ),
        ),
        Visibility(
          visible: showUnavailable,
          child: Icon(Icons.close, color: context.errorColor),
        ),
        // cancel button
        Visibility(
          visible: showClosed,
          child: IconButton(
            icon: const Icon(FontAwesomeIcons.close),
            color: context.surfaceColor,
            onPressed: () {
              if (widget.onClose != null) {
                widget.onClose!();
              }
            },
          ),
        ),
      ],
    );
  }

  void _onSearchChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      _loading = true;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Your data fetching logic here
      Database.instance().getUserByUsername(text).listen((user) {
        if (!mounted) return;

        if (text == _controller.text) {
          if (user != null) {
            setState(() {
              _loading = false;
              _available = false;
            });
          } else {
            setState(() {
              _loading = false;
              _available = true;
            });
          }
        } else {
          setState(() {
            _loading = false;
          });
        }
      });
    });
  }
}
