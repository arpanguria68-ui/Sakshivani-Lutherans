class AppUser {
  const AppUser({
    required this.uid,
    required this.isAnonymous,
    required this.isLocalOnly,
    this.email,
    this.displayName,
  });

  final String uid;
  final bool isAnonymous;
  final bool isLocalOnly;
  final String? email;
  final String? displayName;

  bool get isSignedIn => !isAnonymous && !isLocalOnly;
}
