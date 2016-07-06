import Foundation
import Echo

struct StaticFileMiddleware: Middleware {
    func handle(request: Request, response: Response, next: (() -> ())) {
        //check in file system
        let filePath = "Resources" + request.path
        
#if os(Linux)
        let fileManager = NSFileManager.defaultManager()
#else
        let fileManager = NSFileManager.default()
#endif
        var isDir: ObjCBool = false
        
        let exists: Bool
        exists = fileManager.fileExists(atPath: filePath, isDirectory: &isDir)
        if exists && !isDir {
            
            if let fileBody = NSData(contentsOfFile: filePath) {
                var array = [UInt8](repeating: 0, count: fileBody.length)
                fileBody.getBytes(&array, length: fileBody.length)
                let ext = NSURL(fileURLWithPath: filePath).pathExtension ?? ""
                
                response.status = .OK
                response.body = array
                response.contentType = .File(ext: ext)
                response.send()
            } else {
                next();
            }
        } else {
            next()
        }
    }
}
