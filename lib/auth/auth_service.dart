import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/user.dart';

class AuthService {
  // Login method
  Future<bool> login(UserModel userModel) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userModel.email,
        password: userModel.password,
      );

      // Agar login successful hua toh SharedPreferences me save karo
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', userModel.email); // Email store

      return true;
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }

  // SignUp method
  Future<bool> signUp(UserModel userModel) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: userModel.email,
        password: userModel.password,
      );

      // Signup ke baad SharedPreferences me data save karo
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', userModel.email);

      return true;
    } catch (e) {
      print('Error during signup: $e');
      return false;
    }
  }

  // Logout method
  Future logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
    } catch (e) {
      rethrow;
    }
  }
}
