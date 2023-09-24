import Combine
import UIKit

final class MagicNumberViewController: UIViewController {

    // MARK: - Properties

    private lazy var randomNum: Int? = nil
    private lazy var elapsedTime = 0.0
    private lazy var timerSubscriber: AnyCancellable? = nil
    private lazy var textViewSubscriber: AnyCancellable? = nil

    // MARK: - Enums

    enum HintLabelState {
        case initial, win, tooSmall, tooBig

        var text: String {
            switch self {
            case .initial:
                return "Try to guess the magic number\nFrom 1 to 100"
            case .win:
                return "You win! Tap the replay button to play again!"
            case .tooSmall:
                return "Try to set a bigger number"
            case .tooBig:
                return "Try to set a smaller number"
            }
        }

        var color: UIColor {
            switch self {
            case .initial:
                return .black
            case .win:
                return .green
            case .tooSmall, .tooBig:
                return .red
            }
        }
    }

    // MARK: - UI Elements

    private lazy var timeToWinLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont(name: "IndieFlower", size: 35)
        label.textAlignment = .center
        label.contentMode = .center
        return label
    }()

    private lazy var hintLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "IndieFlower", size: 25)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.contentMode = .center
        return label
    }()

    private lazy var answerTextView: UITextView = {
        let textView = UITextView()
        textView.font = .boldSystemFont(ofSize: 50)
        textView.layer.borderWidth = 2.0
        textView.textContainer.maximumNumberOfLines = 1
        textView.textAlignment = .center
        textView.contentMode = .bottom
        textView.keyboardType = .numberPad
        return textView
    }()

    private lazy var restartButton: UIButton = {
        let button = UIButton()
        let buttonImage = UIImage(systemName: "goforward")
        button.setBackgroundImage(buttonImage, for: .normal)
        button.tintColor = .lightGray
        button.titleLabel?.font = .systemFont(ofSize: 50, weight: .ultraLight)
        button.addTarget(self, action: #selector(replayButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
        setSubviews()
        setInitialValues()
        updateTimerLabel()
        setCurrentHint(currentValue: .initial)
        makeTimerPublisher()
        makeTextViewPublisher()
    }

    // MARK: - Setting subviews

    private func addSubviews() {
        [timeToWinLabel, hintLabel, answerTextView, restartButton].forEach { subview in
            view.addSubview(subview)
            subview.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private func setSubviews() {
        NSLayoutConstraint.activate([
            timeToWinLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 90.0),
            timeToWinLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50.0),
            timeToWinLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50.0),

            hintLabel.topAnchor.constraint(equalTo: timeToWinLabel.bottomAnchor, constant: 40),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            hintLabel.heightAnchor.constraint(equalToConstant: 85),

            answerTextView.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 40),
            answerTextView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            answerTextView.leadingAnchor.constraint(equalTo: timeToWinLabel.leadingAnchor),
            answerTextView.trailingAnchor.constraint(equalTo: timeToWinLabel.trailingAnchor),
            answerTextView.heightAnchor.constraint(equalTo: hintLabel.heightAnchor),

            restartButton.topAnchor.constraint(equalTo: answerTextView.bottomAnchor, constant: 50),
            restartButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            restartButton.heightAnchor.constraint(equalToConstant: 80.0),
            restartButton.widthAnchor.constraint(equalTo: restartButton.heightAnchor)
        ])
    }

    // MARK: - Actions

    /// It helps hide the keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let _ = touches.first {
            view.endEditing(true)
        }
        super.touchesBegan(touches, with: event)
    }

    @objc private func replayButtonTapped() {
        setInitialValues()
        makeTextViewPublisher()
        makeTimerPublisher()
    }

    private func setCurrentHint(currentValue: HintLabelState) {
        hintLabel.text = currentValue.text
        hintLabel.textColor = currentValue.color
    }

    private func updateTimerLabel() {
        let timeString = String(format: "Seconds remains:\n%.0f ", elapsedTime)
        timeToWinLabel.text = timeString
    }

    private func setInitialValues() {
        randomNum = Int.random(in: 1...100)
        elapsedTime = 0.0
        answerTextView.text = ""
        setCurrentHint(currentValue: .initial)
    }

    // MARK: - Publishers

    private func makeTextViewPublisher() {
        textViewSubscriber = NotificationCenter.default
            .publisher(for: UITextView.textDidChangeNotification,
                       object: answerTextView)
            .compactMap { $0.object as? UITextView }
            .compactMap { $0.text }
            .sink(
                receiveValue: { [weak self] value in
                    guard let self = self,
                    let randomNum = randomNum else { return }

                    if let userNum = Int(value) {
                        if userNum == randomNum {
                            self.setCurrentHint(currentValue: .win)
                            self.timerSubscriber?.cancel()
                            self.textViewSubscriber?.cancel()
                        } else if userNum < randomNum {
                            self.setCurrentHint(currentValue: .tooSmall)
                        } else if userNum > randomNum {
                            self.setCurrentHint(currentValue: .tooBig)
                        }
                    } else {
                        self.setCurrentHint(currentValue: .initial)
                    }
                })
    }

    private func makeTimerPublisher() {
        timerSubscriber = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }

                self.elapsedTime += 1
                self.updateTimerLabel()

            }
    }
}

