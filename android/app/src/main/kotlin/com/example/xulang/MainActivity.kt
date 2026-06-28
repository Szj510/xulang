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
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.math.max

class MainActivity : FlutterActivity() {
    private val recorderChannel = "xulang/native_screen_recorder"
    private val mediaProjectionRequestCode = 4207

    private var pendingResult: MethodChannel.Result? = null
    private var pendingArgs: RecorderArgs? = null
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
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    @Deprecated("Deprecated in Android Activity API, still used by FlutterActivity embedding callback.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != mediaProjectionRequestCode) return
        val result = pendingResult ?: return
        val args = pendingArgs
        pendingResult = null
        pendingArgs = null
        if (resultCode != Activity.RESULT_OK || data == null || args == null) {
            result.error("permission_denied", "Screen recording permission was not granted.", null)
            return
        }
        try {
            startProjectionRecording(resultCode, data, args)
            result.success(args.outputPath)
        } catch (error: Throwable) {
            cleanupRecording(deleteOutput = true)
            result.error("recording_start_failed", error.message, null)
        }
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
