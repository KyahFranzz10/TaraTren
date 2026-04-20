import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Singleton Pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Current User Pointer
  User? get currentUser => _supabase.auth.currentUser;

  // Guest Check
  bool get isGuest => currentUser?.isAnonymous ?? (currentUser == null);

  // 1. Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'No Access Token found.';
      }

      final AuthResponse res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken!,
        accessToken: accessToken,
      );

      // Upsert User Data to Supabase Table 'users'
      if (res.user != null) {
        await _updateUserData(res.user!);
      }
      
      return res.user;
    } catch (e) {
      debugPrint("Error during Google Sign-In: $e");
      return null;
    }
  }

  // 2. Guest/Anonymous Sign-In
  Future<User?> signInAnonymously({String? username}) async {
    try {
      final AuthResponse res = await _supabase.auth.signInAnonymously();
      User? user = res.user;
      if (user != null) {
        if (username != null && username.isNotEmpty) {
          await _supabase.auth.updateUser(
            UserAttributes(data: {'display_name': username}),
          );
          user = _supabase.auth.currentUser;
        }
        await _updateUserData(user!);
      }
      return user;
    } catch (e) {
      debugPrint("Error during Guest Sign-In: $e");
      rethrow;
    }
  }

  // 2.5 Username/Password Sign-In (Internal mapping to Email)
  Future<User?> signUp(String username, String password, {String fareType = 'normal'}) async {
    try {
      final email = "$username@taratren.local";
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': username,
          'fare_type': fareType,
        },
      );
      if (res.user != null) {
        await _updateUserData(res.user!);
      }
      return res.user;
    } catch (e) {
      debugPrint("Error during Sign-Up: $e");
      rethrow;
    }
  }

  Future<User?> signIn(String username, String password) async {
    try {
      final email = "$username@taratren.local";
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user != null) {
        await _updateUserData(res.user!);
      }
      return res.user;
    } catch (e) {
      debugPrint("Error during Sign-In: $e");
      rethrow;
    }
  }

  // 3. Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut()
          .timeout(const Duration(seconds: 2))
          .catchError((_) => null);
    } catch (e) {
      debugPrint("Non-critical: Google Sign-Out timed out or failed: $e");
    }

    try {
      await _supabase.auth.signOut();
      debugPrint("Supabase Sign-Out successful");
    } catch (e) {
      debugPrint("Critical: Supabase Sign-Out failed: $e");
      rethrow;
    }
  }

  // 3.1 Delete Account (Self-service via RPC or cascading)
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) return;

      // Note: In a production Supabase app, self-deletion typically requires 
      // an Edge Function or RPC with service_role permissions.
      // For this implementation, we rely on the Cascade triggers we set in SQL.
      // We first clear our profile data which signals the backend.
      await _supabase.from('profiles').delete().eq('id', user.id);
      
      // Finally sign out to clear session
      await signOut();
    } catch (e) {
      debugPrint("Error during account deletion: $e");
      rethrow;
    }
  }

  // 3. Persist User Data (Postgres Table 'users')
  Future<void> _updateUserData(User user) async {
    await _supabase.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      'avatar_url': user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
      'display_name': user.userMetadata?['display_name'] ?? user.userMetadata?['name'],
      'fare_type': user.userMetadata?['fare_type'] ?? 'normal',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // 4. Favorites Logic (Table 'favorites')
  Future<void> toggleFavorite(String stationName) async {
    final user = currentUser;
    if (user == null) {
      debugPrint("Error: User is not logged in!");
      return;
    }

    final String cleanName = stationName.trim();

    try {
      final response = await _supabase.from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('station_name', cleanName)
          .maybeSingle();

      if (response != null) {
        await _supabase.from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('station_name', cleanName);
      } else {
        await _supabase.from('favorites').insert({
          'user_id': user.id,
          'station_name': cleanName,
          'added_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint("ERROR saving favorite to cloud: $e");
    }
  }

  // 5. Get Favorites Stream
  Stream<List<Map<String, dynamic>>> getFavorites() {
    final user = currentUser;
    if (user == null) return const Stream.empty();
    return _supabase.from('favorites')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id);
  }

  // 6. Get Profile Stream
  Stream<Map<String, dynamic>?> getProfileStream() {
    final user = currentUser;
    if (user == null) return const Stream.empty();
    return _supabase.from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((data) => data.isNotEmpty ? data.first : null);
  }

  // 7. Update Commuter Preferences
  Future<void> updateCommuterProfile({
    String? favStation,
    String? futureLineHype,
    String? favTrainSet,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final updates = {
      'id': user.id,
      if (favStation != null) 'fav_station': favStation,
      if (futureLineHype != null) 'future_line_hype': futureLineHype,
      if (favTrainSet != null) 'fav_train_set': favTrainSet,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('profiles').upsert(updates);
  }
}
