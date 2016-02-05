//
// Based on HttpServer from Swifter (https://github.com/glock45/swifter) by Damian Kołakowski.
//

import Foundation

public class Blackfish: SocketServer {

    public static let VERSION = "0.1.2"

    private let middlewareManager: MiddlewareManager
    
    private let routeManager: RouteManager

    public override init() {
        middlewareManager = MiddlewareManager()
        routeManager = RouteManager()
        super.init()
    }
    
    override func dispatch(request request: Request, response: Response, handlers: [Middleware.Handler]?) {
        
        if var handlers = handlers {
            
            if let handler = handlers.popLast() {
                
                handler(request: request, response: response, next: { () -> () in
                    self.dispatch(request: request, response: response, handlers: handlers)
                })
                
            } else {
                if let result = routeManager.routeSingle(request) {
                    result(request: request, response: response)
                } else {
                    super.dispatch(request: request, response: response, handlers: nil)
                }
            }
            
        } else {
            let handlers = middlewareManager.route(request)
            dispatch(request: request, response: response, handlers: handlers)
        }
    }
    
    func parseRoutes() {
        
        for route in Route.routes {
            
            self.routeManager.register(route.method.rawValue, driver: route) { request, response in
                
                // Grab request params
                let routePaths = route.path.split("?")[0].split("/")
                
                for (index, path) in routePaths.enumerate() {
                    if path.hasPrefix(":") {
                        let requestPaths = request.path.split("/")
                        if requestPaths.count > index {
                            var trimPath = path
                            trimPath.removeAtIndex(path.startIndex)
                            request.parameters[trimPath] = requestPaths[index]
                        }
                    }
                }
                
                Session.start(request)
                
                route.handler(request: request, response: response)
            }
        }
    }
}

// MARK: - Public Methods

extension Blackfish {
    
    public func listen(port inPort: Int = 80, handler: ((error: ErrorType?) -> ())? = nil) {
        
        parseRoutes()
        
        var port = inPort
        
        if Process.arguments.count >= 2 {
            let secondArg = Process.arguments[1]
            if secondArg.hasPrefix("--port=") {
                let portString = secondArg.split("=")[1]
                if let portInt = Int(portString) {
                    port = portInt
                }
            }
        }
        
        do {
            try self.start(port)
            handler?(error: nil)
            self.loop()
        } catch {
            handler?(error: error)
        }
    }
    
    public func use(path path: String, router: Router) {
        Route.createRoutesFromRouter(router, withPath: path)
    }
}

// MARK: - Routing

extension Blackfish: Routing {
    
    public func use(middleware middleware: Middleware) {
        middlewareManager.register(middleware)
    }
    
    public func get(path: String, handler: Route.Handler) {
        Route.get(path, handler: handler)
    }
    
    public func put(path: String, handler: Route.Handler) {
        Route.put(path, handler: handler)
    }
    
    public func delete(path: String, handler: Route.Handler) {
        Route.delete(path, handler: handler)
    }
    
    public func post(path: String, handler: Route.Handler) {
        Route.post(path, handler: handler)
    }
    
    public func patch(path: String, handler: Route.Handler) {
        Route.patch(path, handler: handler)
    }
    
    public func all(path: String, handler: Route.Handler) {
        Route.all(path, handler: handler)
    }
    
}
