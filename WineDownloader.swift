//
//  WineDownloader.swift
//  arcadeit
//
//  Created by kevin on 2025-12-11.
//


//
//  WineDownloader.swift
//  arcadeit
//

import Foundation

final class WineDownloader: NSObject, URLSessionDownloadDelegate {
    
    static let shared = WineDownloader()
    
    private var progressHandler: ((Double, Int64, Int64) -> Void)?
    private var completionHandler: ((Result<URL, Error>) -> Void)?
    
    private var session: URLSession!
    
    override init() {
        super.init()
        
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func download(
        from url: URL,
        progress: @escaping (Double, Int64, Int64) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        self.progressHandler = progress
        self.completionHandler = completion
        
        let task = session.downloadTask(with: url)
        task.resume()
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progressHandler?(progress, totalBytesWritten, totalBytesExpectedToWrite)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL)
    {
        completionHandler?(.success(location))
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        if let error = error {
            completionHandler?(.failure(error))
        }
    }
}
