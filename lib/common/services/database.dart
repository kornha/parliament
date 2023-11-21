import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/room.dart';
import 'package:political_think/common/models/zuser.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';
import 'package:political_think/common/chat/chat_types/flutter_chat_types.dart'
    as ct;

class Database {
  Database.instance();

  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');

  final CollectionReference postCollection =
      FirebaseFirestore.instance.collection('posts');

  final CollectionReference roomCollection =
      FirebaseFirestore.instance.collection('rooms');

  final CollectionReference messageCollection =
      FirebaseFirestore.instance.collection('messages');

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

  Future updateUser(String uid, ZUser data) async {
    return userCollection.doc(uid).update(data.toJson());
  }

  //////////////////////////////////////////////////////////////
  // Post
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

  Future createPost(Post post) async {
    return postCollection.doc(post.pid).set(post.toJson());
  }

  Future deletePost(Post post) async {
    return postCollection.doc(post.pid).delete();
  }

  Future updatePost(Post post) async {
    return postCollection.doc(post.pid).update(post.toJson());
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

  Stream<Room?> streamRoom(String uid, String pid) {
    return Database.instance()
        .roomCollection
        .where("pid", isEqualTo: pid)
        .where("users", arrayContains: uid)
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

  Future<List<ct.Message>?> getMessages(String rid, int page, int limit) {
    // use "roomId" since this is the chat message object
    return Database.instance()
        .messageCollection
        .where('roomId', isEqualTo: rid)
        .orderBy('createdAt', descending: true)
        .startAfter([page == 0 ? double.maxFinite : page])
        .limit(limit)
        .get()
        .then(
          (querySnapshot) {
            if (querySnapshot.docs.isNotEmpty) {
              return querySnapshot.docs
                  .map((doc) =>
                      ct.Message.fromJson(doc.data() as Map<String, dynamic>))
                  .toList();
            } else {
              return null;
            }
          },
        );
  }

  Future createMessage(ct.Message message) async {
    return messageCollection.doc(message.id).set(message.toJson());
  }
}
