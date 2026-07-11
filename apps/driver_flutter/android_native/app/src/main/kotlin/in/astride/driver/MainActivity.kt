package `in`.astride.driver

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "in.astride.driver/location_service"
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val intent = Intent(this, LocationForegroundService::class.java).setAction(LocationForegroundService.ACTION_START)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent) else startService(intent)
                    result.success(true)
                }
                "stop" -> {
                    startService(Intent(this, LocationForegroundService::class.java).setAction(LocationForegroundService.ACTION_STOP))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
