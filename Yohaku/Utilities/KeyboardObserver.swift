import Observation
import UIKit

@MainActor
@Observable
final class KeyboardObserver {
    private(set) var isVisible = false
    private var observers: [NSObjectProtocol] = []

    init(center: NotificationCenter = .default) {
        observers = [
            center.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.isVisible = true
                }
            },
            center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.isVisible = false
                }
            }
        ]
    }
}
