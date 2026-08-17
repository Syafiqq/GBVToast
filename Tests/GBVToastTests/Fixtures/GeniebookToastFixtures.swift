import Foundation

@testable import GBVToast

enum GeniebookToastFixtures {
  // GenieAsk/PresentationLayer/UIKit/Controller/ChatPage/GAChatPageViewController.swift:631
  static let modeSwitch = ToastConfiguration(
    message: "Your question has been sent to your teacher and they will get back to you at the earliest",
    style: .info,
    cta: ToastCTA(title: "Close", layout: .inline),
    autoDismissDuration: nil
  )

  static let modeSwitchDedicated = ToastConfiguration(
    message: "Your question has been sent to your teacher and they will get back to you at the earliest",
    style: .info,
    cta: ToastCTA(title: "Close", layout: .dedicated),
    autoDismissDuration: nil
  )

  // Geniebook/PresentationLayer/UIKit/Controller/WorkingSpace/V1WorkingSpaceViewController.swift:1842
  static let tenMinuteReminder = ToastConfiguration(
    message: "Reminder that you only have 10 minutes remaining",
    style: .warning,
    cta: ToastCTA(title: "Dismiss"),
    autoDismissDuration: nil
  )

  // Geniebook/PresentationLayer/UIKit/Controller/V3GenieClass/V3GenieClassUpcomingViewController.swift:511
  static let reminderUndo = ToastConfiguration(
    message: "Reminder has been removed.",
    style: .info,
    cta: ToastCTA(title: "Undo"),
    autoDismissDuration: nil
  )

  static let hiddenIcon = ToastConfiguration(
    message: "Unable to load your worksheet. Please try again.",
    style: .danger,
    icon: .hidden,
    autoDismissDuration: nil,
    isAnimated: false
  )

  static let syntheticBottom = ToastConfiguration(
    message: "Saved",
    style: .info,
    edge: .bottom,
    autoDismissDuration: nil
  )

  static let updateVersionImageCTA = ToastConfiguration(
    message: "A newer version of Geniebook (4.2.0) is available. Update now for the latest improvements.",
    width: .full,
    style: .normal,
    edge: .bottom,
    icon: .hidden,
    cta: ToastCTA(
      label: .asset(
        name: "UpdateVersionAppStore",
        bundleIdentifier: Bundle.module.bundleIdentifier,
        renderingMode: .original,
        accessibilityLabel: "Open App Store"
      ),
      layout: .inline
    ),
    autoDismissDuration: 2,
    isAnimated: false,
    safeAreaSpacing: 15,
    deduplicationKey: "geniebook.update-version"
  )

  static let updateVersionLongMessage = ToastConfiguration(
    message: "A newer version of Geniebook (4.2.0) is available with important learning improvements and reliability fixes. Update now to continue.",
    width: .full,
    style: .normal,
    edge: .bottom,
    icon: .hidden,
    cta: updateVersionImageCTA.cta,
    autoDismissDuration: nil,
    isAnimated: false,
    safeAreaSpacing: 15
  )

  static let all = [
    modeSwitch,
    modeSwitchDedicated,
    tenMinuteReminder,
    reminderUndo,
    hiddenIcon,
    syntheticBottom,
    updateVersionImageCTA,
  ]
}
