import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trello/models/user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get newBoardId => _firestore.collection('Boards').doc().id;

  Future<String> getCurrentUserData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }
    return currentUser.uid;
  }

  Future<UserModel> getUserInfo(String userId) async {
    final docSnapshot = await _firestore.collection('Users').doc(userId).get();

    if (!docSnapshot.exists) {
      throw Exception('Kullanıcı bulunamadı');
    }

    final data = docSnapshot.data();
    if (data == null) {
      throw Exception('Kullanıcı verisi boş');
    }

    return UserModel.fromJson({
      'id': userId,
      'name': data['name'] ?? '',
      'email': data['email'] ?? '',
    });
  }

  Future<void> updateCurrentUserData(String name, String email) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Kullanıcı giriş yapmamış');
    }

    await _firestore.collection('Users').doc(currentUser.uid).set({
      'name': name,
      'email': email,
    }, SetOptions(merge: true));

    await currentUser.updateDisplayName(name);
  }

  Future<void> dataUpdateBoard({
    required String title,
    required String description,
    required String color,
  }) async {
    try {
      final currentUserId = await getCurrentUserData();

      await _firestore.collection("Boards").doc(newBoardId).set({
        "boardID": newBoardId,
        "title": title,
        "description": description,
        "color": color,
        "ownerID": currentUserId,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Board oluşturma hatası: $e');
      rethrow;
    }
  }

  Future<void> createTask({
    required String boardId,
    required String title,
    required String description,
    required String priority,
    String? assignee,
    required String status,
    Timestamp? deadline,
    required List<String> assignees
  }) async {
    try {
      final taskRef = _firestore.collection('Boards').doc(boardId).collection('Tasks').doc();

      final taskData = {
        'taskId': taskRef.id,
        'title': title,
        'description': description,
        'priority': priority,
        'status': status,
        'assignees': assignees,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Deadline varsa ekle
      if (deadline != null) {
        taskData['deadline'] = deadline;
      }

      // Ana assignee varsa ekle
      if (assignee != null) {
        taskData['assignee'] = assignee;
      }

      await taskRef.set(taskData);
      print('Task başarıyla oluşturuldu');
    } catch (e) {
      print('Task oluşturma hatası: $e');
      rethrow;
    }
  }

  Future<void> updateTask({
    required String taskId, 
    required String boardId, 
    required String title, 
    required String description, 
    required String priority, 
    String? assignee, 
    required List<String> assignees, 
    Timestamp? deadline
  }) async {
    try {
      final taskData = {
        'title': title,
        'description': description,
        'priority': priority,
        'assignees': assignees,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Deadline varsa ekle, yoksa kaldır
      if (deadline != null) {
        taskData['deadline'] = deadline;
      } else {
        taskData['deadline'] = FieldValue.delete();
      }

      // Ana assignee varsa ekle
      if (assignee != null) {
        taskData['assignee'] = assignee;
      } else {
        taskData['assignee'] = FieldValue.delete();
      }

      await _firestore
          .collection('Boards')
          .doc(boardId)
          .collection('Tasks')
          .doc(taskId)
          .update(taskData);

      print('Task başarıyla güncellendi');
    } catch (e) {
      print('Task güncelleme hatası: $e');
      rethrow;
    }
  }

  // Task durumunu güncelle (sürükle-bırak için)
  Future<void> updateTaskStatus({
    required String boardId,
    required String taskId,
    required String newStatus,
  }) async {
    try {
      await _firestore
          .collection('Boards')
          .doc(boardId)
          .collection('Tasks')
          .doc(taskId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Task durumu güncellendi: $newStatus');
    } catch (e) {
      print('Task durum güncelleme hatası: $e');
      rethrow;
    }
  }

  // Task silme
  Future<void> deleteTask({required String boardId, required String taskId}) async {
    try {
      await _firestore
          .collection('Boards')
          .doc(boardId)
          .collection('Tasks')
          .doc(taskId)
          .delete();
      print('Task başarıyla silindi');
    } catch (e) {
      print('Task silme hatası: $e');
      rethrow;
    }
  }

  // Board silme
  Future<void> deleteBoard({required String boardId}) async {
    try {
      // Önce board içindeki tüm taskları sil
      final tasksSnapshot = await _firestore
          .collection('Boards')
          .doc(boardId)
          .collection('Tasks')
          .get();

      final batch = _firestore.batch();
      
      for (var doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Board'u da sil
      batch.delete(_firestore.collection('Boards').doc(boardId));
      
      await batch.commit();
      print('Board ve tüm taskları başarıyla silindi');
    } catch (e) {
      print('Board silme hatası: $e');
      rethrow;
    }
  }
  Future<void> updateBoard({
  required String boardId,
  required String title,
  required String description,
}) async {
  await _firestore.collection('Boards').doc(boardId).update({
    'title': title,
    'description': description,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

  // Kullanıcı adını ID'den getir
  Future<String> getUserNameById(String userId) async {
    try {
      final doc = await _firestore.collection('Users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return data['name'] ?? data['email'] ?? 'Bilinmeyen';
      }
      return 'Bilinmeyen';
    } catch (e) {
      print('Kullanıcı adı getirme hatası: $e');
      return 'Bilinmeyen';
    }
  }

  // Çoklu kullanıcı adlarını getir
  Future<Map<String, String>> getUserNamesByIds(List<String> userIds) async {
    try {
      final Map<String, String> userNames = {};
      
      for (String userId in userIds) {
        final doc = await _firestore.collection('Users').doc(userId).get();
        if (doc.exists) {
          final data = doc.data()!;
          userNames[userId] = data['name'] ?? data['email'] ?? 'Bilinmeyen';
        } else {
          userNames[userId] = 'Bilinmeyen';
        }
      }
      
      return userNames;
    } catch (e) {
      print('Kullanıcı adları getirme hatası: $e');
      return {};
    }
  }
}