import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/models/claim.dart';
import 'package:political_think/common/models/entity.dart';
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

final zusersProvider =
    StreamProvider.family<List<ZUser>?, List<String>>((ref, uids) {
  return Database.instance().getUsers(uids);
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

final postsFromStoryProvider =
    StreamProvider.family<List<Post>?, String>((ref, sid) {
  // int limit = ridlimit.$2;
  return Database.instance()
      .postCollection
      .where("sids", arrayContains: sid)
      //.orderBy("importance", descending: true)
      .limit(50) // need to configure
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

// We do this without a notifier
// can switch if needed
final primaryPostsFromStoryProvider =
    StreamProvider.family<List<Post>?, String>((ref, sid) {
  // int limit = ridlimit.$2;
  return Database.instance()
      .postCollection
      .where("sid", isEqualTo: sid)
      //.orderBy("importance", descending: true)
      .limit(25) // need to configure
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
// Claims
//////////////////////////////////////////////////////////////
final claimProvider = StreamProvider.family<Claim?, String>((ref, cid) {
  final claimRef = Database.instance().claimCollection.doc(cid);
  return claimRef.snapshots().map((snapshot) {
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      return Claim.fromJson(data);
    } else {
      return null;
    }
  });
});

final claimsFromStoryProvider =
    StreamProvider.family<List<Claim>?, String>((ref, sid) {
  // int limit = ridlimit.$2;
  return Database.instance()
      .claimCollection
      .where("sids", arrayContains: sid)
      //.orderBy("importance", descending: true)
      .limit(50) // need to configure
      .snapshots()
      .map((querySnapshot) {
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Claim.fromJson(data);
      }).toList();
    } else {
      return null;
    }
  });
});

//////////////////////////////////////////////////////////////
// Entities
//////////////////////////////////////////////////////////////

final entityProvider = StreamProvider.family<Entity?, String>((ref, eid) {
  final entityRef = Database.instance().entityCollection.doc(eid);
  return entityRef.snapshots().map((snapshot) {
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      return Entity.fromJson(data);
    } else {
      return null;
    }
  });
});

// TODO: WHEREIN LIMIT 10
final entitiesFromPostsProvider =
    StreamProvider.family<List<Entity>?, List<String>>((ref, pids) {
  if (pids.isEmpty) {
    return Stream.value(null);
  }
  return Database.instance()
      .postCollection
      .where(FieldPath.documentId, whereIn: pids)
      .snapshots()
      .asyncMap((postsSnapshot) async {
    final eids = postsSnapshot.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['eid'] as String?;
        })
        .where((eid) => eid != null)
        .toList();

    // If no entity IDs or more than 10 (limit of 'whereIn'), return null or handle appropriately
    if (eids.isEmpty || eids.length > 10) {
      return null;
    }

    // Fetch entities based on the entity IDs collected
    final entitySnapshot = await Database.instance()
        .entityCollection
        .where(FieldPath.documentId, whereIn: eids)
        .get();

    // Map over the entity documents and convert them to Entity objects
    return entitySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Entity.fromJson(data);
    }).toList();
  });
});

//////////////////////////////////////////////////////////////
// Rooms
//////////////////////////////////////////////////////////////

// need a tuple as this only takes in one param
// returns only the first room as there should be one per user/post
final latestRoomProvider =
    StreamProvider.family<Room?, String>((ref, parentId) {
  return Database.instance().streamLatestRoom(parentId);
});

//////////////////////////////////////////////////////////////
// Messages
//////////////////////////////////////////////////////////////

final messagesProvider =
    StreamProvider.family<List<ct.Message>?, (String, int)>((ref, ridlimit) {
  String rid = ridlimit.$1;
  int limit = ridlimit.$2;
  return Database.instance().streamMessages(rid, limit);
});
