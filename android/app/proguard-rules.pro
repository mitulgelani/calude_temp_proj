# Python (Chaquopy) calls ProgressSink.update(...) by reflection — keep Pluck's native classes intact.
-keep class com.pluck.pluck.** { *; }
-keep class com.chaquo.python.** { *; }
