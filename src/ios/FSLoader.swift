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
    internal var finishedTask: [FSTask]
    internal var startedTask: [FSTask]

    internal init(session: URLSession) {
        self.session = session
        self.finishedTask = []
        self.startedTask = []
    }

    internal func handleComplete(task: URLSessionTask, error: Error?) {

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
        self.finishedTask.append(fsTask)
    }

    internal func handleTaskError(failedTask: FSTask, error: Error) {
        print("[FileSync] FSTask completed with error: \(error.localizedDescription)");
        print("[FileSync] FSTask completet with error", failedTask.sessionTask!.originalRequest!)

        let task = self.session.downloadTask(with: failedTask.url)
        task.taskDescription = failedTask.sessionTask?.taskDescription

        if failedTask.restart(task) {
            self.startedTask.append(failedTask)
        }
    }

    // ---------------------
    // create, find tasks
    // ---------------------
    internal func getIndexOfActiveTask(taskToFind: URLSessionTask) -> Int? {
        for (index, startedTask) in self.startedTask.enumerated() {
            if startedTask.sessionTask?.taskIdentifier == taskToFind.taskIdentifier {
                return index
            }
        }
        return nil
    }

    internal func getStartedTask(_ task: URLSessionTask) -> FSTask? {
        guard let index = getIndexOfActiveTask(taskToFind: task) else {
            print("[FileSync] failed fs-task not found in startedTasks (IMPOSSIBLE)", task.originalRequest!)
            return nil
        }
        return self.startedTask[index]
    }


    internal func removeStartedTask(_ task: URLSessionTask) -> FSTask?{
        guard let index = getIndexOfActiveTask(taskToFind: task) else {
            print("[FileSync] failed fs-task not found in startedTasks (IMPOSSIBLE)", task.originalRequest!)
            return nil
        }
        let task = self.startedTask[index]
        self.startedTask.remove(at: index)
        return task
    }

    internal func removeFinishedTask(_ task: URLSessionTask) -> FSTask?{
        guard let index = getIndexOfActiveTask(taskToFind: task) else {
            print("[FileSync] failed fs-task not found in finishedTasks (IMPOSSIBLE)", task.originalRequest!)
            return nil
        }
        let task = self.finishedTask[index]
        self.finishedTask.remove(at: index)
        return task
    }

    // used startUploads and startDownloads instead
    internal func startTasks() -> FSTask {
        fatalError("Subclasses need to implement the `createTask()` method. Sorry about this but there are no abstract classes in swift.")
    }

}
