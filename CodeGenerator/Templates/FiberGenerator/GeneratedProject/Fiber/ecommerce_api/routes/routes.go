package routes

import (
    "github.com/gofiber/fiber/v2"

    "ecommerce_api/config"
    "ecommerce_api/handlers"
    "ecommerce_api/repositories"
    "ecommerce_api/services"
)

func SetupRoutes(app *fiber.App) {
    api := app.Group("/api/v1")


    // User routes
    userRepo := repositories.NewUserRepository(config.DB)
    userService := services.NewUserService(userRepo)
    userHandler := handlers.NewUserHandler(userService)

    userGroup := api.Group("")
    userGroup.Get("/", userHandler.GetAll)
    userGroup.Get("/:id", userHandler.GetByID)
    userGroup.Post("/", userHandler.Create)
    userGroup.Put("/:id", userHandler.Update)
    userGroup.Delete("/:id", userHandler.Delete)

    // Admin_user routes
    admin_userRepo := repositories.NewAdmin_userRepository(config.DB)
    admin_userService := services.NewAdmin_userService(admin_userRepo)
    admin_userHandler := handlers.NewAdmin_userHandler(admin_userService)

    admin_userGroup := api.Group("")
    admin_userGroup.Get("/", admin_userHandler.GetAll)
    admin_userGroup.Get("/:id", admin_userHandler.GetByID)
    admin_userGroup.Post("/", admin_userHandler.Create)
    admin_userGroup.Put("/:id", admin_userHandler.Update)
    admin_userGroup.Delete("/:id", admin_userHandler.Delete)

    // Role routes
    roleRepo := repositories.NewRoleRepository(config.DB)
    roleService := services.NewRoleService(roleRepo)
    roleHandler := handlers.NewRoleHandler(roleService)

    roleGroup := api.Group("")
    roleGroup.Get("/", roleHandler.GetAll)
    roleGroup.Get("/:id", roleHandler.GetByID)
    roleGroup.Post("/", roleHandler.Create)
    roleGroup.Put("/:id", roleHandler.Update)
    roleGroup.Delete("/:id", roleHandler.Delete)

    // Permission routes
    permissionRepo := repositories.NewPermissionRepository(config.DB)
    permissionService := services.NewPermissionService(permissionRepo)
    permissionHandler := handlers.NewPermissionHandler(permissionService)

    permissionGroup := api.Group("")
    permissionGroup.Get("/", permissionHandler.GetAll)
    permissionGroup.Get("/:id", permissionHandler.GetByID)
    permissionGroup.Post("/", permissionHandler.Create)
    permissionGroup.Put("/:id", permissionHandler.Update)
    permissionGroup.Delete("/:id", permissionHandler.Delete)

    // Address routes
    addressRepo := repositories.NewAddressRepository(config.DB)
    addressService := services.NewAddressService(addressRepo)
    addressHandler := handlers.NewAddressHandler(addressService)

    addressGroup := api.Group("")
    addressGroup.Get("/", addressHandler.GetAll)
    addressGroup.Get("/:id", addressHandler.GetByID)
    addressGroup.Post("/", addressHandler.Create)
    addressGroup.Put("/:id", addressHandler.Update)
    addressGroup.Delete("/:id", addressHandler.Delete)

    // Product routes
    productRepo := repositories.NewProductRepository(config.DB)
    productService := services.NewProductService(productRepo)
    productHandler := handlers.NewProductHandler(productService)

    productGroup := api.Group("")
    productGroup.Get("/", productHandler.GetAll)
    productGroup.Get("/:id", productHandler.GetByID)
    productGroup.Post("/", productHandler.Create)
    productGroup.Put("/:id", productHandler.Update)
    productGroup.Delete("/:id", productHandler.Delete)

    // Category routes
    categoryRepo := repositories.NewCategoryRepository(config.DB)
    categoryService := services.NewCategoryService(categoryRepo)
    categoryHandler := handlers.NewCategoryHandler(categoryService)

    categoryGroup := api.Group("")
    categoryGroup.Get("/", categoryHandler.GetAll)
    categoryGroup.Get("/:id", categoryHandler.GetByID)
    categoryGroup.Post("/", categoryHandler.Create)
    categoryGroup.Put("/:id", categoryHandler.Update)
    categoryGroup.Delete("/:id", categoryHandler.Delete)

    // Order routes
    orderRepo := repositories.NewOrderRepository(config.DB)
    orderService := services.NewOrderService(orderRepo)
    orderHandler := handlers.NewOrderHandler(orderService)

    orderGroup := api.Group("")
    orderGroup.Get("/", orderHandler.GetAll)
    orderGroup.Get("/:id", orderHandler.GetByID)
    orderGroup.Post("/", orderHandler.Create)
    orderGroup.Put("/:id", orderHandler.Update)
    orderGroup.Delete("/:id", orderHandler.Delete)

    // Order_item routes
    order_itemRepo := repositories.NewOrder_itemRepository(config.DB)
    order_itemService := services.NewOrder_itemService(order_itemRepo)
    order_itemHandler := handlers.NewOrder_itemHandler(order_itemService)

    order_itemGroup := api.Group("")
    order_itemGroup.Get("/", order_itemHandler.GetAll)
    order_itemGroup.Get("/:id", order_itemHandler.GetByID)
    order_itemGroup.Post("/", order_itemHandler.Create)
    order_itemGroup.Put("/:id", order_itemHandler.Update)
    order_itemGroup.Delete("/:id", order_itemHandler.Delete)

    // Payment routes
    paymentRepo := repositories.NewPaymentRepository(config.DB)
    paymentService := services.NewPaymentService(paymentRepo)
    paymentHandler := handlers.NewPaymentHandler(paymentService)

    paymentGroup := api.Group("")
    paymentGroup.Get("/", paymentHandler.GetAll)
    paymentGroup.Get("/:id", paymentHandler.GetByID)
    paymentGroup.Post("/", paymentHandler.Create)
    paymentGroup.Put("/:id", paymentHandler.Update)
    paymentGroup.Delete("/:id", paymentHandler.Delete)

}