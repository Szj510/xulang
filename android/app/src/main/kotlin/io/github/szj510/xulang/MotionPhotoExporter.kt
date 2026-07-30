package io.github.szj510.xulang

import android.content.ClipData
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.charset.StandardCharsets

data class SavedMotionPhoto(
    val uri: Uri,
    val displayName: String,
    val sizeBytes: Long,
)

class MotionPhotoExporter(private val context: Context) {
    fun create(videoFile: File, title: String): SavedMotionPhoto {
        require(videoFile.isFile && videoFile.length() > 0L) {
            "The recorded MP4 file is missing or empty."
        }

        val stillJpeg = extractMiddleFrame(videoFile)
        val videoLength = videoFile.length()
        val xmp = MotionPhotoFormat.buildXmp(videoLength)
        val jpegWithXmp = MotionPhotoFormat.insertXmp(stillJpeg, xmp)
        val displayName = MotionPhotoFormat.buildDisplayName(title)
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
            put(
                MediaStore.Images.Media.RELATIVE_PATH,
                "${Environment.DIRECTORY_PICTURES}/Xulang",
            )
            put(MediaStore.Images.Media.DATE_TAKEN, System.currentTimeMillis())
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val uri = context.contentResolver.insert(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            values,
        ) ?: throw IllegalStateException("Unable to create a system gallery entry.")

        try {
            context.contentResolver.openOutputStream(uri, "w").use { output ->
                val target = output ?: throw IllegalStateException(
                    "Unable to write the motion photo.",
                )
                target.write(jpegWithXmp)
                videoFile.inputStream().use { input -> input.copyTo(target) }
            }
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            check(context.contentResolver.update(uri, values, null, null) == 1) {
                "Unable to publish the motion photo to the system gallery."
            }
            return SavedMotionPhoto(
                uri = uri,
                displayName = displayName,
                sizeBytes = jpegWithXmp.size.toLong() + videoLength,
            )
        } catch (error: Throwable) {
            context.contentResolver.delete(uri, null, null)
            throw error
        }
    }

    fun share(uri: Uri, title: String) {
        require(uri.scheme == "content") { "Only a saved media URI can be shared." }
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/jpeg"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, title)
            clipData = ClipData.newUri(context.contentResolver, title, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        context.startActivity(
            Intent.createChooser(intent, title).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    private fun extractMiddleFrame(videoFile: File): ByteArray {
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(videoFile.absolutePath)
            val durationMs = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_DURATION,
            )?.toLongOrNull()?.coerceAtLeast(1L) ?: 1L
            val middleUs = durationMs * 500L
            val bitmap = retriever.getFrameAtTime(
                middleUs,
                MediaMetadataRetriever.OPTION_CLOSEST,
            ) ?: throw IllegalStateException("Unable to extract the motion photo cover.")
            return bitmap.useAsJpeg()
        } finally {
            retriever.release()
        }
    }

    private fun Bitmap.useAsJpeg(): ByteArray {
        try {
            return ByteArrayOutputStream().use { output ->
                check(compress(Bitmap.CompressFormat.JPEG, 94, output)) {
                    "Unable to encode the motion photo cover."
                }
                output.toByteArray()
            }
        } finally {
            recycle()
        }
    }
}

/**
 * JPEG Motion Photo 1.0 container writer.
 *
 * Specification:
 * https://developer.android.com/media/platform/motion-photo-format
 */
object MotionPhotoFormat {
    private val xmpHeader = "http://ns.adobe.com/xap/1.0/\u0000"
        .toByteArray(StandardCharsets.US_ASCII)

    fun buildXmp(videoLength: Long): String {
        require(videoLength > 0L) { "Motion photo video must not be empty." }
        return """
            <x:xmpmeta xmlns:x="adobe:ns:meta/">
              <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                <rdf:Description
                    rdf:about=""
                    xmlns:Camera="http://ns.google.com/photos/1.0/camera/"
                    xmlns:Container="http://ns.google.com/photos/1.0/container/"
                    xmlns:Item="http://ns.google.com/photos/1.0/container/item/"
                    Camera:MotionPhoto="1"
                    Camera:MotionPhotoVersion="1">
                  <Container:Directory>
                    <rdf:Seq>
                      <rdf:li rdf:parseType="Resource">
                        <Container:Item
                            Item:Mime="image/jpeg"
                            Item:Semantic="Primary"/>
                      </rdf:li>
                      <rdf:li rdf:parseType="Resource">
                        <Container:Item
                            Item:Mime="video/mp4"
                            Item:Semantic="MotionPhoto"
                            Item:Length="$videoLength"/>
                      </rdf:li>
                    </rdf:Seq>
                  </Container:Directory>
                </rdf:Description>
              </rdf:RDF>
            </x:xmpmeta>
        """.trimIndent()
    }

    fun insertXmp(jpeg: ByteArray, xmp: String): ByteArray {
        require(jpeg.size >= 4 && jpeg[0] == 0xff.toByte() && jpeg[1] == 0xd8.toByte()) {
            "Motion photo cover is not a JPEG image."
        }
        val payload = xmpHeader + xmp.toByteArray(StandardCharsets.UTF_8)
        val segmentLength = payload.size + 2
        require(segmentLength <= 0xffff) { "Motion photo XMP packet is too large." }
        return ByteArrayOutputStream(jpeg.size + payload.size + 4).use { output ->
            output.write(jpeg, 0, 2)
            output.write(0xff)
            output.write(0xe1)
            output.write((segmentLength ushr 8) and 0xff)
            output.write(segmentLength and 0xff)
            output.write(payload)
            output.write(jpeg, 2, jpeg.size - 2)
            output.toByteArray()
        }
    }

    fun buildDisplayName(title: String, nowMillis: Long = System.currentTimeMillis()): String {
        val safeTitle = title
            .trim()
            .replace(Regex("""[\\/:*?"<>|\p{Cntrl}]+"""), "_")
            .replace(Regex("""\s+"""), "_")
            .replace(Regex("""_+"""), "_")
            .trim('_')
            .ifEmpty { "motion" }
            .take(64)
        val timestamp = java.text.SimpleDateFormat(
            "yyyyMMdd-HHmmss",
            java.util.Locale.ROOT,
        ).format(java.util.Date(nowMillis))
        return "xulang-${safeTitle}-${timestamp}_MP.jpg"
    }
}
