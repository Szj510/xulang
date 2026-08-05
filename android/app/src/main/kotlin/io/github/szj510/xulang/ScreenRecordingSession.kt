package io.github.szj510.xulang

import android.content.Context
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioPlaybackCaptureConfiguration
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.os.Handler
import android.os.Looper
import java.io.File
import java.nio.ByteBuffer
import kotlin.math.max

internal data class RecordingOptions(
    val outputPath: String,
    val width: Int,
    val height: Int,
    val frameRate: Int,
    val bitRate: Int,
)

internal class ScreenRecordingSession(
    private val context: Context,
    private val projection: MediaProjection,
    private val options: RecordingOptions,
    private val onProjectionStopped: () -> Unit = {},
) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val recordingDirectory = File(context.cacheDir, "recordings")
    private val videoTempFile = File(recordingDirectory, "${options.outputPath.hashCode().toUInt().toString(16)}-video.mp4")
    private val audioTempFile = File(recordingDirectory, "${options.outputPath.hashCode().toUInt().toString(16)}-audio.m4a")
    private val projectionCallback = object : MediaProjection.Callback() {
        override fun onStop() {
            releaseFromProjectionStop()
        }
    }

    private var mediaRecorder: MediaRecorder? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var audioRecorder: PlaybackAudioRecorder? = null
    private var projectionCallbackRegistered = false
    @Volatile
    private var stopped = false
    @Volatile
    private var released = false

    fun start() {
        recordingDirectory.mkdirs()
        projection.registerCallback(projectionCallback, mainHandler)
        projectionCallbackRegistered = true
        try {
            startVideoRecorder()
            startAudioRecorder()
        } catch (error: Throwable) {
            releaseInternal(deleteOutput = true, stopProjection = true)
            throw error
        }
    }

    fun stop(): String {
        if (released) return options.outputPath
        stopped = true
        val stopError = runCatching {
            stopAudioRecorder()
            stopVideoRecorder()
            finalizeOutput()
        }.exceptionOrNull()

        releaseInternal(deleteOutput = stopError != null, stopProjection = true)
        if (stopError != null) throw stopError
        return options.outputPath
    }

    private fun startVideoRecorder() {
        val recorder = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            MediaRecorder(context)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }
        recorder.setVideoSource(MediaRecorder.VideoSource.SURFACE)
        recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        recorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
        recorder.setVideoSize(options.width, options.height)
        recorder.setVideoFrameRate(options.frameRate)
        recorder.setVideoEncodingBitRate(options.bitRate)
        recorder.setOutputFile(videoTempFile.absolutePath)
        recorder.prepare()
        mediaRecorder = recorder
        virtualDisplay = projection.createVirtualDisplay(
            "xulang-screen-recording",
            options.width,
            options.height,
            context.resources.displayMetrics.densityDpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            recorder.surface,
            null,
            null,
        )
        recorder.start()
    }

    private fun startAudioRecorder() {
        val recorder = PlaybackAudioRecorder(
            projection = projection,
            outputFile = audioTempFile,
        )
        runCatching {
            recorder.start()
            audioRecorder = recorder
        }.onFailure {
            runCatching { recorder.stop() }
        }
    }

    private fun stopVideoRecorder() {
        val recorder = mediaRecorder ?: return
        mediaRecorder = null
        try {
            recorder.stop()
        } finally {
            recorder.reset()
            recorder.release()
            virtualDisplay?.release()
            virtualDisplay = null
        }
    }

    private fun stopAudioRecorder() {
        val recorder = audioRecorder ?: return
        audioRecorder = null
        recorder.stop()
    }

    private fun finalizeOutput() {
        File(options.outputPath).parentFile?.mkdirs()
        if (audioTempFile.exists() && audioTempFile.length() > 0L) {
            muxVideoAndAudio(
                videoFile = videoTempFile,
                audioFile = audioTempFile,
                outputFile = File(options.outputPath),
            )
        } else {
            moveFile(videoTempFile, File(options.outputPath))
        }
    }

    private fun releaseFromProjectionStop() {
        if (released) return
        releaseInternal(deleteOutput = true, stopProjection = false)
        onProjectionStopped()
    }

    private fun releaseInternal(deleteOutput: Boolean, stopProjection: Boolean) {
        if (released) return
        released = true
        runCatching { audioRecorder?.stop() }
        audioRecorder = null
        runCatching { mediaRecorder?.stop() }
        mediaRecorder?.reset()
        mediaRecorder?.release()
        mediaRecorder = null
        virtualDisplay?.release()
        virtualDisplay = null
        if (projectionCallbackRegistered) {
            runCatching { projection.unregisterCallback(projectionCallback) }
            projectionCallbackRegistered = false
        }
        if (stopProjection) {
            runCatching { projection.stop() }
        }
        if (deleteOutput) {
            deleteQuietly(videoTempFile)
            deleteQuietly(audioTempFile)
            deleteQuietly(File(options.outputPath))
        }
        deleteQuietly(videoTempFile)
        deleteQuietly(audioTempFile)
    }
}

