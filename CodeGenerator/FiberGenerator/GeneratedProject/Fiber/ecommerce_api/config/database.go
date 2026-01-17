package config

import (
    "fmt"
    "log"
    "os"
    "ecommerce_api/models"

    "github.com/joho/godotenv"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
    "gorm.io/gorm/logger"
)

var DB *gorm.DB

func ConnectDatabase() {
     //chargement fichier env
    err := godotenv.Load()

    if err != nil {
        log.Println("Warning: No .env file found")
    }

    // Récuperation des variables
    host := os.Getenv("DB_HOST")
    user := os.Getenv("DB_USER")
    password := os.Getenv("DB_PASSWORD")
    dbname := os.Getenv("DB_NAME")
    port := os.Getenv("DB_PORT")

   //  DSN
    dsn := fmt.Sprintf(
        "host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
        host, user, password, dbname, port,
    )

    // Connexion BD
    DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{
        Logger: logger.Default.LogMode(logger.Info),
    })

    if err != nil {
        log.Fatal("Failed to connect to database:", err)
    }



    log.Println("Database connected successfully")
}

func AutoMigrate(db *gorm.DB) error {
    return db.AutoMigrate(
        &models.User{},
        &models.Admin_user{},
        &models.Role{},
        &models.Permission{},
        &models.Address{},
        &models.Product{},
        &models.Category{},
        &models.Order{},
        &models.Order_item{},
        &models.Payment{},
    )
        }