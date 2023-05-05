import Fluent
import Vapor

struct RestaurantController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("categories", use: getCategories)
        routes.get("menu", use: getMenus)
        routes.post("order", use: orderMenuItems)
    }
    
    func getCategories(req: Request) async throws -> Response {
        let categories = try await Category.query(on: req.db).all()
        let result = CategoriesResponse(categories: categories)
        return try await result.encodeResponse(for: req)
    }
    
    func getMenus(req: Request) async throws -> Response {
        let menuItems: [MenuItem]
        
        if let categoryName = try? req.query.decode(MenuItemRequestQuery.self).category {
            menuItems = try await MenuItem.query(on: req.db).with(\.$category).all()
                .filter({ $0.category.category == categoryName })
        } else {
            menuItems = try await MenuItem.query(on: req.db).with(\.$category).all()
        }
        
        let result = MenuItemsResponse(menuItems: menuItems)
        return try await result.encodeResponse(for: req)
    }
    
    func orderMenuItems(req: Request) async throws -> [String: Int] {
        var preperationTime = 1
        
        guard let menuIds = try? req.content.decode(OrderRequestQuery.self).menuIds else {
            return ["preparation_time": preperationTime]
        }
        
        let menuItems = try await MenuItem.query(on: req.db).all()
        
        preperationTime = menuIds
            .compactMap { id in
                menuItems.filter { item in (try? item.requireID() == id) ?? false }.first
            }
            .reduce(preperationTime) { $0 + $1.estimatedPrepTime }
        
        return ["preparation_time": preperationTime]
    }

//    func index(req: Request) async throws -> [Todo] {
//        try await Todo.query(on: req.db).all()
//    }
//
//    func create(req: Request) async throws -> Todo {
//        let todo = try req.content.decode(Todo.self)
//        try await todo.save(on: req.db)
//        return todo
//    }
//
//    func delete(req: Request) async throws -> HTTPStatus {
//        guard let todo = try await Todo.find(req.parameters.get("todoID"), on: req.db) else {
//            throw Abort(.notFound)
//        }
//        try await todo.delete(on: req.db)
//        return .noContent
//    }
    
}