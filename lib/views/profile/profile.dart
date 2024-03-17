import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/components/zback_button.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/components/ztextfield.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/zuser.dart';
import 'package:political_think/common/services/auth.dart';
import 'package:political_think/views/profile/create_username_component.dart';

class Profile extends ConsumerStatefulWidget {
  const Profile({super.key});

  static const location = "/profile";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<Profile> {
  bool isEditing = false;
  String? _localUsername;

  @override
  Widget build(BuildContext context) {
    final userRef = ref.selfUserWatch();
    bool isLoading = userRef.isLoading;
    bool isError = userRef.hasError || userRef.value == null;
    // set isEditing to false if user changed (but did not go from null to not null)
    ZUser? user = userRef.value;

    if (_localUsername == user?.username) {
      _localUsername = null;
    }

    return ZScaffold(
      body: isLoading
          ? const Loading()
          : Container(
              padding: context.blockPadding,
              margin: context.blockMargin,
              width: context.blockSize.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileIcon(size: context.iconSizeLarge),
                  context.sf,
                  isEditing || user?.username == null
                      ? CreateUsernameComponent(
                          onClose: () {
                            setState(() {
                              isEditing = false;
                            });
                          },
                          onSave: (text) {
                            setState(() {
                              isEditing = false;
                              _localUsername = text;
                            });
                          },
                          onSaveError: () {
                            setState(() {
                              _localUsername = null;
                            });
                          },
                          onSaveSuccess: () {
                            context.showToast("Username updated",
                                isError: false);
                            setState(() {
                              _localUsername = null;
                            });
                          },
                        )
                      : Row(
                          children: [
                            Text("@ ", style: context.h3),
                            Text(_localUsername ?? user?.username ?? "username",
                                style: context.l), // matches hint style
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.lock_sharp,
                                color: context.surfaceColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  isEditing = true;
                                });
                              },
                            ),
                          ],
                        ),
                  const Spacer(),
                  Center(
                    child: ZTextButton(
                      type: ZButtonTypes.wide,
                      backgroundColor: context.surfaceColor,
                      foregroundColor: context.onSurfaceColor,
                      onPressed: () {
                        Auth().signOut();
                      },
                      child: const Text("Logout"),
                    ),
                  ),
                  context.sh,
                  Center(
                    child: ZTextButton(
                      type: ZButtonTypes.wide,
                      backgroundColor: context.errorColor,
                      foregroundColor: context.onErrorColor,
                      onPressed: () {
                        Auth().delete();
                      },
                      child: const Text("Delete Account"),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
