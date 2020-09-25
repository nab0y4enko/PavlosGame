import UIKit
import Foundation
import PlaygroundSupport

func generateQRCode(from string: String) -> UIImage? {
    let data = string.data(using: String.Encoding.ascii)

    if let filter = CIFilter(name: "CIQRCodeGenerator") {
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 20, y: 20)

        if let output = filter.outputImage?.transformed(by: transform) {
            return UIImage(ciImage: output)
        }
    }

    return nil
}

func save(image: UIImage, name: String) -> Bool {
    guard var path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first, let imageData = image.pngData() else {
        return false
    }
    
    path = path.appendingPathComponent(name)
    
    print(path)
    
    do {
        try imageData.write(to: path)
    } catch {
        print(error)
        return false
    }
    return true
}

let directories = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
let documentDirectory = URL(string: directories.first!)

for i in (1...5) {
    for j in (1...5) {
        let question = "\(i) + \(j)"
        let answer = "\(i + j)"
        
        var urlComponents = URLComponents(string: "com.pavlo.game://simple_math_exercise")
        urlComponents?.queryItems = [
            URLQueryItem(name: "question", value: question),
            URLQueryItem(name: "rightAnswer", value: answer)
        ]
        
        guard let url = urlComponents?.url else {
            continue
        }
        
        
        guard let image = generateQRCode(from: url.absoluteString) else {
            continue
        }

        
        save(image: image, name: "\(question).png")
    }
}



