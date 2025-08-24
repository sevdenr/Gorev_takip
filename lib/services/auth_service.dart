// services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  

  // Çıkış yapma fonksiyonu
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Çıkış yapılırken hata oluştu: $e');
      throw e; // Hata yönetimi için
    }
  }

//giriş
  Future <String> login({required BuildContext context,required String email, required String password}) async{
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hesabınıza başarıyla giriş yapıldı!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      // ignore: use_build_context_synchronously
      GoRouter.of(context).push('/');
      return "başarılı";
    } on FirebaseAuthException catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getLogErrorMessage(e.code)),
          backgroundColor: Colors.red,
        ),
      );
      return e.code;      
    }
  }

  Future<String> registerFonk({required BuildContext context,required String email,required String password,required String name,}) async {
    try {
    // 1. Kullanıcıyı oluştur
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Kullanıcı ID'sini al
      String uid = userCredential.user!.uid;

      // 3. Firestore'a ekle
      await _firestore.collection("Users").doc(uid).set({
        "email": email,
        "name": name,
        "userId": uid,
      });

      // 4. Başarılı mesajı göster
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hesabınız başarıyla oluşturuldu!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      // 5. Login sayfasına yönlendir
      // ignore: use_build_context_synchronously
      GoRouter.of(context).push('/login');

      return "başarılı";
    } on FirebaseAuthException catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getResErrorMessage(e.code)),
          backgroundColor: Colors.red,
        ),
      );
      return e.code;
    } catch (e) {
      print("Firestore hata: $e");
      return "Firestore hatası: $e";
    }
  }

  // Herhangi bir sayfa açılmadan önce kontrol
  Future<bool> checkUserLoggedIn() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Lütfen önce giriş yapın');
    }
    return true;
  }

  // Şifre değiştirme fonksiyonu
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      // Kullanıcının mevcut şifresini doğrula
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      // Yeniden kimlik doğrulama yap
      await user.reauthenticateWithCredential(credential);

      // Şifreyi değiştir
      await user.updatePassword(newPassword);

    } on FirebaseAuthException catch (e) {
      throw Exception(_getPasswordChangeErrorMessage(e.code));
    } catch (e) {
      throw Exception('Şifre değiştirilirken bir hata oluştu: $e');
    }
  }
  
  Future <String> ForgotPassword({context,required String email}) async{
    try {
     await _auth.sendPasswordResetEmail(email: email);
      return "başarılı";
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getResErrorMessage(e.code)),
          backgroundColor: Colors.red,
        ),
      );
      return e.code;
    }
  }

  // Kullanıcı durumunu dinleme
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _getLogErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Yanlış şifre';
      case 'invalid-email':
        return 'Geçersiz email formatı';
      default:
        return 'Giriş başarısız: $code';
    }
  }  

  String _getResErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Yanlış şifre';
      case 'invalid-email':
        return 'Geçersiz email formatı';
      case 'email-already-in-use':
        return 'Bu email adresi zaten kullanımda';
      case 'weak-password':
        return 'Şifre çok zayıf (en az 6 karakter olmalı)';
      case 'invalid-credential':
        return 'Geçersiz kimlik bilgileri';
      default:
        return 'Kayıt başarısız: $code';
    }
  }

  String _getPasswordChangeErrorMessage(String code) {
    switch (code) {
      case 'wrong-password':
        return 'Mevcut şifre yanlış';
      case 'weak-password':
        return 'Yeni şifre çok zayıf (en az 6 karakter olmalı)';
      case 'requires-recent-login':
        return 'Güvenlik nedeniyle yeniden giriş yapmanız gerekiyor';
      case 'user-not-found':
        return 'Kullanıcı bulunamadı';
      case 'invalid-credential':
        return 'Kimlik bilgileri geçersiz';
      case 'user-disabled':
        return 'Kullanıcı hesabı devre dışı bırakılmış';
      case 'operation-not-allowed':
        return 'Bu işlem izin verilmiyor';
      default:
        return 'Şifre değiştirme başarısız: $code';
    }
  }
}