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
    
    static func dataForFile(_ file: String) -> Data {
        return try! Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: file, ofType: "")!))
    }
    
    private let sessionManager: AFHTTPSessionManager = {
        let m = AFHTTPSessionManager()
        let s = AFSecurityPolicy(pinningMode: AFSSLPinningMode.publicKey)
        s.allowInvalidCertificates = true
        s.pinnedCertificates = Set([AllImagesDownloader.dataForFile("server.crt")])
        m.securityPolicy = s
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
                }, failure: { (_, _, error) in
                     print(error)
                })
            }
        }
        allImagesGroup.notify(queue: DispatchQueue.main) {
            completion()
        }
    }
}

let cards = [Card(url: "https://localhost:4443/i1.png"),
             Card(url: "https://localhost:4443/i1.png"),
             Card(url: "https://localhost:4443/i1.png")]

AllImagesDownloader().fetchImages(cards) {
    cards.forEach { print($0.image ?? "no image?") }
}
