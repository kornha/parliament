import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zlist_view.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/components/ztext_field.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/entity.dart';
import 'package:political_think/common/services/database.dart';
import 'package:political_think/common/util/utils.dart';
import 'package:political_think/views/entity/entity_list.dart';
import 'package:political_think/views/post/post_builder.dart';

class Search extends ConsumerStatefulWidget {
  const Search({super.key});

  static const location = "/search";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SearchState();
}

class _SearchState extends ConsumerState<Search> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Entity> _entities = [];
  Timer? _debounce;
  bool _showSearchButton = true;
  bool _showPasteButton = true;
  bool _showSearchResults = false;
  bool _showPasteResults = false;
  String? _url;

  @override
  void initState() {
    super.initState();
    //detect when focus has changed on/off textfield
    _focusNode.addListener(() {
      setState(() {
        if (_focusNode.hasFocus) {
          _showSearchButton = true;
          _showPasteButton = false;
          _showSearchResults = true;
          _showPasteResults = false;
        } else {
          _showPasteButton = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZScaffold(
      appBar: ZAppBar(showLogo: true),
      ignoreScrollView: true,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: context.blockSize.width,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ZTextField(
                    textAlign: TextAlign.start,
                    // _showSearchButton && !_showPasteButton
                    // ? TextAlign.start
                    // : TextAlign.center,
                    textCapitalization: TextCapitalization.none,
                    keyboardType: TextInputType.text,
                    controller: _controller,
                    hintText: "Search Entities",
                    onChanged: _onSearchChanged,
                    focusNode: _focusNode,
                    maxLines: 1,
                    autoCorrect: false,
                  ),
                ),
                _showPasteButton
                    ? ZTextButton(
                        foregroundColor: context.secondaryColor,
                        backgroundColor: context.secondaryColorWithOpacity,
                        type: ZButtonTypes.icon,
                        child: const Icon(Icons.paste),
                        onPressed: () async {
                          ClipboardData? clipboardData =
                              await Clipboard.getData(Clipboard.kTextPlain);
                          if (clipboardData?.text != null) {
                            _controller.text = clipboardData?.text ?? "";
                            _onSearchChanged(_controller.text); //Manual paste
                          }
                        },
                      )
                    : const SizedBox.shrink(),
                context.sf,
                ZTextButton(
                  foregroundColor: context.errorColor,
                  backgroundColor: context.errorColorWithOpacity,
                  type: ZButtonTypes.icon,
                  child: const Icon(Icons.clear),
                  onPressed: () async {
                    _controller.text = "";
                    _onSearchChanged(_controller.text);
                  },
                )
              ],
            ),
          ),
          Expanded(
            child: _showSearchResults
                ? EntityListView(
                    eids: _entities.map((e) => e.eid).toList(),
                  )
                : _showPasteResults
                    ? SingleChildScrollView(child: PostBuilder(url: _url))
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _showSearchResults = true;
    _showPasteResults = false;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (Utils.isURL(query)) {
        print("here");
        setState(() {
          _showSearchResults = false;
          _showPasteResults = true;
          _url = query;
        });
        return;
      }
      if (query.isEmpty) {
        setState(() {
          _entities = [];
        });
        return;
      }
      Database.instance().searchEntities(query).then((entities) {
        setState(() {
          _entities = entities ?? [];
        });
      });
    });
  }
}
