package app.template.patches.wallverse.premium

import app.morphe.patcher.extensions.InstructionExtensions.addInstruction
import app.morphe.patcher.extensions.InstructionExtensions.addInstructions
import app.morphe.patcher.extensions.InstructionExtensions.addInstructionsWithLabels
import app.morphe.patcher.extensions.InstructionExtensions.getInstruction
import app.morphe.patcher.extensions.InstructionExtensions.removeInstruction
import app.morphe.patcher.patch.bytecodePatch
import app.template.patches.shared.Constants.WALLVERSE_COMPATIBILITY
import com.android.tools.smali.dexlib2.iface.instruction.formats.Instruction35c

@Suppress("unused")
val wallverseUnlockPremiumPatch = bytecodePatch(
    name = "Unlock Premium",
    description = "Unlocks lifetime Premium in Wallverse.",
    default = true,
) {
    compatibleWith(WALLVERSE_COMPATIBILITY)

    execute {
        // Application.attachBaseContext calls this before WallverseApp starts.
        // Returning immediately preserves the original application initialization.
        PairipCheckLicenseFingerprint.method.addInstructions(0, "return-void")

        // Force the isPremium boolean to true immediately before Boolean.valueOf(Z).
        // The insertion sequence preserves incoming control-flow labels.
        val method = WallverseIsPremiumFingerprint.method
        val callIndex = WallverseIsPremiumFingerprint.instructionMatches[1].index
        val reg = method.getInstruction<Instruction35c>(callIndex).registerC

        method.addInstruction(callIndex + 1, method.getInstruction(callIndex))
        method.addInstructionsWithLabels(callIndex + 1, "const/4 v$reg, 0x1")
        method.removeInstruction(callIndex)
    }
}
