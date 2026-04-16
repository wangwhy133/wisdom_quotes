package com.wangli.wisdom_quotes

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Configure native alarm scheduler
        NativeAlarmSchedulerPlugin(this).configure(flutterEngine)
    }
}
