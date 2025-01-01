import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:political_think/common/models/platform.dart';
import 'package:political_think/common/models/statement.dart';
import 'package:political_think/common/models/entity.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/room.dart';
import 'package:political_think/common/models/statement.dart';
import 'package:political_think/common/models/story.dart';
import 'package:political_think/common/models/vote.dart';
import 'package:political_think/common/models/zsettings.dart';
import 'package:political_think/common/models/zuser.dart';
import 'package:political_think/common/riverpod_infinite_scroll/src/paged_notifier.dart';
import 'package:political_think/common/riverpod_infinite_scroll/src/paged_state.dart';
import 'package:political_think/common/services/auth.dart';
import 'package:political_think/common/services/database.dart';
import 'package:political_think/common/chat/chat_types/flutter_chat_types.dart'
    as ct;

//////////////////////////////////////////////////////////////
// Auth/User
//////////////////////////////////////////////////////////////
// Change notifier
final authProvider = ChangeNotifierProvider<Auth>((ref) {
  return Auth.instance();
});

// stream of user
final authUserProvider = Provider<User?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.authUser;
});

final zuserProvider = StreamProvider.family<ZUser?, String?>((ref, uid) {
  if (uid == null) {
    return Stream.value(null);
  }
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

final storiesStreamProvider = StreamProvider.family<List<Story>?, ZSettings?>(
  (ref, settings) => Database.instance().streamStoriesFiltered(settings),
);

final storiesProvider = StateNotifierProvider.family<StoryNotifier,
    PagedState<int, Story>, ZSettings?>(
  (ref, settings) => StoryNotifier(settings),
);

class StoryNotifier extends PagedNotifier<int, Story> {
  final ZSettings? settings;

  StoryNotifier(this.settings)
      : super(
          load: (page, limit) async {
            // Use the settings parameters in the query
            return Database.instance()
                .getStoriesFiltered(page, limit, settings);
          },
          nextPageKeyBuilder: (List<Story>? lastItems, int page, int limit) =>
              lastItems?.last.scaledHappenedAt?.millisecondsSinceEpoch,
        );
}

// for refreshing feed
final pagingControllerProvider =
    StateProvider<PagingController<int, Story?>?>((ref) => null);

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

// Deprecated; not used
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

final postsFromEntityProvider =
    StreamProvider.family<List<Post>?, String>((ref, eid) {
  // int limit = ridlimit.$2;
  return Database.instance()
      .postCollection
      .where("eid", isEqualTo: eid)
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
// Statements
//////////////////////////////////////////////////////////////
final statementProvider =
    StreamProvider.family<Statement?, String>((ref, stid) {
  final statementRef = Database.instance().statementCollection.doc(stid);
  return statementRef.snapshots().map((snapshot) {
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      return Statement.fromJson(data);
    } else {
      return null;
    }
  });
});

final statementsProvider =
    StreamProvider.family<List<Statement>?, List<String>>((ref, stids) {
  // int limit = ridlimit.$2;
  return Database.instance()
      .statementCollection
      .where(FieldPath.documentId, whereIn: stids)
      .limit(50)
      .snapshots()
      .map((querySnapshot) {
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Statement.fromJson(data);
      }).toList();
    } else {
      return null;
    }
  });
});

final statementsFromStoryProvider =
    StreamProvider.family<List<Statement>?, String>((ref, sid) {
  // int limit = ridlimit.$2;
  return Database.instance()
      .statementCollection
      .where("sids", arrayContains: sid)
      //.orderBy("importance", descending: true)
      .limit(50) // need to configure
      .snapshots()
      .map((querySnapshot) {
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Statement.fromJson(data);
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
// Platforms
//////////////////////////////////////////////////////////////
final platformProvider = StreamProvider.family<Platform?, String>((ref, plid) {
  final platformRef = Database.instance().platformCollection.doc(plid);
  return platformRef.snapshots().map((snapshot) {
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      return Platform.fromJson(data);
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
