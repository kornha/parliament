import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/room.dart';
import 'package:political_think/common/models/story.dart';
import 'package:political_think/common/models/vote.dart';
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

// Searches 2 diff tables depending on the vote type
final voteProvider = StreamProvider.family<Vote?, (String, String, VoteType)>(
    (ref, piduidcollection) {
  String pid = piduidcollection.$1;
  String uid = piduidcollection.$2;
  VoteType collection = piduidcollection.$3;

  return Database.instance().getVotes(pid, uid, collection);
});

//////////////////////////////////////////////////////////////
// Stories
//////////////////////////////////////////////////////////////

final storyProvider = StreamProvider.family<Story?, String>((ref, pid) {
  final storyRef = Database.instance().storyCollection.doc(pid);
  return storyRef.snapshots().map((snapshot) {
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      return Story.fromJson(data);
    } else {
      return null;
    }
  });
});

final storiesProvider =
    StateNotifierProvider<StoryNotifier, PagedState<int, Story>>(
  (_) => StoryNotifier(),
);

class StoryNotifier extends PagedNotifier<int, Story> {
  StoryNotifier()
      : super(
          //load is a required method of PagedNotifier
          load: (page, limit) async {
            return Database.instance().getStories(page, limit);
          },
          nextPageKeyBuilder: (List<Story>? lastItems, int page, int limit) =>
              lastItems?.last.createdAt.millisecondsSinceEpoch,
        );
}

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

// We do this without a notifier
// can switch if needed
final postsFromStoryProvider =
    StreamProvider.family<List<Post>?, String>((ref, sid) {
  // int limit = ridlimit.$2;
  return Database.instance()
      .postCollection
      .where("sid", isEqualTo: sid)
      .orderBy("importance", descending: true)
      .limit(5) // need to configure
      .snapshots()
      .map((querySnapshot) {
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Post.fromJson(data);
      }).toList();
    } else {
      return null;
    }
  });
});

//////////////////////////////////////////////////////////////
// Rooms
//////////////////////////////////////////////////////////////

// need a tuple as this only takes in one param
// returns only the first room as there should be one per user/post
final latestRoomProvider = StreamProvider.family<Room?, (String, String)>(
    (ref, parentIdparentCollection) {
  String parentId = parentIdparentCollection.$1;
  String parentCollection = parentIdparentCollection.$2;
  return Database.instance().streamLatestRoom(parentId, parentCollection);
});

//////////////////////////////////////////////////////////////
// Messages
//////////////////////////////////////////////////////////////

final messagesProvider =
    StreamProvider.family<List<ct.Message>?, (Room, int)>((ref, roomlimit) {
  Room room = roomlimit.$1;
  int limit = roomlimit.$2;
  return Database.instance().streamMessages(room, limit);
});
