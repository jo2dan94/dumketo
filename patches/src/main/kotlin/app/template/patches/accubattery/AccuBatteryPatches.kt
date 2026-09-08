package app.template.patches.accubattery

import app.morphe.patcher.patch.bytecodePatch
import app.template.patches.shared.Constants.ACCUBATTERY_COMPATIBILITY

@Suppress("unused")
val accubatteryUnlockProPatch = bytecodePatch(
    name = "Unlock Pro Features",
    description = "Unlocks Pro features like detailed battery stats and widget customization in AccuBattery.",
    default = true,
) {
    compatibleWith(ACCUBATTERY_COMPATIBILITY)

    execute {
        // Upstream source contains only placeholder logic here.
    }
}

@Suppress("unused")
val accubatteryRemoveAdsPatch = bytecodePatch(
    name = "Remove Ads",
    description = "Removes all advertisements from AccuBattery.",
    default = true,
) {
    compatibleWith(ACCUBATTERY_COMPATIBILITY)

    execute {
        // Upstream source contains only placeholder logic here.
    }
}
