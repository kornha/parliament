import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/room.dart';
import 'package:political_think/common/models/zuser.dart';
import 'package:political_think/common/services/auth.dart';
import 'package:political_think/common/services/database.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';
import 'package:tuple/tuple.dart';
import 'package:political_think/common/chat/chat_types/flutter_chat_types.dart'
    as ct;

//////////////////////////////////////////////////////////////
// Auth/User
//////////////////////////////////////////////////////////////

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authProvider = ChangeNotifierProvider<AuthState>((ref) {
  return AuthState.instance();
});

final zuserProvider = StreamProvider.family<ZUser?, String>((ref, uid) {
  return Database.instance().getUser(uid);
});

//////////////////////////////////////////////////////////////
// Posts
//////////////////////////////////////////////////////////////

final postProvider = StreamProvider.family<Post?, String>((ref, pid) {
  final postRef = Database.instance().postCollection.doc(pid);
  return postRef.snapshots().map((snapshot) {
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      return Post.fromJson(data);
    } else {
      return null;
    }
  });
});

final postsProvider =
    StateNotifierProvider<PostNotifier, PagedState<int, Post>>(
  (_) => PostNotifier(),
);

class PostNotifier extends PagedNotifier<int, Post> {
  PostNotifier()
      : super(
          //load is a required method of PagedNotifier
          load: (page, limit) async {
            return Database.instance().getPosts(page, limit);
          },
          nextPageKeyBuilder: (List<Post>? lastItems, int page, int limit) =>
              lastItems?.last.createdAt.millisecondsSinceEpoch,
        );
}

//////////////////////////////////////////////////////////////
// Rooms
//////////////////////////////////////////////////////////////

// need a tuple as this only takes in one param
// returns only the first room as there should be one per user/post
final roomProvider =
    StreamProvider.family<Room?, (String, String)>((ref, uidpid) {
  String uid = uidpid.$1;
  String pid = uidpid.$2;

  return Database.instance().streamRoom(uid, pid);
});

//////////////////////////////////////////////////////////////
// Messages
//////////////////////////////////////////////////////////////

final messagesProvider =
    StreamProvider.family<List<ct.Message>?, (String, int)>((ref, ridlimit) {
  String rid = ridlimit.$1;
  int limit = ridlimit.$2;
  return Database.instance()
      .messageCollection
      .where("roomId", isEqualTo: rid)
      .orderBy("createdAt", descending: true)
      .limit(limit)
      .snapshots()
      .map((querySnapshot) {
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ct.Message.fromJson(data);
      }).toList();
    } else {
      return null;
    }
  });
});

class MessagesNotifier extends PagedNotifier<int, ct.Message> {
  String rid;
  MessagesNotifier({required this.rid})
      : super(
          //load is a required method of PagedNotifier
          load: (page, limit) async {
            return Database.instance().getMessages(rid, page, limit);
          },
          nextPageKeyBuilder:
              (List<ct.Message>? lastItems, int page, int limit) =>
                  lastItems?.last.createdAt,
        );
}
