package com.pluck.pluck

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.webkit.CookieManager
import com.chaquo.python.PyObject
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.nio.ByteBuffer
import java.util.concurrent.Executors

/**
 * Native side of Pluck. Everything runs on the phone:
 *  - yt-dlp (Python, via Chaquopy) resolves links and downloads media
 *  - MediaMuxer merges HD video + audio (no ffmpeg needed)
 *  - Storage Access Framework reads WhatsApp statuses
 */
class MainActivity : FlutterActivity() {
    private val channelName = "pluck/native"
    private var channel: MethodChannel? = null
    private var pendingTree: MethodChannel.Result? = null
    private var sharedText: String? = null
    private val io = Executors.newFixedThreadPool(4)
    private val main = Handler(Looper.getMainLooper())
    private var engine: PyObject? = null

    companion object {
        private const val REQ_TREE = 7031
        private const val STATUS_WA = "Android/media/com.whatsapp/WhatsApp/Media/.Statuses"
        private const val STATUS_WB = "Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses"
        private const val STATUS_WA_LEGACY = "WhatsApp/Media/.Statuses"
        private const val STATUS_WB_LEGACY = "WhatsApp Business/Media/.Statuses"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sharedText = extractShared(intent)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "takeSharedText" -> { result.success(sharedText); sharedText = null }
                "resolve" -> background(result) { resolve(call.argument<String>("url")!!) }
                "download" -> background(result) {
                    download(
                        call.argument<String>("id")!!, call.argument<String>("url")!!, call.argument<String>("spec")!!,
                        call.argument<String>("outDir")!!, call.argument<String>("baseName")!!,
                    )
                }
                "cancel" -> { io.execute { runCatching { py().callAttr("cancel", call.argument<String>("id")) } }; result.success(null) }
                "engineVersion" -> background(result) { py().callAttr("version").toString() }
                "updateEngine" -> background(result) { updateEngine() }
                "clearBrowserData" -> {
                    CookieManager.getInstance().removeAllCookies(null)
                    CookieManager.getInstance().flush()
                    File(filesDir, "cookies.txt").delete()
                    result.success(null)
                }
                "pickStatusTree" -> pickTree(call.argument<String>("variant") ?: "whatsapp", result)
                "listStatuses" -> background(result) { listStatuses(Uri.parse(call.argument<String>("tree")!!)) }
                "copyToCache" -> background(result) { copyToCache(Uri.parse(call.argument<String>("uri")!!), call.argument<String>("name")!!) }
                "videoThumb" -> background(result) { videoThumb(Uri.parse(call.argument<String>("uri")!!)) }
                else -> result.notImplemented()
            }
        }
    }

    private fun background(result: MethodChannel.Result, block: () -> Any?) {
        io.execute {
            try {
                val value = block()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("PLUCK", e.message ?: "Something went wrong. Try again.", null) }
            }
        }
    }

    // ── Engine ────────────────────────────────────────────────────────────
    @Synchronized
    private fun py(): PyObject {
        engine?.let { return it }
        if (!Python.isStarted()) Python.start(AndroidPlatform(applicationContext))
        val mod = Python.getInstance().getModule("pluck_engine")
        mod.callAttr("init", filesDir.absolutePath)
        engine = mod
        return mod
    }

    /** If the user logged in to a site inside Pluck's browser, hand that session to the engine. Stays on the phone. */
    private fun syncBrowserCookies() {
        val cm = runCatching { CookieManager.getInstance() }.getOrNull() ?: return
        val domains = listOf("instagram.com", "facebook.com", "tiktok.com", "x.com", "twitter.com", "pinterest.com", "youtube.com", "vimeo.com", "dailymotion.com")
        val sb = StringBuilder("# Netscape HTTP Cookie File\n")
        var any = false
        for (d in domains) {
            val raw = cm.getCookie("https://www.$d") ?: continue
            raw.split(";").map { it.trim() }.filter { it.contains("=") }.forEach {
                sb.append(".$d\tTRUE\t/\tTRUE\t2147483647\t${it.substringBefore("=")}\t${it.substringAfter("=")}\n")
                any = true
            }
        }
        val f = File(filesDir, "cookies.txt")
        if (any) f.writeText(sb.toString()) else f.delete()
    }

    private fun resolve(url: String): String {
        syncBrowserCookies()
        val raw = py().callAttr("resolve", url).toString()
        val json = JSONObject(raw)
        if (json.has("error")) throw Exception(json.getString("error"))
        return raw
    }

    /** Kotlin object handed to Python; Python calls sink.update(done, total). */
    inner class ProgressSink(private val id: String) {
        fun update(done: Long, total: Long) {
            main.post { channel?.invokeMethod("progress", mapOf("id" to id, "done" to done, "total" to total)) }
        }
    }

    private fun download(id: String, url: String, spec: String, outDir: String, baseName: String): String {
        syncBrowserCookies()
        val raw = py().callAttr("download", url, spec, outDir, baseName, id, ProgressSink(id)).toString()
        val json = JSONObject(raw)
        if (json.has("error")) throw Exception(json.getString("error"))
        if (json.optBoolean("mux")) {
            val video = json.getString("video")
            val audio = json.getString("audio")
            val out = json.getString("out")
            try {
                mux(video, audio, out)
            } finally {
                File(video).delete(); File(audio).delete()
            }
            return out
        }
        return json.getString("path")
    }

    /** Lossless merge of an H.264 video track and an AAC audio track into one MP4. */
    private fun mux(videoPath: String, audioPath: String, outPath: String) {
        val muxer = MediaMuxer(outPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        val tracks = mutableListOf<Pair<MediaExtractor, Int>>()
        try {
            for ((path, prefix) in listOf(videoPath to "video/", audioPath to "audio/")) {
                val ex = MediaExtractor()
                ex.setDataSource(path)
                for (i in 0 until ex.trackCount) {
                    val fmt = ex.getTrackFormat(i)
                    if (fmt.getString(MediaFormat.KEY_MIME)?.startsWith(prefix) == true) {
                        ex.selectTrack(i)
                        tracks.add(ex to muxer.addTrack(fmt))
                        break
                    }
                }
            }
            if (tracks.size != 2) throw Exception("Couldn’t merge video and audio for this one. Try a lower quality.")
            muxer.start()
            val buffer = ByteBuffer.allocate(8 * 1024 * 1024)
            val info = MediaCodec.BufferInfo()
            for ((ex, track) in tracks) {
                while (true) {
                    val size = ex.readSampleData(buffer, 0)
                    if (size < 0) break
                    info.set(0, size, ex.sampleTime,
                        if (ex.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC != 0) MediaCodec.BUFFER_FLAG_KEY_FRAME else 0)
                    muxer.writeSampleData(track, buffer, info)
                    ex.advance()
                }
            }
            muxer.stop()
        } finally {
            tracks.forEach { it.first.release() }
            runCatching { muxer.release() }
        }
    }

    /** Free self-update: newest yt-dlp release (pure-Python zip) from GitHub. Used from next launch. */
    private fun updateEngine(): String {
        val tmp = File(filesDir, "yt-dlp.zip.part")
        var url = URL("https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp")
        var conn: HttpURLConnection
        var hops = 0
        while (true) {
            conn = url.openConnection() as HttpURLConnection
            conn.instanceFollowRedirects = false
            conn.connectTimeout = 15000
            conn.readTimeout = 60000
            val code = conn.responseCode
            if (code in 300..399 && hops++ < 5) {
                url = URL(url, conn.getHeaderField("Location")); conn.disconnect(); continue
            }
            if (code != 200) throw Exception("Update failed (HTTP $code). Try again later.")
            break
        }
        conn.inputStream.use { input -> tmp.outputStream().use { input.copyTo(it) } }
        if (tmp.length() < 1_000_000) throw Exception("Update file looks wrong. Try again later.")
        tmp.renameTo(File(filesDir, "yt-dlp.zip"))
        return Regex("/download/([0-9.]+)/").find(url.toString())?.groupValues?.get(1) ?: "latest"
    }

    // ── Share-to-Pluck ────────────────────────────────────────────────────
    private fun extractShared(i: Intent?): String? =
        if (i?.action == Intent.ACTION_SEND && i.type?.startsWith("text/") == true) i.getStringExtra(Intent.EXTRA_TEXT) else null

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        extractShared(intent)?.let { channel?.invokeMethod("sharedText", it) }
    }

    // ── WhatsApp statuses ─────────────────────────────────────────────────
    private fun pickTree(variant: String, result: MethodChannel.Result) {
        pendingTree = result
        val modern = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R
        val path = when {
            variant == "business" && modern -> STATUS_WB
            variant == "business" -> STATUS_WB_LEGACY
            modern -> STATUS_WA
            else -> STATUS_WA_LEGACY
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                putExtra(
                    DocumentsContract.EXTRA_INITIAL_URI,
                    DocumentsContract.buildDocumentUri("com.android.externalstorage.documents", "primary:$path"),
                )
            }
        }
        @Suppress("DEPRECATION")
        startActivityForResult(intent, REQ_TREE)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQ_TREE) return
        val res = pendingTree ?: return
        pendingTree = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) { res.success(null); return }
        contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        if (!Uri.decode(uri.toString()).contains(".Statuses")) {
            res.error("PLUCK", "That isn’t the .Statuses folder. Tap the button again and choose “Use this folder” without moving.", null)
            return
        }
        res.success(uri.toString())
    }

    private fun listStatuses(tree: Uri): List<Map<String, Any?>> {
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        val cols = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
            DocumentsContract.Document.COLUMN_SIZE,
        )
        val out = mutableListOf<Map<String, Any?>>()
        contentResolver.query(children, cols, null, null, null)?.use { c ->
            while (c.moveToNext()) {
                val name = c.getString(1) ?: continue
                val mime = c.getString(2) ?: ""
                if (name.startsWith(".") || !(mime.startsWith("image/") || mime.startsWith("video/"))) continue
                out.add(mapOf(
                    "uri" to DocumentsContract.buildDocumentUriUsingTree(tree, c.getString(0)).toString(),
                    "name" to name,
                    "mime" to mime,
                    "modified" to c.getLong(3),
                    "size" to c.getLong(4),
                ))
            }
        } ?: throw Exception("Status folder unavailable")
        return out
    }

    private fun copyToCache(uri: Uri, name: String): String {
        val dir = File(cacheDir, "statuses").apply { mkdirs() }
        val out = File(dir, name)
        if (!out.exists() || out.length() == 0L) {
            contentResolver.openInputStream(uri)?.use { input -> out.outputStream().use { input.copyTo(it) } }
                ?: throw Exception("Couldn’t open that status")
        }
        return out.absolutePath
    }

    private fun videoThumb(uri: Uri): ByteArray? {
        val r = MediaMetadataRetriever()
        return try {
            r.setDataSource(applicationContext, uri)
            val frame = r.getFrameAtTime(500_000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC) ?: return null
            val scale = 360f / frame.width.coerceAtLeast(1)
            val small = Bitmap.createScaledBitmap(frame, 360, (frame.height * scale).toInt().coerceAtLeast(1), true)
            ByteArrayOutputStream().use { small.compress(Bitmap.CompressFormat.JPEG, 78, it); it.toByteArray() }
        } catch (e: Exception) {
            null
        } finally {
            runCatching { r.release() }
        }
    }
}
