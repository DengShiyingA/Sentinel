import SwiftUI
import AVFoundation

/// AVFoundation camera QR scanner.
/// Detects `sentinel://` and `sentinel-remote://` deep links and fires `onCodeScanned` callback.
struct QRScannerView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onCodeScanned = onCodeScanned
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false
    private var timeoutTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkCameraPermission()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
        // Auto-timeout after 2 minutes to save battery
        timeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(120))
            guard let self, !self.hasScanned else { return }
            self.captureSession.stopRunning()
            self.showTimeoutLabel()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timeoutTask?.cancel()
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.setupCamera() }
                    else { self?.showPermissionDeniedLabel() }
                }
            }
        case .denied, .restricted:
            showPermissionDeniedLabel()
        @unknown default:
            setupCamera()
        }
    }

    private func showPermissionDeniedLabel() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = String(localized: "需要相机权限来扫描二维码")
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0

        let button = UIButton(type: .system)
        button.setTitle(String(localized: "前往设置"), for: .normal)
        button.addAction(UIAction { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }, for: .touchUpInside)

        stack.addArrangedSubview(label)
        stack.addArrangedSubview(button)
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
        ])
    }

    private func showTimeoutLabel() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = String(localized: "扫描超时，请重试")
        label.textColor = .white
        label.textAlignment = .center

        let button = UIButton(type: .system)
        button.setTitle(String(localized: "重新扫描"), for: .normal)
        button.addAction(UIAction { [weak self] _ in
            stack.removeFromSuperview()
            self?.hasScanned = false
            DispatchQueue.global(qos: .userInitiated).async {
                self?.captureSession.startRunning()
            }
        }, for: .touchUpInside)

        stack.addArrangedSubview(label)
        stack.addArrangedSubview(button)
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            showNoCameraLabel()
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        let output = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
        }

        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview

        // Overlay: scan frame indicator
        addScanOverlay()
    }

    private func addScanOverlay() {
        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.layer.borderColor = UIColor.systemBlue.cgColor
        overlay.layer.borderWidth = 2
        overlay.layer.cornerRadius = 12
        overlay.backgroundColor = .clear
        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            overlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            overlay.widthAnchor.constraint(equalToConstant: 250),
            overlay.heightAnchor.constraint(equalToConstant: 250),
        ])
    }

    private func showNoCameraLabel() {
        let label = UILabel()
        label.text = String(localized: "无法访问相机")
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasScanned,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue,
              value.hasPrefix("sentinel://") || value.hasPrefix("sentinel-remote://") else {
            return
        }

        hasScanned = true
        captureSession.stopRunning()

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        onCodeScanned?(value)
    }
}
