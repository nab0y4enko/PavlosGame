//
//  WinViewController.swift
//  PavlosGame
//
//  Created by Oleksii Naboichenko on 08.02.2020.
//  Copyright © 2020 Oleksii Naboichenko. All rights reserved.
//

import UIKit
import SDWebImage

protocol WinViewControllerDelegate: AnyObject {
    func tapToCloseButton()
}

final class WinViewController: UIViewController {
    
    @IBOutlet private weak var imageView: SDAnimatedImageView!

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet private weak var closeButton: UIButton! {
        didSet {
            closeButton.layer.cornerRadius = 10
        }
    }
    
    var gifUrl: URL?
    weak var delegate: WinViewControllerDelegate?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadGifImage()
    }
    
    @IBAction func tapToCloseButton() {
        delegate?.tapToCloseButton()
    }
    
    private func loadGifImage() {
        activityIndicatorView.startAnimating()
        
        imageView.sd_setImage(with: gifUrl) { [weak self] (_, error, _, _) in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }

                self.activityIndicatorView.stopAnimating()
                
                if let errorDescription = error?.localizedDescription {
                    let alertController = UIAlertController(title: "Error", message: errorDescription, preferredStyle: .alert)
                    
                    let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                        guard let self = self else {
                            return
                        }
                        
                        self.tapToCloseButton()
                    }
                    
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true)
                }
            }
        }
    }
}
