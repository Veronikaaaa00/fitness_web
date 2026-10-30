class AuthTokenStore {
  String? accessToken;
  String? refreshToken;
  String? userId;

  void setTokens({
    required String access,
    String? refresh,
    String? userId,
  }) {
    accessToken = access;
    if (refresh != null) refreshToken = refresh;
    if (userId != null) this.userId = userId;
  }

  void clear() {
    accessToken = null;
    refreshToken = null;
    userId = null;
  }
}