private class PlaybackAudioRecorder(
    projection: MediaProjection,
    private val outputFile: File,
) {
    private val sampleRate = 44_100
    private val channelCount = 2
    private val channelMask = AudioFormat.CHANNEL_IN_STEREO
    private val pcmEncoding = AudioFormat.ENCODING_PCM_16BIT
    private val bufferSize = max(
        AudioRecord.getMinBufferSize(sampleRate, channelMask, pcmEncoding),
        sampleRate * channelCount,
    )
    private val audioRecord = createAudioRecord(projection)
    private val encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
    private val muxer = MediaMuxer(outputFile.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
    private val captureBuffer = ByteArray(bufferSize)
    private val bufferInfo = MediaCodec.BufferInfo()

    @Volatile
    private var stopped = false
    private var encoderTrackIndex = -1
    private var muxerStarted = false
    private var captureThread: Thread? = null
    private var totalFramesCaptured = 0L

    fun start() {
        val format = MediaFormat.createAudioFormat(
            MediaFormat.MIMETYPE_AUDIO_AAC,
            sampleRate,
            channelCount,
        ).apply {
            setInteger(
                MediaFormat.KEY_AAC_PROFILE,
                MediaCodecInfo.CodecProfileLevel.AACObjectLC,
            )
            setInteger(MediaFormat.KEY_BIT_RATE, 128_000)
            setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, bufferSize)
        }
        encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        encoder.start()
        audioRecord.startRecording()
        captureThread = Thread(::captureLoop, "xulang-audio-capture").apply {
            isDaemon = true
            start()
        }
    }

    fun stop() {
        stopped = true
        runCatching { audioRecord.stop() }
        captureThread?.join()
        captureThread = null
        releaseEncoder()
        runCatching {
            if (muxerStarted) muxer.stop()
        }
        runCatching { muxer.release() }
    }

    private fun captureLoop() {
        try {
            while (!stopped) {
                val read = audioRecord.read(captureBuffer, 0, captureBuffer.size)
                if (read > 0) {
                    queueInput(captureBuffer, read, totalFramesCaptured)
                    totalFramesCaptured += read / (channelCount * 2)
                    drainEncoder()
                    continue
                }
                if (read == AudioRecord.ERROR_INVALID_OPERATION || read == AudioRecord.ERROR_DEAD_OBJECT) {
                    break
                }
            }
            signalEndOfStream()
            drainEncoder(endOfStream = true)
        } finally {
            runCatching { audioRecord.release() }
        }
    }

    private fun queueInput(data: ByteArray, size: Int, frameIndex: Long) {
        val inputIndex = encoder.dequeueInputBuffer(10_000)
        if (inputIndex < 0) return
        val inputBuffer = encoder.getInputBuffer(inputIndex) ?: return
        inputBuffer.clear()
        inputBuffer.put(data, 0, size)
        val presentationTimeUs = frameIndex * 1_000_000L / sampleRate
        encoder.queueInputBuffer(inputIndex, 0, size, presentationTimeUs, 0)
    }

    private fun signalEndOfStream() {
        val inputIndex = encoder.dequeueInputBuffer(10_000)
        if (inputIndex < 0) return
        encoder.queueInputBuffer(
            inputIndex,
            0,
            0,
            totalFramesCaptured * 1_000_000L / sampleRate,
            MediaCodec.BUFFER_FLAG_END_OF_STREAM,
        )
    }

    private fun drainEncoder(endOfStream: Boolean = false) {
        while (true) {
            when (val outputIndex = encoder.dequeueOutputBuffer(bufferInfo, 10_000)) {
                MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (endOfStream) {
                        Thread.sleep(10)
                        continue
                    }
                    return
                }

                MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    if (muxerStarted) {
                        throw IllegalStateException("Audio muxer already started.")
                    }
                    encoderTrackIndex = muxer.addTrack(encoder.outputFormat)
                    muxer.start()
                    muxerStarted = true
                }

                MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED -> Unit

                else -> {
                    val outputBuffer = encoder.getOutputBuffer(outputIndex)
                        ?: throw IllegalStateException("Unable to read encoded audio.")
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                        bufferInfo.size = 0
                    }
                    if (bufferInfo.size > 0 && muxerStarted) {
                        outputBuffer.position(bufferInfo.offset)
                        outputBuffer.limit(bufferInfo.offset + bufferInfo.size)
                        muxer.writeSampleData(encoderTrackIndex, outputBuffer, bufferInfo)
                    }
                    encoder.releaseOutputBuffer(outputIndex, false)
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        return
                    }
                }
            }
        }
    }

    private fun releaseEncoder() {
        runCatching { encoder.stop() }
        runCatching { encoder.release() }
    }

    private fun createAudioRecord(projection: MediaProjection): AudioRecord {
        val format = AudioFormat.Builder()
            .setSampleRate(sampleRate)
            .setEncoding(pcmEncoding)
            .setChannelMask(channelMask)
            .build()
        val playbackConfig = AudioPlaybackCaptureConfiguration.Builder(projection)
            .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
            .addMatchingUsage(AudioAttributes.USAGE_GAME)
            .build()
        return AudioRecord.Builder()
            .setAudioFormat(format)
            .setBufferSizeInBytes(bufferSize)
            .setAudioPlaybackCaptureConfig(playbackConfig)
            .build()
            .also {
                if (it.state != AudioRecord.STATE_INITIALIZED) {
                    throw IllegalStateException("Unable to initialize audio recorder.")
                }
            }
    }
}

