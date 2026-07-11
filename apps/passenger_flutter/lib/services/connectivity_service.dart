import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
class ConnectivityService {
  final _connectivity=Connectivity();
  Stream<bool> get online=>_connectivity.onConnectivityChanged.map((r)=>!r.contains(ConnectivityResult.none)).distinct();
  Future<bool> isOnline() async=>!(await _connectivity.checkConnectivity()).contains(ConnectivityResult.none);
}
