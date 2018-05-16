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

    internal let session: URLSession
    internal var finishedTask: [Int:FSTask]
    internal var startedTask: [Int:FSTask]

    internal init(session: URLSession) {
        self.session = session
        self.finishedTask = [:]
        self.startedTask = [:]
    }

    internal func handleComplete(task: URLSessionTask, error: Error?) {

        print("[FileSync] started tasks", self.startedTask.count)
        print("[FileSync] finished tasks", self.finishedTask.count)

        guard let fsTask = self.removeStartedTask(task) else {
            return
        }

        guard error == nil else {
            self.handleTaskError(failedTask: fsTask, error: error!)
            return
        }

        self.handleTaskCompleted(fsTask: fsTask)
    }

    // ---------------------
    // task complete/error
    // ---------------------
    internal func handleTaskCompleted(fsTask: FSTask) {
        self.finishedTask[(fsTask.sessionTask?.taskIdentifier)!] = fsTask
    }

    internal func handleTaskError(failedTask: FSTask, error: Error) {
        print("[FileSync] FSTask completed with error: \(error.localizedDescription)");
        print("[FileSync] FSTask completet with error", failedTask.sessionTask!.originalRequest!)

        let task = self.session.downloadTask(with: failedTask.url)
        task.taskDescription = failedTask.sessionTask?.taskDescription

        if failedTask.restart(task) {
            self.startedTask[(failedTask.sessionTask?.taskIdentifier)!] = failedTask
        }
    }

    // ---------------------
    // create, find tasks
    // ---------------------
    /* not needed anymore
    internal func getStartedTask(_ task: URLSessionTask) -> String? {
        var found: String?
        for (_,value) in self.startedTask {
            if (value.sessionTask?.taskIdentifier == task.taskIdentifier) {
                found = value.localPath
                break
            }
        }
        return found
    }
     */


    internal func removeStartedTask(_ task: URLSessionTask) -> FSTask?{
        //print("[FileSync] remove started task", task)

        let fsTask = self.startedTask[task.taskIdentifier]
        self.startedTask.removeValue(forKey: task.taskIdentifier)

        return fsTask
    }

    /* not needed...
    internal func removeFinishedTask(_ task: URLSessionTask) -> FSTask?{
        guard let index = getIndexOfActiveTask(taskToFind: task) else {
            print("[FileSync] failed fs-task not found in finishedTasks (IMPOSSIBLE)", task.originalRequest!)
            return nil
        }
        let task = self.finishedTask[index]
        self.finishedTask.remove(at: index)
        return task
    }
    */

    // used startUploads and startDownloads instead
    internal func startTasks() -> FSTask {
        fatalError("Subclasses need to implement the `createTask()` method. Sorry about this but there are no abstract classes in swift.")
    }

}
