/**
  * background  http://stackoverflow.com/questions/40920912/why-previous-finish-of-download-fires-after-stop-app-and-running-again?noredirect=1#comment69055651_40920912
  *
  * main        https://developer.apple.com/reference/foundation/nsurlsessiondelegate
  * up/down     https://developer.apple.com/reference/foundation/nsurlsessiontaskdelegate
  * upload      https://developer.apple.com/reference/foundation/nsurlsessiondatadelegate
  * download    https://developer.apple.com/reference/foundation/nsurlsessiondownloaddelegate
  *
  * task        https://developer.apple.com/reference/foundation/nsurlsessiontask
  * upload      https://developer.apple.com/reference/foundation/nsurlsessionuploadtask
  * download
  *
**/

class FSLoader {

    internal let session: NSURLSession
    internal var finishedTask: [FSTask]
    internal var startedTask: [FSTask]

    internal init(session: NSURLSession) {
        self.session = session
        self.finishedTask = []
        self.startedTask = []
    }

    internal func handleComplete(task: NSURLSessionTask, error: NSError?) {

        guard let fsTask = self.removeStartedTask(task) else {
            return
        }

        guard error == nil else {
            self.handleTaskError(fsTask, error: error!)
            return
        }

        self.handleTaskCompleted(fsTask)
    }

    // ---------------------
    // task complete/error
    // ---------------------
    internal func handleTaskCompleted(fsTask: FSTask) {
        self.finishedTask.append(fsTask)
    }

    internal func handleTaskError(failedTask: FSTask, error: NSError) {
        print("[FileSync] FSTask completed with error: \(error.localizedDescription)");
        print("[FileSync] FSTask completet with error", failedTask.sessionTask!.originalRequest!)

        let task = self.session.downloadTaskWithURL(failedTask.url)
        task.taskDescription = failedTask.sessionTask?.taskDescription

        if failedTask.restart(task) {
            self.startedTask.append(failedTask)
        }
    }

    // ---------------------
    // create, find tasks
    // ---------------------
    internal func getIndexOfActiveTask(task: NSURLSessionTask) -> Int? {
        for (index, startedTask) in self.startedTask.enumerate() {
            if startedTask.sessionTask?.taskIdentifier == task.taskIdentifier {
                return index
            }
        }
        return nil
    }

    internal func getStartedTask(task: NSURLSessionTask) -> FSTask? {
        guard let index = getIndexOfActiveTask(task) else {
            print("[FileSync] failed fs-task not found in startedTasks (IMPOSSIBLE)", task.originalRequest!)
            return nil
        }
        return self.startedTask[index]
    }


    internal func removeStartedTask(task: NSURLSessionTask) -> FSTask?{
        guard let index = getIndexOfActiveTask(task) else {
            print("[FileSync] failed fs-task not found in startedTasks (IMPOSSIBLE)", task.originalRequest!)
            return nil
        }
        let task = self.startedTask[index]
        self.startedTask.removeAtIndex(index)
        return task
    }

    internal func removeFinishedTask(task: NSURLSessionTask) -> FSTask?{
        guard let index = getIndexOfActiveTask(task) else {
            print("[FileSync] failed fs-task not found in finishedTasks (IMPOSSIBLE)", task.originalRequest!)
            return nil
        }
        let task = self.finishedTask[index]
        self.finishedTask.removeAtIndex(index)
        return task
    }

    // used startUploads and startDownloads instead
    internal func startTasks() -> FSTask {
        fatalError("Subclasses need to implement the `createTask()` method. Sorry about this but there are no abstract classes in swift.")
    }

}
