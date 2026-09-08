package app.template.patches.shared

import app.morphe.patcher.patch.ApkFileType
import app.morphe.patcher.patch.AppTarget
import app.morphe.patcher.patch.Compatibility

object Constants {
    val WALLVERSE_COMPATIBILITY = Compatibility(
        name = "Wallverse",
        packageName = "com.wallverse.wallpapers",
        apkFileType = ApkFileType.XAPK,
        targets = listOf(
            AppTarget(version = "4.2")
        )
    )

    val ACCUBATTERY_COMPATIBILITY = Compatibility(
        name = "AccuBattery",
        packageName = "com.digibites.accubattery",
        apkFileType = ApkFileType.APK,
        targets = listOf(
            AppTarget(version = "2.1.8")
        )
    )

    val ADGUARD_COMPATIBILITY = Compatibility(
        name = "AdGuard",
        packageName = "com.adguard.android",
        apkFileType = ApkFileType.APK,
        targets = listOf(
            AppTarget(version = "4.14.68")
        )
    )

    val ADOBE_ACROBAT_COMPATIBILITY = Compatibility(
        name = "Adobe Acrobat",
        packageName = "com.adobe.reader",
        apkFileType = ApkFileType.XAPK,
        targets = listOf(
            AppTarget(version = "26.7.0.47169")
        )
    )
}
