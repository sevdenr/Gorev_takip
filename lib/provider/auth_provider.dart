// providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trello/models/user.dart';
import 'package:trello/services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  UserModel? _userModel;
  
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoggedIn => _user != null;
  String? get currentUserId => _user?.uid;
  
  // Auth durumu dinleme
  AuthProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _loadUserModel(user.uid);
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }
  
  Future<void> _loadUserModel(String uid) async {
    try {
      _userModel = await FirestoreService().getUserInfo(uid);
      notifyListeners();
    } catch (e) {
      print('User model yükleme hatası: $e');
    }
  }
}