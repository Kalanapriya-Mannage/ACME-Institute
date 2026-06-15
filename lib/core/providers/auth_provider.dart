import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AuthenticatedUser {
  final User firebaseUser;
  final String role;
  final String name;
  final String profileId;

  AuthenticatedUser({
    required this.firebaseUser,
    required this.role,
    required this.name,
    required this.profileId,
  });
}

class AuthProvider extends ChangeNotifier {
  AuthenticatedUser? currentUser;
  bool isLoading = false;
  String userRole = '';
  String userName = '';
  String? errorMessage;

  bool get isAuthenticated => currentUser != null;

  Future<bool> login(String email, String password, String expectedRole) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        errorMessage = 'Unable to authenticate user.';
        return false;
      }

      final userInfo = await _fetchUserInfo(firebaseUser.uid);
      if (userInfo == null) {
        await FirebaseAuth.instance.signOut();
        errorMessage = 'No user information found for this account.';
        return false;
      }

      if (userInfo.role != expectedRole) {
        await FirebaseAuth.instance.signOut();
        errorMessage = 'Selected portal does not match your account role.';
        return false;
      }

      currentUser = AuthenticatedUser(
        firebaseUser: firebaseUser,
        role: userInfo.role,
        name: userInfo.name,
        profileId: userInfo.profileId,
      );
      userRole = userInfo.role;
      userName = userInfo.name;
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _firebaseAuthErrorMessage(e);
      return false;
    } on FirebaseException catch (e) {
      errorMessage = 'Network error. Please try again.';
      return false;
    } catch (_) {
      errorMessage = 'Login failed. Please check your credentials.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    isLoading = true;
    notifyListeners();
    try {
      await FirebaseAuth.instance.signOut();
    } finally {
      _clearState();
      notifyListeners();
    }
  }

  Future<bool> loadCurrentUser() async {
    isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        return false;
      }

      final userInfo = await _fetchUserInfo(firebaseUser.uid);
      if (userInfo == null) {
        await FirebaseAuth.instance.signOut();
        return false;
      }

      currentUser = AuthenticatedUser(
        firebaseUser: firebaseUser,
        role: userInfo.role,
        name: userInfo.name,
        profileId: userInfo.profileId,
      );
      userRole = userInfo.role;
      userName = userInfo.name;
      return true;
    } catch (_) {
      await FirebaseAuth.instance.signOut();
      _clearState();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _clearState() {
    currentUser = null;
    userRole = '';
    userName = '';
    errorMessage = null;
    isLoading = false;
  }

  Future<_RoleUserInfo?> _fetchUserInfo(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;

      debugPrint('User data keys: ${data.keys.toList()}');
      debugPrint('id value: ${data["id"]}');
      debugPrint('role value: ${data["role"]}');
      debugPrint('username value: ${data["username"]}');

      final role = (data['role'] as String?)?.trim().toLowerCase();
      final username = (data['username'] as String?)?.trim();
      
      // Read profileId based on role
      String? id;
      if (role == 'teacher') {
        id = (data['tId'] as String?)?.trim();
      } else if (role == 'student') {
        id = (data['sId'] as String?)?.trim();
      } else if (role == 'admin') {
        id = (data['aId'] as String?)?.trim();
      }

      final profileId = id;
      final profileName = await _fetchProfileName(role, profileId);
      final displayName = profileName?.trim().isNotEmpty == true
          ? profileName!
          : username;

      if (role == null || role.isEmpty || profileId == null || profileId.isEmpty) {
        debugPrint('Missing required fields: role=$role, profileId=$profileId');
        return null;
      }
      if (displayName == null || displayName.isEmpty) {
        debugPrint('Missing display name for role=$role and profileId=$profileId');
        return null;
      }

      return _RoleUserInfo(
        role: role,
        name: displayName,
        profileId: profileId,
      );
    } catch (e) {
      debugPrint('Error in _fetchUserInfo: $e');
      return null;
    }
  }

  Future<String?> _fetchProfileName(String? role, String? profileId) async {
    if (role == null || profileId == null || profileId.isEmpty) return null;

    try {
      if (role == 'teacher') {
        final doc = await FirebaseFirestore.instance.collection('teachers').doc(profileId).get();
        if (!doc.exists) return null;
        final data = doc.data();
        return (data?['name'] as String?) ?? (data?['fullName'] as String?);
      }
      if (role == 'student') {
        final doc = await FirebaseFirestore.instance.collection('students').doc(profileId).get();
        if (!doc.exists) return null;
        final data = doc.data();
        return (data?['sName'] as String?) ?? (data?['name'] as String?);
      }
      if (role == 'admin') {
        final doc = await FirebaseFirestore.instance.collection('admins').doc(profileId).get();
        if (!doc.exists) return null;
        final data = doc.data();
        return (data?['aName'] as String?) ?? (data?['name'] as String?);
      }
    } catch (e) {
      debugPrint('Error fetching profile name: $e');
    }
    return null;
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account was found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'network-request-failed':
        return 'Network error. Please try again.';
      default:
        return exception.message ?? 'Authentication failed.';
    }
  }
}

class _RoleUserInfo {
  final String role;
  final String name;
  final String profileId;

  _RoleUserInfo({
    required this.role,
    required this.name,
    required this.profileId,
  });
}
