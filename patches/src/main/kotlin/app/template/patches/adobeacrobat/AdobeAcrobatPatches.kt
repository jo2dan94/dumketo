package app.template.patches.adobeacrobat

import app.morphe.patcher.patch.bytecodePatch
import app.template.patches.shared.Constants.ADOBE_ACROBAT_COMPATIBILITY

@Suppress("unused")
val adobeUnlockProToolsPatch = bytecodePatch(
    name = "Unlock Pro Tools",
    description = "Unlocks premium editing and conversion tools in Adobe Acrobat.",
    default = true,
) {
    compatibleWith(ADOBE_ACROBAT_COMPATIBILITY)

    execute {
        // Upstream source contains only placeholder logic here.
    }
}

@Suppress("unused")
val adobeRemoveWatermarksPatch = bytecodePatch(
    name = "Remove Watermarks",
    description = "Removes trial watermarks from documents in Adobe Acrobat.",
    default = true,
) {
    compatibleWith(ADOBE_ACROBAT_COMPATIBILITY)

    execute {
        // Upstream source contains only placeholder logic here.
    }
}
