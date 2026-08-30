import 'package:carbon_ui/carbon_ui.dart';
import 'package:flutter/material.dart';

import 'database_manager.dart';

// The single checkpoint every inbound/outbound connection to another CWICare app goes
// through — per the user's explicit scope: "All connections inbound and outbound to
// the other apps (the emails, etc) are blocked" until this professional's credentials
// are verified (or their organization vouches for them). Call this at the top of
// whatever action would actually send or receive something (a discharge report, a
// questionnaire request, an EMS handoff import) — not at screen-open time, so a
// professional can still browse and prepare a report before hitting this wall.
class ProfessionalGate {
  static Future<bool> ensureVerified(BuildContext context) async {
    final profile = await DatabaseManager().getProfessionalProfile();
    if (profile != null && profile.verificationStatus.grantsFullAccess) return true;
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Verification Required"),
        content: const Text(
          "This connects to another CWICare app, which requires your professional credentials to be verified first. "
          "You can verify — or enter your organization's certification code — from your profile.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfessionalProfileScreen(
                    profile: profile ?? const ProfessionalProfile(name: '', clinicName: '', specialty: '', designation: ''),
                    onSave: (updated) => DatabaseManager().saveProfessionalProfile(updated),
                    onNewlyVerified: () => handleNewlyVerified(context),
                  ),
                ),
              );
            },
            child: const Text("Go to Profile"),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Shows CarbonPreparingAppScreen for exactly as long as the demo-data wipe actually
  // takes, then dismisses it — called the moment a professional's verification lands,
  // whether from a status check, an org code, or completing onboarding already
  // verified. Pushed on the root navigator so it covers everything regardless of which
  // screen triggered it, and survives that screen popping out from under it.
  static Future<void> handleNewlyVerified(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const CarbonPreparingAppScreen()));
    await DatabaseManager().wipeDemoDataForLicensedInstall();
    navigator.pop();
  }
}
