import Foundation

/// Downloads GGUF model files from HuggingFace with progress reporting.
public class ModelDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    public static let shared = ModelDownloader()
    
    @Published public var isDownloading = false
    @Published public var progress: Double = 0.0          // 0.0 – 1.0
    @Published public var downloadedBytes: Int64 = 0
    @Published public var totalBytes: Int64 = 0
    @Published public var error: String? = nil
    
    private var downloadTask: URLSessionDownloadTask?
    private var session: URLSession!
    private var destinationPath: String = ""
    private var completion: ((Bool) -> Void)?
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 3600  // 1 hour timeout for large files
        session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }
    
    /// Start downloading a model of the given size.
    /// Completion is called on the main thread with true on success, false on failure.
    public func download(size: LocalModelSize, completion: @escaping (Bool) -> Void) {
        guard !isDownloading else {
            completion(false)
            return
        }
        
        // Ensure the models directory exists
        ConfigManager.shared.ensureModelsDirectory()
        
        self.completion = completion
        self.destinationPath = ConfigManager.shared.modelPath(for: size)
        self.error = nil
        self.progress = 0.0
        self.downloadedBytes = 0
        self.totalBytes = 0
        self.isDownloading = true
        
        let task = session.downloadTask(with: size.downloadURL)
        self.downloadTask = task
        task.resume()
    }
    
    /// Cancel an in-progress download.
    public func cancel() {
        downloadTask?.cancel()
        downloadTask = nil
        isDownloading = false
        progress = 0.0
        error = nil
        completion?(false)
        completion = nil
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let destination = URL(fileURLWithPath: destinationPath)
        
        do {
            // Remove any existing file at the destination
            let fm = FileManager.default
            if fm.fileExists(atPath: destinationPath) {
                try fm.removeItem(atPath: destinationPath)
            }
            
            // Move the downloaded temp file to the final location
            try fm.moveItem(at: location, to: destination)
            
            self.isDownloading = false
            self.progress = 1.0
            self.completion?(true)
            self.completion = nil
        } catch {
            self.isDownloading = false
            self.error = "Failed to save model: \(error.localizedDescription)"
            self.completion?(false)
            self.completion = nil
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        self.downloadedBytes = totalBytesWritten
        self.totalBytes = totalBytesExpectedToWrite
        if totalBytesExpectedToWrite > 0 {
            self.progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        if let error = error {
            // Don't report cancellation as an error
            if (error as NSError).code == NSURLErrorCancelled {
                return
            }
            self.isDownloading = false
            self.error = "Download failed: \(error.localizedDescription)"
            self.completion?(false)
            self.completion = nil
        }
    }
}
