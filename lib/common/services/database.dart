import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:political_think/common/models/political_position.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/room.dart';
import 'package:political_think/common/models/story.dart';
import 'package:political_think/common/models/vote.dart';
import 'package:political_think/common/models/zuser.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';
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

  CollectionReference roomCollection(String parentId, RoomParentType type) =>
      FirebaseFirestore.instance
          .collection(type.collectionName)
          .doc(parentId)
          .collection("rooms");

  final CollectionReference messageCollection =
      FirebaseFirestore.instance.collection('messages');

  final CollectionReference storyCollection =
      FirebaseFirestore.instance.collection('stories');

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

  Future updateUser(String uid, Map<Object, Object?> data) async {
    return userCollection.doc(uid).update(data);
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

  Future<List<Story>?> getStories(int page, int limit) {
    return Database.instance()
        .storyCollection
        .orderBy('createdAt', descending: true)
        .startAfter([page == 0 ? double.maxFinite : page])
        .limit(limit)
        .get()
        .then(
          (querySnapshot) {
            if (querySnapshot.docs.isNotEmpty) {
              return querySnapshot.docs
                  .map((doc) =>
                      Story.fromJson(doc.data() as Map<String, dynamic>))
                  .toList();
            } else {
              return null;
            }
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

  Future<Post?> getFirstPostInDraft(uid) {
    return postCollection
        .where("creator", isEqualTo: uid)
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

  Future vote(String pid, Vote vote, VoteType type) {
    return postCollection
        .doc(pid)
        .collection(type.collectionName)
        .doc(vote.uid)
        .set(vote.toJson());
  }

  Future createPost(Post post) async {
    return postCollection.doc(post.pid).set(post.toJson());
  }

  Future deletePost(Post post) async {
    return postCollection.doc(post.pid).delete();
  }

  Future updatePost(Post post) async {
    return postCollection.doc(post.pid).update(post.toJson());
  }

  Future likePost(Post post, String uid) async {
    return updateUser(uid, {
      "likedPosts": FieldValue.arrayUnion([post.pid]),
    });
  }

  //////////////////////////////////////////////////////////////
  // Rooms
  //////////////////////////////////////////////////////////////

  Future createRoom(Room room, String parentCollection) async {
    return roomCollection(room.parentId, room.parentType)
        .doc(room.rid)
        .set(room.toJson());
  }

  Future deleteRoom(Room room, String parentCollection) async {
    return roomCollection(room.parentId, room.parentType)
        .doc(room.rid)
        .delete();
  }

  Future updateRoom(Room room, String parentCollection) async {
    return roomCollection(room.parentId, RoomParentType.post)
        .doc(room.rid)
        .update(room.toJson());
  }

  Stream<Room?> streamLatestRoom(String parentId, String parentCollection) {
    return roomCollection(parentId, RoomParentType.post)
        .where('status', whereIn: RoomStatus.activeStatuses)
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

  Stream<List<Message>?> streamMessages(Room room, int limit) {
    // use "roomId" since this is the chat message object
    return Database.instance()
        .roomCollection(room.parentId, room.parentType)
        .doc(room.rid)
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

  Future createMessage(Room room, ct.Message message) async {
    return roomCollection(room.parentId, room.parentType)
        .doc(room.rid)
        .collection("messages")
        .doc(message.id)
        .set(message.toJson());
  }
}
