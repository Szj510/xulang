package com.example.xulang

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionConfig
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.math.max

class MainActivity : FlutterActivity() {
    private val recorderChannel = "xulang/native_screen_recorder"
    private val documentAccessChannel = "xulang/document_access"
    private val mediaProjectionRequestCode = 4207
    private val documentTreeRequestCode = 4208
    private val documentScanFileLimit = 500
    private val documentScanVisitLimit = 4000

    private var pendingResult: MethodChannel.Result? = null
    private var pendingArgs: RecorderArgs? = null
    private var pendingDocumentTreeResult: MethodChannel.Result? = null
    private var mediaProjection: MediaProjection? = null
    private var mediaProjectionCallback: MediaProjection.Callback? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var mediaRecorder: MediaRecorder? = null
    private var outputPath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, recorderChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> result.success(true)
                    "start" -> startRecording(call, result)
                    "stop" -> stopRecording(result)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, documentAccessChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openTree" -> openDocumentTree(result)
                    "listFiles" -> listDocumentFiles(call, result)
                    "readText" -> readDocumentText(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    @Deprecated("Deprecated in Android Activity API, still used by FlutterActivity embedding callback.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == documentTreeRequestCode) {
            handleDocumentTreeResult(resultCode, data)
            return
        }
        if (requestCode != mediaProjectionRequestCode) return
        val result = pendingResult ?: return
        val args = pendingArgs
        pendingResult = null
        pendingArgs = null
        if (resultCode != Activity.RESULT_OK || data == null || args == null) {
            result.error("permission_denied", "Screen recording permission was not granted.", null)
            return
        }
        startMediaProjectionForegroundService()
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                startProjectionRecording(resultCode, data, args)
                result.success(args.outputPath)
            } catch (error: Throwable) {
                cleanupRecording(deleteOutput = true)
                result.error("recording_start_failed", error.message, null)
            }
        }, 300)
    }

    private fun openDocumentTree(result: MethodChannel.Result) {
        if (pendingDocumentTreeResult != null) {
            result.error("already_opening", "A folder authorization request is already open.", null)
            return
        }
        pendingDocumentTreeResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
        }
        startActivityForResult(intent, documentTreeRequestCode)
    }

    private fun handleDocumentTreeResult(resultCode: Int, data: Intent?) {
        val result = pendingDocumentTreeResult ?: return
        pendingDocumentTreeResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        val flags = data.flags and
            (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        try {
            contentResolver.takePersistableUriPermission(uri, flags)
        } catch (_: Throwable) {
            // Some providers do not expose persistable grants; the current URI is still usable now.
        }
        result.success(uri.toString())
    }

    private fun listDocumentFiles(call: MethodCall, result: MethodChannel.Result) {
        val roots = call.argument<List<String>>("roots") ?: emptyList()
        val extensions = (call.argument<List<String>>("extensions") ?: emptyList())
            .map { it.lowercase() }
            .toSet()
        Thread {
            try {
                val files = mutableListOf<Map<String, Any?>>()
                for (root in roots) {
                    val tree = DocumentFile.fromTreeUri(this, Uri.parse(root)) ?: continue
                    collectDocumentFiles(tree, extensions, files)
                    if (files.size >= documentScanFileLimit) break
                }
                postMethodResult { result.success(files) }
            } catch (error: Throwable) {
                postMethodResult { result.error("document_scan_failed", error.message, null) }
            }
        }.start()
    }

    private fun collectDocumentFiles(
        root: DocumentFile,
        extensions: Set<String>,
        files: MutableList<Map<String, Any?>>,
    ) {
        val pending = java.util.ArrayDeque<DocumentFile>()
        pending.add(root)
        var visited = 0
        while (
            pending.isNotEmpty() &&
            files.size < documentScanFileLimit &&
            visited < documentScanVisitLimit
        ) {
            val document = pending.removeFirst()
            visited += 1
            try {
                if (document.isFile) {
                    val name = document.name ?: continue
                    val lower = name.lowercase()
                    if (extensions.isEmpty() || extensions.any { lower.endsWith(it) }) {
                        files.add(
                            mapOf(
                                "uri" to document.uri.toString(),
                                "name" to name,
                                "size" to document.length(),
                                "modified" to document.lastModified(),
                            ),
                        )
                    }
                    continue
                }
                if (!document.isDirectory) continue
                for (child in document.listFiles()) {
                    if (pending.size + files.size >= documentScanVisitLimit) break
                    pending.add(child)
                }
            } catch (_: Throwable) {
                // Some providers expose entries that cannot be queried; skip them and continue scanning.
            }
        }
    }

    private fun readDocumentText(call: MethodCall, result: MethodChannel.Result) {
        val uriText = call.argument<String>("uri")
        if (uriText.isNullOrBlank()) {
            result.error("missing_uri", "Document URI is required.", null)
            return
        }
        Thread {
            try {
                val text = contentResolver.openInputStream(Uri.parse(uriText)).use { stream ->
                    stream?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }
                        ?: throw IllegalStateException("Unable to open document.")
                }
                postMethodResult { result.success(text) }
            } catch (error: Throwable) {
                postMethodResult { result.error("document_read_failed", error.message, null) }
            }
        }.start()
    }

    private fun postMethodResult(action: () -> Unit) {
        Handler(Looper.getMainLooper()).post(action)
    }

    private fun startRecording(call: MethodCall, result: MethodChannel.Result) {
        if (mediaRecorder != null || pendingResult != null) {
            result.error("already_recording", "A screen recording is already in progress.", null)
            return
        }
        val outputPath = call.argument<String>("outputPath") ?: defaultOutputPath()
        val width = sanitizeDimension(call.argument<Int>("width") ?: resources.displayMetrics.widthPixels)
        val height = sanitizeDimension(call.argument<Int>("height") ?: resources.displayMetrics.heightPixels)
        val frameRate = (call.argument<Int>("frameRate") ?: 30).coerceIn(15, 60)
        val bitRate = max(call.argument<Int>("bitRate") ?: 8_000_000, 1_000_000)
        val args = RecorderArgs(outputPath, width, height, frameRate, bitRate)
        File(outputPath).parentFile?.mkdirs()

        pendingResult = result
        pendingArgs = args
        val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(createCaptureIntent(manager), mediaProjectionRequestCode)
    }

    private fun createCaptureIntent(manager: MediaProjectionManager): Intent {
        return if (Build.VERSION.SDK_INT >= 34) {
            manager.createScreenCaptureIntent(
                MediaProjectionConfig.createConfigForDefaultDisplay(),
            )
        } else {
            manager.createScreenCaptureIntent()
        }
    }

    private fun startProjectionRecording(resultCode: Int, data: Intent, args: RecorderArgs) {
        val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val projection = manager.getMediaProjection(resultCode, data)
            ?: throw IllegalStateException("Unable to create media projection.")
        mediaProjection = projection
        val callback = object : MediaProjection.Callback() {
            override fun onStop() {
                cleanupRecording(deleteOutput = false)
            }
        }
        mediaProjectionCallback = callback
        projection.registerCallback(callback, Handler(Looper.getMainLooper()))

        val recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(this)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }
        recorder.setVideoSource(MediaRecorder.VideoSource.SURFACE)
        recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        recorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
        recorder.setVideoSize(args.width, args.height)
        recorder.setVideoFrameRate(args.frameRate)
        recorder.setVideoEncodingBitRate(args.bitRate)
        recorder.setOutputFile(args.outputPath)
        recorder.prepare()
        mediaRecorder = recorder
        outputPath = args.outputPath
        virtualDisplay = projection.createVirtualDisplay(
            "xulang-screen-recording",
            args.width,
            args.height,
            resources.displayMetrics.densityDpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            recorder.surface,
            null,
            null,
        )
        recorder.start()
    }

    private fun stopRecording(result: MethodChannel.Result) {
        val path = outputPath
        try {
            mediaRecorder?.apply {
                try {
                    stop()
                } catch (_: RuntimeException) {
                    if (path != null) File(path).delete()
                    throw IllegalStateException("Recording was too short to finalize.")
                }
            }
            cleanupRecording(deleteOutput = false)
            result.success(path)
        } catch (error: Throwable) {
            cleanupRecording(deleteOutput = true)
            result.error("recording_stop_failed", error.message, null)
        }
    }

    private fun cleanupRecording(deleteOutput: Boolean) {
        val path = outputPath
        virtualDisplay?.release()
        virtualDisplay = null
        mediaRecorder?.reset()
        mediaRecorder?.release()
        mediaRecorder = null
        mediaProjectionCallback?.let { callback ->
            try {
                mediaProjection?.unregisterCallback(callback)
            } catch (_: Throwable) {
                // Projection may already be stopped by the system.
            }
        }
        mediaProjectionCallback = null
        mediaProjection?.stop()
        mediaProjection = null
        outputPath = null
        pendingResult = null
        pendingArgs = null
        if (deleteOutput && path != null) File(path).delete()
        stopMediaProjectionForegroundService()
    }

    private fun startMediaProjectionForegroundService() {
        val intent = Intent(this, MediaProjectionForegroundService::class.java).apply {
            action = MediaProjectionForegroundService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopMediaProjectionForegroundService() {
        val intent = Intent(this, MediaProjectionForegroundService::class.java).apply {
            action = MediaProjectionForegroundService.ACTION_STOP
        }
        startService(intent)
    }

    private fun sanitizeDimension(value: Int): Int {
        val even = if (value % 2 == 0) value else value - 1
        return even.coerceAtLeast(320)
    }

    private fun defaultOutputPath(): String {
        val directory = File(cacheDir, "recordings")
        directory.mkdirs()
        return File(directory, "xulang-recording-${System.currentTimeMillis()}.mp4").absolutePath
    }

    private data class RecorderArgs(
        val outputPath: String,
        val width: Int,
        val height: Int,
        val frameRate: Int,
        val bitRate: Int,
    )
}
