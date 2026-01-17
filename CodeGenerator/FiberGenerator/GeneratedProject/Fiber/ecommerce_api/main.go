package main

import (
    "log"
    "os"

    "github.com/gofiber/fiber/v2"
    "github.com/gofiber/fiber/v2/middleware/logger"
    "github.com/gofiber/fiber/v2/middleware/cors"
    "github.com/joho/godotenv"

    "ecommerce_api/config"
    "ecommerce_api/routes"
)

func main() {
    // Load environment variables
    if err := godotenv.Load(); err != nil {
        log.Println("No .env file found")
    }

    // Initialize database
    config.ConnectDatabase()
    config.AutoMigrate(config.DB)

    // Create Fiber app
    app := fiber.New(fiber.Config{
        AppName: "ecommerce_api",
    })

    // Middleware
    app.Use(logger.New())
    app.Use(cors.New())

    // Setup routes
    routes.SetupRoutes(app)

    // Start server
    port := os.Getenv("SERVER_PORT")
    if port == "" {
        port = "3000"
    }

    log.Fatal(app.Listen(":" + port))
}