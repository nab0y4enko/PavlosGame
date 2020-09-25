//
//  ViewController.swift
//  PavlosGame
//
//  Created by Oleksii Naboichenko on 08.02.2020.
//  Copyright © 2020 Oleksii Naboichenko. All rights reserved.
//

import UIKit
import AVFoundation
import QRCodeReader
import PMAlertController

class ViewController: UIViewController {

    @IBOutlet private weak var questionAndAnswerStackView: UIStackView!

    @IBOutlet private weak var questionLabel: UILabel!
    @IBOutlet private weak var answerTextField: UITextField!
    @IBOutlet private weak var answerButton: UIButton! {
        didSet {
            answerButton.layer.cornerRadius = 10
        }
    }
    
    @IBOutlet private weak var scanQRButton: UIButton! {
        didSet {
            scanQRButton.layer.cornerRadius = 10
        }
    }

    private let speechSynthesizer = AVSpeechSynthesizer()
    
    lazy var qrReaderViewController: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)

            // Configure the view controller (optional)
            $0.showTorchButton = false
            $0.showSwitchCameraButton = false
            $0.showCancelButton = true
            $0.showOverlayView = true
            $0.rectOfInterest = CGRect(x: 0.2, y: 0.3, width: 0.6, height: 0.35)
        }

        let qrReaderViewController = QRCodeReaderViewController(builder: builder)
        qrReaderViewController.delegate = self
        return qrReaderViewController
    }()
    
    // MARK: - Deinitializer
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateViews), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateViews()
    }
    
    // MARK: - IBActions
    @IBAction private func tapToScanQRButton() {
        present(qrReaderViewController, animated: true)
        
        DeeplinkManager.shared.currentGame = nil
        
        updateViews()
    }

    @IBAction private func tapToVolumeButton() {
        guard let text = DeeplinkManager.shared.currentGame?.textToSpeak else {
            return
        }
        
        speakText(text)
    }
    
    @IBAction private func tapToAnswerButton() {
        answerTextField.resignFirstResponder()
        
        guard let answerString = answerTextField.text, answerString.isEmpty == false else {
            return
        }
        

        if answerString == DeeplinkManager.shared.currentGame?.answer {
            var urlComponents = URLComponents(string: "http://api.giphy.com/v1/gifs/random")
            urlComponents?.queryItems = [
                URLQueryItem(name: "api_key", value: "6XhpejPp6KPmQmScbcJDHRtZSlbtj8GR"),
                URLQueryItem(name: "tag", value: "win"),
                URLQueryItem(name: "rating", value: "PG"),
            ]
            
            guard let url = urlComponents?.url else {
                return
            }
            
            let urlRequest = URLRequest(url: url)
            let session = URLSession.shared

            let dataTask = session.dataTask(with: urlRequest) { [weak self] data, _,error in
                DispatchQueue.main.sync {
                    guard let self = self else {
                        return
                    }
                    
                    do {
                        guard let data = data else {
                            if let error = error {
                                throw error
                            } else {
                                return
                            }
                        }
                        
                        let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        
                        guard let dataJsonResult = jsonResult?["data"] as? [String: Any] else {
                            return
                        }
                        
                        guard let gifUrlString = dataJsonResult["image_url"] as? String, let gifUrl = URL(string: gifUrlString) else {
                            return
                        }
                        
                        self.openWinScreen(url: gifUrl)
                        
                        DeeplinkManager.shared.currentGame = nil
                        
                        self.updateViews()
                    } catch let error as NSError {
                        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "Ok", style: .default)
                        alertController.addAction(okAction)
                        self.present(alertController, animated: true)
                    }
                }
            }
            dataTask.resume()
        } else {
            let alertViewController = PMAlertController(title: "Не верно", description: "Твой ответ неверный", image: UIImage(named: "disapoined_icon"), style: .alert)

            alertViewController.addAction(PMAlertAction(title: "OK", style: .default))

            present(alertViewController, animated: true, completion: { [weak self] in
                guard let self = self else {
                    return
                }

                self.answerTextField.text = nil
                self.speakText("Твой ответ неверный!")
            })
        }
    }
    
    @objc private func updateViews() {
        if let game = DeeplinkManager.shared.currentGame {
            questionAndAnswerStackView.isHidden = false
            
            switch game {
            case .simpleMathExercise(let question, _):
                questionLabel.text = question
            }
            
            scanQRButton.isHidden = true
        } else {
            questionAndAnswerStackView.isHidden = true
            answerTextField.text = nil
            scanQRButton.isHidden = false
        }
    }
    
    private func openWinScreen(url: URL) {
        let winViewController = storyboard?.instantiateViewController(withIdentifier: "WinViewController") as! WinViewController
        winViewController.gifUrl = url
        winViewController.delegate = self
        present(winViewController, animated: true, completion: { [weak self] in
            guard let self = self else {
                return
            }
            
            self.speakText("Ура! Ты ответил правильно!")
        })
    }
    
    private func speakText(_ text: String) {
        let speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "ru-RU")

        speechSynthesizer.speak(speechUtterance)
    }
}

extension ViewController: WinViewControllerDelegate {
    
    func tapToCloseButton() {
        presentedViewController?.dismiss(
            animated: true,
            completion: { [weak self] in
                guard let self = self else {
                    return
                }

                self.updateViews()
            }
        )
    }
}


extension ViewController: QRCodeReaderViewControllerDelegate {

    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        if let scanedUrl = URL(string: result.value) {
            DeeplinkManager.shared.handleUrl(scanedUrl)
        }

        updateViews()
        
        dismiss(animated: true)
    }

    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()

        updateViews()
        
        dismiss(animated: true)
    }
}
