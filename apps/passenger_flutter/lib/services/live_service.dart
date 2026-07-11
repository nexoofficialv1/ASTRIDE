import 'dart:async';import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/app_config.dart';
class LiveService {WebSocketChannel? _channel;Timer? _retry;final _events=StreamController<Map<String,dynamic>>.broadcast();Stream<Map<String,dynamic>> get events=>_events.stream;
 void connect(String bookingId){disconnect();try{_channel=WebSocketChannel.connect(Uri.parse('${AppConfig.wsBaseUrl}/v1/live?bookingId=$bookingId'));_channel!.stream.listen((e){final d=jsonDecode(e.toString());if(d is Map)_events.add(d.cast<String,dynamic>());},onDone:()=>_schedule(bookingId),onError:(_)=>_schedule(bookingId));}catch(_){_schedule(bookingId);}}
 void _schedule(String id){_retry?.cancel();_retry=Timer(const Duration(seconds:3),()=>connect(id));}
 void disconnect(){_retry?.cancel();_channel?.sink.close();_channel=null;}void dispose(){disconnect();_events.close();}}
