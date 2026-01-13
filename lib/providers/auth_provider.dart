import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/firebase_service.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/user_repository.dart';

/// Auth state
enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final User? user;
  final UserProfile? profile;
  final bool isAdmin;
  final String? error;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.profile,
    this.isAdmin = false,
    this.error,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    UserProfile? profile,
    bool? isAdmin,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isAdmin: isAdmin ?? this.isAdmin,
      error: error,
    );
  }
}

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final _userRepository = UserRepository();
  static const String _adminEmail = 'sourabh3527@gmail.com';

  AuthNotifier() : super(AuthState()) {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    FirebaseService.auth.authStateChanges().listen((user) async {
      if (user == null) {
        state = AuthState(status: AuthStatus.unauthenticated);
      } else {
        // Fetch user profile
        final profile = await _userRepository.getUserById(user.uid);
        final isAdmin = user.email == _adminEmail;

        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          profile: profile,
          isAdmin: isAdmin,
        );
      }
    });
  }

  /// Sign in anonymously
  Future<void> signInAnonymously() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final credential = await FirebaseService.signInAnonymously();

      // Create default profile if new user
      if (credential.user != null) {
        final existingProfile = await _userRepository.getUserById(
          credential.user!.uid,
        );
        if (existingProfile == null) {
          final newProfile = UserProfile(
            id: credential.user!.uid,
            name: 'Pilgrim',
            age: 0,
            isVerified: false,
            emergencyContacts: [],
          );
          await _userRepository.saveProfile(newProfile);
        }
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final credential = await FirebaseService.signInWithGoogle();

      if (credential == null) {
        // User cancelled
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      // Check if profile exists
      if (credential.user != null) {
        final user = credential.user!;
        final existingProfile = await _userRepository.getUserById(user.uid);
        final isAdmin = user.email == AuthNotifier._adminEmail;

        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          profile: existingProfile, // Can be null, UI will handle redirection
          isAdmin: isAdmin,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  /// Update profile
  Future<void> updateProfile(UserProfile profile) async {
    await _userRepository.saveProfile(profile);
    state = state.copyWith(profile: profile);
  }

  /// Sign out
  Future<void> signOut() async {
    await FirebaseService.signOut();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

/// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final currentProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authProvider).profile;
});