private fun muxVideoAndAudio(videoFile: File, audioFile: File, outputFile: File) {
    if (outputFile.exists()) outputFile.delete()
    val extractorMap = linkedMapOf(
        videoFile to "video/",
        audioFile to "audio/",
    )
    val muxer = MediaMuxer(outputFile.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
    val extractors = mutableListOf<MediaExtractor>()
    try {
        var videoTrackIndex = -1
        var audioTrackIndex = -1
        var videoOutputTrack = -1
        var audioOutputTrack = -1
        for ((file, mimePrefix) in extractorMap) {
            val extractor = MediaExtractor()
            extractor.setDataSource(file.absolutePath)
            extractors += extractor
            val trackIndex = findTrackIndex(extractor, mimePrefix)
            if (trackIndex < 0) continue
            extractor.selectTrack(trackIndex)
            val format = extractor.getTrackFormat(trackIndex)
            val muxTrackIndex = muxer.addTrack(format)
            if (mimePrefix == "video/") {
                videoTrackIndex = trackIndex
                videoOutputTrack = muxTrackIndex
            } else {
                audioTrackIndex = trackIndex
                audioOutputTrack = muxTrackIndex
            }
        }
        if (videoTrackIndex < 0 || videoOutputTrack < 0) {
            throw IllegalStateException("No video track found.")
        }
        muxer.start()
        val buffer = ByteBuffer.allocate(2 * 1024 * 1024)
        copyTrack(extractors[0], videoOutputTrack, buffer, muxer)
        if (audioTrackIndex >= 0 && audioOutputTrack >= 0) {
            buffer.clear()
            copyTrack(extractors[1], audioOutputTrack, buffer, muxer)
        }
    } finally {
        runCatching { muxer.stop() }
        runCatching { muxer.release() }
        extractors.forEach { runCatching { it.release() } }
    }
}

private fun copyTrack(
    extractor: MediaExtractor,
    outputTrackIndex: Int,
    buffer: ByteBuffer,
    muxer: MediaMuxer,
) {
    extractor.seekTo(0, MediaExtractor.SEEK_TO_CLOSEST_SYNC)
    while (true) {
        buffer.clear()
        val sampleSize = extractor.readSampleData(buffer, 0)
        if (sampleSize < 0) break
        val info = MediaCodec.BufferInfo().apply {
            size = sampleSize
            offset = 0
            presentationTimeUs = extractor.sampleTime
            flags = extractor.sampleFlags
        }
        muxer.writeSampleData(outputTrackIndex, buffer, info)
        if (!extractor.advance()) break
    }
}

private fun findTrackIndex(extractor: MediaExtractor, mimePrefix: String): Int {
    for (index in 0 until extractor.trackCount) {
        val mime = extractor.getTrackFormat(index).getString(MediaFormat.KEY_MIME) ?: continue
        if (mime.startsWith(mimePrefix)) return index
    }
    return -1
}

private fun moveFile(source: File, target: File) {
    if (target.exists()) target.delete()
    if (!source.renameTo(target)) {
        source.copyTo(target, overwrite = true)
        source.delete()
    }
}

private fun deleteQuietly(file: File) {
    if (file.exists()) file.delete()
}
