package app.template.patches.adguard

import app.morphe.patcher.patch.bytecodePatch
import app.template.patches.shared.Constants.ADGUARD_COMPATIBILITY

@Suppress("unused")
val adguardPremiumLicensePatch = bytecodePatch(
    name = "Premium License",
    description = "Activates premium license features in AdGuard.",
    default = true,
) {
    compatibleWith(ADGUARD_COMPATIBILITY)

    execute {
        // Upstream source contains only placeholder logic here.
    }
}

@Suppress("unused")
val adguardCustomDnsPatch = bytecodePatch(
    name = "Custom DNS",
    description = "Adds custom DNS server options to AdGuard.",
    default = false,
) {
    compatibleWith(ADGUARD_COMPATIBILITY)

    execute {
        // Upstream source contains only placeholder logic here.
    }
}
