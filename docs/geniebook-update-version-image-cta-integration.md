# Geniebook update-version image CTA integration

Use this checklist only after the GBVToast image CTA release passes its package and snapshot gates.

1. Publish a new semantic version. Do not move the existing `1.0.1` tag.
2. Confirm the generated Geniebook asset name for the App Store artwork; the handoff's `ic_appstore_100` spelling records intent, not generator output.
3. Update Geniebook's exact package pin and resolved revision together.
4. Replace `APIClient.showUpdateAvailableNotifier(newVersion:)` with a bottom, full-width GBVToast configuration using:
   - `.normal` style;
   - hidden leading icon;
   - inline original-rendered image CTA;
   - 15-point safe-area spacing;
   - two-second auto-dismissal;
   - `geniebook.update-version` deduplication key.
5. Await the presentation token and open `itms-apps://itunes.apple.com/us/app/geniebook/id905900825` only when the result is `.cta`.
6. Add the update-version occurrence to Geniebook's UI snapshot inventory.
7. Verify the authored asset, VoiceOver label, 44×44 interaction target, App Store deep link, background-touch pass-through, replacement behavior, and two-second dismissal in the app.
8. Search Geniebook for every `SnackBar` reference. Delete the component only when no caller remains.
