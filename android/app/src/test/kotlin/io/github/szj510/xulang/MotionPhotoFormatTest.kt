package io.github.szj510.xulang

import java.nio.charset.StandardCharsets
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class MotionPhotoFormatTest {
    @Test
    fun `buildXmp describes the appended MP4 length`() {
        val xmp = MotionPhotoFormat.buildXmp(123456L)

        assertTrue(xmp.contains("""Camera:MotionPhoto="1""""))
        assertTrue(xmp.contains("""Camera:MotionPhotoVersion="1""""))
        assertTrue(xmp.contains("""Item:Semantic="Primary""""))
        assertTrue(xmp.contains("""Item:Semantic="MotionPhoto""""))
        assertTrue(xmp.contains("""Item:Length="123456""""))
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
    fun `display name follows the Android motion photo naming convention`() {
        val name = MotionPhotoFormat.buildDisplayName(
            title = "测试 / Exhibition",
            nowMillis = 0L,
        )

        assertTrue(name.startsWith("xulang-测试_Exhibition-"))
        assertTrue(name.endsWith("_MP.jpg"))
        assertTrue('/' !in name)
    }
}
