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
}
