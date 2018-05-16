class FSDownloader: FSLoader {
    
    // gets called before upload/download finished
    // gets called before startedDownload did move to FinishedDownload
    internal func handleDownloadFinished(downloadTask: URLSessionDownloadTask, downloadLocation: URL) {

        /* not needed anymore
        guard let keyForDownloadTask = self.getStartedTask(downloadTask) else {
            print("[FileSync] could not find started download task, but is needed so wen can move file to download dir")
            return
        }
        */

        // optional check hash, to enshure correct loading
        FSFileSystem.Instance().moveToRoot(from: downloadLocation, relativeTo: (self.startedTask[downloadTask.taskIdentifier]?.localPath)!)
    }

    internal func startDownloads(files: [AnyObject], remoteBaseUrl: URL) {
        objc_sync_enter(self.startedTask)

        for item in files {
            let downloadUrl = remoteBaseUrl.appendingPathComponent(item["file"] as! String)

            let task = self.session.downloadTask(with: downloadUrl)
            task.taskDescription = "download"
            let fsTask = FSTask(url: downloadUrl, localPath: item["file"] as! String, sessionTask: task)
            fsTask.start()
            self.startedTask[task.taskIdentifier] = fsTask
        }
        objc_sync_exit(self.startedTask)
    }
    
}
