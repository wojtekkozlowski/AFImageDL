//: Playground - noun: a place where people can play

import UIKit
import AFNetworking
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

class Card {
    let url: String
    var image: UIImage? = nil
    init(url: String) {
        self.url = url
    }
}

//-----------------------------------------------------------
class AllImagesDownloader {
    
    private let sessionManager: AFHTTPSessionManager = {
        let m = AFHTTPSessionManager()
        m.responseSerializer = AFImageResponseSerializer()
        return m
    }()
    
    private lazy var downloader:AFImageDownloader = {
        return AFImageDownloader(sessionManager: self.sessionManager, downloadPrioritization: .FIFO, maximumActiveDownloads: 5, imageCache: nil)
    }()

    
    func fetchImages(_ items: [Card], completion: @escaping () -> Void) {
        let allImagesGroup = DispatchGroup()
        
        items.enumerated().forEach { _, item in
            allImagesGroup.enter()
            DispatchQueue.global().async {
                self.downloader.downloadImage(for: URLRequest(url: URL(string: item.url)!), success: { (_, _, image) in
                    item.image = image
                    allImagesGroup.leave()
                }, failure: { (req, res, error) in
                    print(req); print(res as Any); print(error)
                    
                })
            }
        }
        allImagesGroup.notify(queue: DispatchQueue.main) {
            completion()
        }
    }
}

let cards = [Card(url: "http://localhost:8080/i1.png"),
             Card(url: "http://localhost:8080/i2.png"),
             Card(url: "http://localhost:8080/i3.png")]

let start = Date()
AllImagesDownloader().fetchImages(cards) {
    cards.forEach { print($0.image ?? "no image?") }
    print("total time: \(round((Date().timeIntervalSince1970 - start.timeIntervalSince1970) * 100)/100.0)")
}
