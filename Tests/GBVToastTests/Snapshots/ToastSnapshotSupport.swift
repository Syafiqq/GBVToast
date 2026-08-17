#if canImport(SwiftUI) && canImport(UIKit)
  import SwiftUI
  import UIKit
  @testable import GBVToast

  @MainActor
  enum ToastSnapshotSupport {
    static let phone = ToastParityFixture.Device.phone

    static func swiftUI(
      _ configuration: ToastConfiguration,
      device: ToastParityFixture.Device = phone,
      dynamicTypeSize: DynamicTypeSize = .large,
      layoutDirection: LayoutDirection = .leftToRight
    ) -> UIView {
      let toast = swiftUIToast(
        configuration,
        device: device,
        dynamicTypeSize: dynamicTypeSize,
        layoutDirection: layoutDirection
      )
      return fullPage(toast, configuration: configuration, device: device)
    }

    static func swiftUIToast(
      _ configuration: ToastConfiguration,
      device: ToastParityFixture.Device = phone,
      dynamicTypeSize: DynamicTypeSize = .large,
      layoutDirection: LayoutDirection = .leftToRight
    ) -> UIView {
      let width = snapshotMaximumWidth(configuration, device: device)
      let controller = UIHostingController(
        rootView: ToastContentView(
          configuration: configuration,
          root: GeniebookToastReferencePreset.configuration,
          onDismiss: {},
          onCTA: {}
        )
        .environment(\.dynamicTypeSize, dynamicTypeSize)
        .environment(\.layoutDirection, layoutDirection)
        .frame(maxWidth: width)
      )
      controller.view.backgroundColor = .clear
      return fitted(controller.view, contentWidth: width)
    }

    static func swiftUIWidth(
      _ configuration: ToastConfiguration,
      device: ToastParityFixture.Device,
      layoutDirection: LayoutDirection = .leftToRight
    ) -> UIView {
      let maximumAvailableWidth = device.size.width - (ToastWidth.horizontalMargin * 2)
      let content = ToastContentView(
        configuration: configuration,
        root: GeniebookToastReferencePreset.configuration,
        onDismiss: {}
      )
        .environment(\.layoutDirection, layoutDirection)
      let measurementController = UIHostingController(rootView: content)
      let intrinsicSize = measurementController.sizeThatFits(in: CGSize(
        width: maximumAvailableWidth,
        height: .greatestFiniteMagnitude
      ))
      let width = configuration.width == .full
        ? min(maximumAvailableWidth, ToastWidth.fullMaximum)
        : min(ceil(intrinsicSize.width), maximumAvailableWidth)
      let renderController = UIHostingController(rootView: content.frame(width: width))
      renderController.view.backgroundColor = .clear
      let toast = fitted(renderController.view, contentWidth: width)
      return fullPageFitted(toast, configuration: configuration, device: device)
    }

    static func legacyImageCTA(_ configuration: ToastConfiguration) -> UIView {
      let cta = configuration.cta ?? ToastCTA(title: "")
      let controller = UIHostingController(rootView: ToastLegacyResponsiveLayout(
        message: configuration.message,
        cta: cta,
        font: .body,
        foregroundStyle: .white,
        onCTA: {}
      )
      .padding(16)
      .background(Color.black))
      controller.view.backgroundColor = .clear
      return fitted(controller.view, contentWidth: 358)
    }

    private static func fullPageFitted(
      _ toast: UIView,
      configuration: ToastConfiguration,
      device: ToastParityFixture.Device
    ) -> UIView {
      let canvas = UIView(frame: CGRect(origin: .zero, size: device.size))
      canvas.backgroundColor = UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1)
      let originY = configuration.edge == .top
        ? device.safeAreaTop + configuration.safeAreaSpacing
        : device.size.height - device.safeAreaBottom - configuration.safeAreaSpacing
          - toast.bounds.height
      toast.frame.origin = CGPoint(
        x: (device.size.width - toast.bounds.width) / 2,
        y: originY
      )
      canvas.addSubview(toast)
      canvas.layoutIfNeeded()
      return canvas
    }

    private static func fullPage(
      _ toast: UIView,
      configuration: ToastConfiguration,
      device: ToastParityFixture.Device
    ) -> UIView {
      let canvas = UIView(frame: CGRect(origin: .zero, size: device.size))
      canvas.backgroundColor = UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1)
      let width = snapshotMaximumWidth(configuration, device: device)
      let fittedToast = fitted(toast, contentWidth: width)
      let originY = configuration.edge == .top
        ? device.safeAreaTop + configuration.safeAreaSpacing
        : device.size.height - device.safeAreaBottom - configuration.safeAreaSpacing
          - fittedToast.bounds.height
      fittedToast.frame.origin = CGPoint(
        x: (device.size.width - fittedToast.bounds.width) / 2,
        y: originY
      )
      canvas.addSubview(fittedToast)
      canvas.layoutIfNeeded()
      return canvas
    }

    private static func fitted(_ view: UIView, contentWidth width: CGFloat) -> UIView {
      view.translatesAutoresizingMaskIntoConstraints = true
      view.frame = CGRect(x: 0, y: 0, width: width, height: 1)
      let height = view.systemLayoutSizeFitting(
        CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
        withHorizontalFittingPriority: .required,
        verticalFittingPriority: .fittingSizeLevel
      ).height
      view.frame = CGRect(x: 0, y: 0, width: width, height: ceil(height))
      view.setNeedsLayout()
      view.layoutIfNeeded()
      return view
    }

    private static func snapshotMaximumWidth(
      _ configuration: ToastConfiguration,
      device: ToastParityFixture.Device
    ) -> CGFloat {
      let configured = device == .pad
        ? configuration.maximumPadWidth
        : configuration.maximumPhoneWidth
      return min(device.size.width - 32, configured ?? .greatestFiniteMagnitude)
    }
  }

#endif
