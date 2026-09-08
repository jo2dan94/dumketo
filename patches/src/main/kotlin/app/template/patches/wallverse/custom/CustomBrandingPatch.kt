package app.template.patches.wallverse.custom

import app.morphe.patcher.patch.booleanOption
import app.morphe.patcher.patch.resourcePatch
import app.morphe.patcher.patch.stringOption
import app.template.patches.shared.Constants.WALLVERSE_COMPATIBILITY

/**
 * Current-API port of the legacy class-style CustomBrandingPatch.
 *
 * The upstream implementation is only a placeholder and does not actually modify
 * Android resources. This port intentionally preserves that behavior rather than
 * inventing patch logic that was not present upstream.
 */
@Suppress("unused")
val wallverseCustomBrandingPatch = resourcePatch(
    name = "Custom Branding",
    description = "Customize the app name and icon for Wallverse.",
    default = false,
) {
    compatibleWith(WALLVERSE_COMPATIBILITY)

    val customAppName by stringOption(
        key = "customAppName",
        title = "Custom app name",
        description = "Set a custom name for the app",
        default = "Wallverse Pro",
        required = false,
    )

    val customIcon by booleanOption(
        key = "customIcon",
        title = "Custom icon",
        description = "Enable custom app icon",
        default = false,
        required = false,
    )

    // No execute block: the original source contained only TODO/placeholder operations.
}
