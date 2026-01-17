package main

import (
    "github.com/gofiber/fiber/v2"
    "gorm.io/driver/sqlite"
    "gorm.io/gorm"
    "your_project/controller"
    "your_project/repository"
    "your_project/service"
)

func main() {
     // DB
    db, _ := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
    userRepo := &repository.UserRepository{DB: db}

    // Service
    userService := &service.UserService{UserRepo: userRepo}

    // Controller
    userController := &controller.UserController{UserService: userService}

    // Routes
    app.Get("/users", userController.GetAll)

    app.Listen(":8000")
}
