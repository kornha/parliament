import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:political_think/common/models/confidence.dart';
import 'package:political_think/common/models/platform.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/room.dart';
import 'package:political_think/common/models/story.dart';
import 'package:political_think/common/models/vote.dart';
import 'package:political_think/common/models/zsettings.dart';
import 'package:political_think/common/models/zuser.dart';
import 'package:political_think/common/chat/chat_types/flutter_chat_types.dart'
    as ct;

import '../chat/chat_types/src/message.dart';

class Database {
  Database.instance();

  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');

  // currently not done as a subcollection since sid is nullable
  final CollectionReference postCollection =
      FirebaseFirestore.instance.collection('posts');

  final CollectionReference roomCollection =
      FirebaseFirestore.instance.collection("rooms");

  final CollectionReference messageCollection =
      FirebaseFirestore.instance.collection('messages');

  final CollectionReference storyCollection =
      FirebaseFirestore.instance.collection('stories');

  final CollectionReference entityCollection =
      FirebaseFirestore.instance.collection('entities');

  final CollectionReference statementCollection =
      FirebaseFirestore.instance.collection('statements');

  final CollectionReference platformCollection =
      FirebaseFirestore.instance.collection('platforms');

  Stream<ZUser?> getUser(uid) {
    return userCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return ZUser.fromJson(data);
      } else {
        return null;
      }
    });
  }

  Stream<List<ZUser>?> getUsers(List<String> uids, {limit = 25}) {
    return userCollection
        .where(FieldPath.documentId, whereIn: uids)
        .limit(limit)
        .snapshots()
        .map((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return ZUser.fromJson(data);
        }).toList();
      } else {
        return null;
      }
    });
  }

  Future updateUser(String uid, Map<Object, Object?> data) async {
    return userCollection.doc(uid).update(data);
  }

  Stream<ZUser?> getUserByUsername(String username) {
    return userCollection
        .where("username", isEqualTo: username)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        return ZUser.fromJson(data);
      } else {
        return null;
      }
    });
  }

  //////////////////////////////////////////////////////////////
  // Stories
  //////////////////////////////////////////////////////////////
  Stream<Story?> streamStory(sid) {
    return storyCollection.doc(sid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return Story.fromJson(data);
      } else {
        return null;
      }
    });
  }

  Stream<List<Story>?> streamStoriesFiltered(ZSettings? settings) {
    return storyCollection
        .orderBy('scaledHappenedAt', descending: true)
        .limit(5)
        .snapshots()
        .map((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        var stories = querySnapshot.docs
            .map((doc) => Story.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        // CLIENT SIDE FILTERING. HACKY NEED TO RECONSIDER
        // Cannot filter on server side since we are using a range query
        stories = stories
            .where((story) =>
                (story.newsworthiness ?? Confidence.min()) >=
                    settings!.minNewsworthiness &&
                story.pids.length >= settings.minPosts)
            .toList();

        if (stories.isNotEmpty) {
          return stories;
        }
      }
      return null;
    });
  }

  Future<List<Story>?> getStoriesFiltered(
      int page, int limit, ZSettings? settings) {
    return storyCollection
        .orderBy('scaledHappenedAt', descending: true)
        .startAfter([page == 0 ? double.maxFinite : page])
        .limit(limit)
        .get()
        .then(
          (querySnapshot) {
            if (querySnapshot.docs.isNotEmpty) {
              var stories = querySnapshot.docs
                  .map((doc) =>
                      Story.fromJson(doc.data() as Map<String, dynamic>))
                  .toList();
              // CLIENT SIDE FILTERING. HACKY NEED TO RECONSIDER
              // Cannot filter on server side since we are using a range query
              stories = stories
                  .where((story) =>
                      (story.newsworthiness ?? Confidence.min()) >=
                          settings!.minNewsworthiness &&
                      story.pids.length >= settings.minPosts)
                  .toList();

              if (stories.isNotEmpty) {
                return stories;
              }
            }
            return null;
          },
        );
  }

  //////////////////////////////////////////////////////////////
  // Posts
  //////////////////////////////////////////////////////////////

  Stream<Post?> streamPost(pid) {
    return postCollection.doc(pid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return Post.fromJson(data);
      } else {
        return null;
      }
    });
  }

  Future<List<Post>?> getPosts(int page, int limit) {
    return Database.instance()
        .postCollection
        .orderBy('createdAt', descending: true)
        .startAfter([page == 0 ? double.maxFinite : page])
        .limit(limit)
        .get()
        .then(
          (querySnapshot) {
            if (querySnapshot.docs.isNotEmpty) {
              return querySnapshot.docs
                  .map((doc) =>
                      Post.fromJson(doc.data() as Map<String, dynamic>))
                  .toList();
            } else {
              return null;
            }
          },
        );
  }

  Future<List<Post>?> getPostsFromStory(String sid, int page, int limit) {
    return Database.instance()
        .postCollection
        .where("sid", isEqualTo: sid)
        .orderBy('importance', descending: true)
        .startAfter([page == 0 ? double.maxFinite : page])
        .limit(limit)
        .get()
        .then(
          (querySnapshot) {
            if (querySnapshot.docs.isNotEmpty) {
              return querySnapshot.docs
                  .map((doc) =>
                      Post.fromJson(doc.data() as Map<String, dynamic>))
                  .toList();
            } else {
              return null;
            }
          },
        );
  }

  // DEPRECATED
  // USE LOCAL STATE INSTEAD
  Future<Post?> getFirstPostInDraft(uid) {
    return postCollection
        .where("poster", isEqualTo: uid)
        .where("status", isEqualTo: PostStatus.draft.name)
        .orderBy("createdAt", descending: true)
        .limit(1)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty && querySnapshot.docs.first.exists) {
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        return Post.fromJson(data);
      } else {
        return null;
      }
    });
  }

  Stream<Vote?> getVotes(pid, uid, VoteType type) {
    return postCollection
        .doc(pid)
        .collection(type.collectionName)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return Vote.fromJson(data);
      } else {
        return null;
      }
    });
  }

  Future vote(Vote vote) {
    return postCollection
        .doc(vote.pid)
        .collection(vote.type.collectionName)
        .doc(vote.uid)
        .set(
          vote.toJson(),
          SetOptions(merge: true),
        ); // note we set @JsonSerializable(explicitToJson: true, includeIfNull: false)
    // in vote.dart to avoid overwriting fields with null, and SetOptions(merge: true), here
  }

  Future updateVote(
      String pid, String uid, VoteType type, Map<Object, Object?> value) {
    return postCollection
        .doc(pid)
        .collection(type.collectionName)
        .doc(uid)
        .update(value);
  }

  Future createPost(Post post) async {
    return postCollection.doc(post.pid).set(post.toJson());
  }

  Future deletePost(Post post) async {
    return postCollection.doc(post.pid).delete();
  }

  // Future updatePost(Post post) async {
  //   return postCollection.doc(post.pid).update(post.toJson());
  // }

  Future updatePost(String pid, Map<Object, Object?> value) async {
    return postCollection.doc(pid).update(value);
  }

  Future likePost(Post post, String uid) async {
    return updateUser(uid, {
      "likedPosts": FieldValue.arrayUnion([post.pid]),
    });
  }

  //////////////////////////////////////////////////////////////
  /// Statements
  //////////////////////////////////////////////////////////////
  Future updateStatement(String stid, Map<Object, Object?> value) async {
    return statementCollection.doc(stid).update(value);
  }

  //////////////////////////////////////////////////////////////
  /// Entities
  //////////////////////////////////////////////////////////////
  Future updateEntity(String eid, Map<Object, Object?> value) async {
    return entityCollection.doc(eid).update(value);
  }

  //////////////////////////////////////////////////////////////
  /// Platforms
  //////////////////////////////////////////////////////////////

  Future<List<Platform>> getPlatforms(List<String> plids) async {
    return platformCollection
        .where(FieldPath.documentId, whereIn: plids)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs
            .map((doc) => Platform.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      } else {
        return [];
      }
    });
  }

  //////////////////////////////////////////////////////////////
  // Rooms
  //////////////////////////////////////////////////////////////

  Future createRoom(Room room) async {
    return roomCollection.doc(room.rid).set(room.toJson());
  }

  Future deleteRoom(Room room) async {
    return roomCollection.doc(room.rid).delete();
  }

  Future updateRoom(Room room) async {
    return roomCollection.doc(room.rid).update(room.toJson());
  }

  Stream<Room?> streamLatestRoom(String parentId) {
    return roomCollection
        .where('parentId', isEqualTo: parentId)
        // .where('status', whereIn: RoomStatus.activeStatuses)
        .orderBy("createdAt", descending: true)
        .limit(1)
        .snapshots()
        .map((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty && querySnapshot.docs.first.exists) {
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        return Room.fromJson(data);
      } else {
        return null;
      }
    });
  }

  /////////////////////////////////////////////////////////////
  /// Messages
  /////////////////////////////////////////////////////////////

  Stream<List<Message>?> streamMessages(String rid, int limit) {
    // use "roomId" since this is the chat message object
    return Database.instance()
        .roomCollection
        .doc(rid)
        .collection("messages")
        .orderBy("createdAt", descending: true)
        .limit(limit)
        .snapshots()
        .map((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.map((doc) {
          final data = doc.data();
          return ct.Message.fromJson(data);
        }).toList();
      } else {
        return null;
      }
    });
  }

  Future createMessage(String rid, ct.Message message) async {
    return roomCollection
        .doc(rid)
        .collection("messages")
        .doc(message.id)
        .set(message.toJson());
  }
}
