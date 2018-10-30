import Foundation


public typealias OfflineVersion = String
public typealias OfflineDownloaderCompletionHandler = (_ location: URL?,_ response: URLResponse?, _ error: Error?) -> Void
public typealias OfflineDownloaderProgressHandler = (_ bytesWritten: Int64, _ totalBytesWritten: Int64, _ totalBytesExpectedToWrite: Int64) -> Void
public typealias OfflineVersionsHandler = (_ version: [OfflineVersion]?, _ error: Error?) -> Void

struct AvailableVersionsResponse: Codable {
    let availableVersions: [String]
}

@objc(MBOfflineDirectionsProtocol)
public protocol OfflineDirectionsProtocol {
    
    /**
     Fetches the available versions.
     */
    @discardableResult
    func availableOfflineVersions(completionHandler: @escaping OfflineVersionsHandler) -> URLSessionDataTask
    
    /**
     Initiates a download process of all tiles needed to provide routing within the given bounding box.
     
     - parameter boundingBox: The region of the pack to be downloaded.
     - parameter version: The version of the pack to be downloaded.
     - parameter progressHandler: Reports the progress of downloaded and yet to be downloaded bytes
     - parameter completionHandler: Informs when the download is completed or failed. The offline pack may be moved from the temporary directory and to a persistent store at this point.
     */
    @discardableResult
    func downloadTiles(for boundingBox: BoundingBox, version: OfflineVersion, progressHandler: @escaping OfflineDownloaderProgressHandler, completionHandler: @escaping OfflineDownloaderCompletionHandler) -> URLSessionDownloadTask
}

extension Directions: OfflineDirectionsProtocol, URLSessionDownloadDelegate {
    
    func availableVersionsURL() -> URL {
        
        let url = apiEndpoint.appendingPathComponent("route-tiles/v1").appendingPathComponent("versions")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = [URLQueryItem(name: "access_token", value: accessToken)]
        
        return components!.url!
    }
    
    func tilesURL(for boundingBox: BoundingBox, version: OfflineVersion) -> URL {
        
        let url = apiEndpoint.appendingPathComponent("route-tiles/v1").appendingPathComponent(boundingBox.path)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = [URLQueryItem(name: "version", value: version),
                                  URLQueryItem(name: "access_token", value: accessToken)]
        
        return components!.url!
    }

    @discardableResult
    @objc
    public func availableOfflineVersions(completionHandler: @escaping OfflineVersionsHandler) -> URLSessionDataTask {
        
        return URLSession.shared.dataTask(with: availableVersionsURL()) { (data, response, error) in
            if let error = error {
                return completionHandler(nil, error)
            }
            
            guard let data = data else {
                return completionHandler(nil, error)
            }
            
            do {
                let versionResponse = try JSONDecoder().decode(AvailableVersionsResponse.self, from: data)
                completionHandler(versionResponse.availableVersions, error)
            } catch {
                completionHandler(nil, error)
            }
        }
    }
    
    @discardableResult
    @objc
    public func downloadTiles(for boundingBox: BoundingBox, version: OfflineVersion, progressHandler: @escaping OfflineDownloaderProgressHandler, completionHandler: @escaping OfflineDownloaderCompletionHandler) -> URLSessionDownloadTask {
        
        self.offlineProgressHandler = progressHandler
        self.offlineCompletionHandler = completionHandler
        
        let configuration = URLSessionConfiguration.default
        let url = tilesURL(for: boundingBox, version: version)
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        return session.downloadTask(with: url)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        // TODO: resume download when range headers are supported
    }
    
    open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        offlineCompletionHandler?(location, downloadTask.response, downloadTask.error)
    }
    
    open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        offlineProgressHandler?(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }
}