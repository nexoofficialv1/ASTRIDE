class Session {
  const Session({required this.userId,required this.token,required this.mobile});
  final String userId,token,mobile;
  Map<String,String> get authHeaders=>{'authorization':'Bearer $token'};
}
