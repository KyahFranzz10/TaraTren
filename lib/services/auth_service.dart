import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Current User Pointer
  User? get currentUser => _auth.currentUser;

  // 1. Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Upsert User Data to Firestore
      if (userCredential.user != null) {
        await _updateUserData(userCredential.user!);
      }
      
      return userCredential.user;
    } catch (e) {
      print("Error during Google Sign-In: $e");
      return null;
    }
  }

  // 2. Guest/Anonymous Sign-In
  Future<User?> signInAnonymously({String? username}) async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      User? user = userCredential.user;
      if (user != null) {
        if (username != null && username.isNotEmpty) {
          await user.updateDisplayName(username);
          await user.reload();
          user = _auth.currentUser;
        }
        await _updateUserData(user!);
      }
      return user;
    } catch (e) {
      debugPrint("Error during Guest Sign-In: $e");
      rethrow;
    }
  }

  // 3. Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 3. Persist User Data
  Future<void> _updateUserData(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    await userRef.set({
      'uid': user.uid,
      'email': user.email,
      'photoURL': user.photoURL,
      'displayName': user.displayName,
      'lastSignIn': DateTime.now(),
    }, SetOptions(merge: true));
  }

  // 4. Favorites Logic
  Future<void> toggleFavorite(String stationName) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("Error: User is not logged in!");
      return;
    }

    try {
      final favoriteRef = _firestore.collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(stationName);
      
      final doc = await favoriteRef.get();
      if (doc.exists) {
        await favoriteRef.delete();
      } else {
        await favoriteRef.set({
          'name': stationName,
          'addedAt': DateTime.now(),
        });
      }
    } catch (e) {
      print("ERROR saving favorite to cloud: $e");
    }
  }

  // 5. Get Favorites Stream
  Stream<QuerySnapshot> getFavorites() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore.collection('users').doc(user.uid).collection('favorites').snapshots();
  }
}
