package io.github.szj510.xulang

import java.nio.charset.StandardCharsets
import javax.xml.parsers.DocumentBuilderFactory
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class MotionPhotoFormatTest {
    @Test
    fun `buildXmp describes current and legacy motion photo metadata`() {
        val xmp = MotionPhotoFormat.buildXmp(
            videoLength = 123456L,
            presentationTimestampUs = 654321L,
        )

        assertTrue(xmp.startsWith("""<?xpacket begin=""""))
        assertTrue(xmp.contains("""Camera:MotionPhoto="1""""))
        assertTrue(xmp.contains("""Camera:MotionPhotoVersion="1""""))
        assertTrue(
            xmp.contains("""Camera:MotionPhotoPresentationTimestampUs="654321""""),
        )
        assertTrue(xmp.contains("""GCamera:MicroVideo="1""""))
        assertTrue(xmp.contains("""GCamera:MicroVideoVersion="1""""))
        assertTrue(xmp.contains("""GCamera:MicroVideoOffset="123456""""))
        assertTrue(
            xmp.contains("""GCamera:MicroVideoPresentationTimestampUs="654321""""),
        )
        assertTrue(xmp.contains("""GContainerItem:Semantic="Primary""""))
        assertTrue(xmp.contains("""GContainerItem:Semantic="MotionPhoto""""))
        assertTrue(xmp.contains("""GContainerItem:Length="123456""""))
        assertTrue(xmp.endsWith("""<?xpacket end="w"?>"""))

        val document = DocumentBuilderFactory.newInstance().apply {
            isNamespaceAware = true
        }.newDocumentBuilder().parse(xmp.byteInputStream())
        assertEquals("xmpmeta", document.documentElement.localName)
    }

    @Test
    fun `insertXmp writes an APP1 packet and preserves JPEG bytes`() {
        val jpeg = byteArrayOf(
            0xff.toByte(),
            0xd8.toByte(),
            0xff.toByte(),
            0xd9.toByte(),
        )
        val result = MotionPhotoFormat.insertXmp(jpeg, "<x:xmpmeta/>")
        val header = "http://ns.adobe.com/xap/1.0/\u0000"
            .toByteArray(StandardCharsets.US_ASCII)

        assertEquals(0xff.toByte(), result[0])
        assertEquals(0xd8.toByte(), result[1])
        assertEquals(0xff.toByte(), result[2])
        assertEquals(0xe1.toByte(), result[3])
        assertArrayEquals(header, result.copyOfRange(6, 6 + header.size))
        assertArrayEquals(
            jpeg.copyOfRange(2, jpeg.size),
            result.copyOfRange(result.size - 2, result.size),
        )
    }

    @Test
    fun `insertXmp keeps JFIF and Exif segments before XMP`() {
        val app0 = jpegSegment(
            marker = 0xe0,
            payload = "JFIF\u0000".toByteArray(StandardCharsets.US_ASCII),
        )
        val exif = jpegSegment(
            marker = 0xe1,
            payload = "Exif\u0000\u0000data".toByteArray(StandardCharsets.US_ASCII),
        )
        val jpeg = byteArrayOf(0xff.toByte(), 0xd8.toByte()) +
            app0 +
            exif +
            byteArrayOf(0xff.toByte(), 0xd9.toByte())

        val result = MotionPhotoFormat.insertXmp(jpeg, "<x:xmpmeta/>")
        val expectedPrefix = byteArrayOf(0xff.toByte(), 0xd8.toByte()) + app0 + exif

        assertArrayEquals(
            expectedPrefix,
            result.copyOfRange(0, expectedPrefix.size),
        )
        assertEquals(0xff.toByte(), result[expectedPrefix.size])
        assertEquals(0xe1.toByte(), result[expectedPrefix.size + 1])
    }

    @Test
    fun `display name follows the Android motion photo naming convention`() {
        val name = MotionPhotoFormat.buildDisplayName(
            title = "测试 / Exhibition",
            nowMillis = 0L,
        )

        assertTrue(name.startsWith("xulang-测试_Exhibition-"))
        assertTrue(name.endsWith("_MP.jpg"))
        assertTrue('/' !in name)
    }

    private fun jpegSegment(marker: Int, payload: ByteArray): ByteArray {
        val length = payload.size + 2
        return byteArrayOf(
            0xff.toByte(),
            marker.toByte(),
            (length ushr 8).toByte(),
            length.toByte(),
        ) + payload
    }
}
