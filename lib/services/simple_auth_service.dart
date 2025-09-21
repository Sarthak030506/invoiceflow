import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class SimpleAuthService {
  static Future<bool> signup(String email, String password, String name) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await credential.user!.updateDisplayName(name);
      
      final userModel = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        phone: '',
      );
      
      return await _saveUserData(userModel);
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  static Future<bool> login(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final userModel = UserModel(
        id: credential.user!.uid,
        name: credential.user!.displayName ?? 'User',
        email: credential.user!.email ?? email,
        phone: credential.user!.phoneNumber ?? '',
      );
      
      return await _saveUserData(userModel);
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  static Future<bool> _saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user.toJson()));
    return true;
  }

  static Future<bool> isLoggedIn() async {
    return FirebaseAuth.instance.currentUser != null;
  }

  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return UserModel.fromJson(json.decode(userData));
    }
    return null;
  }

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }
}