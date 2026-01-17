package repositories

import (

    "gorm.io/gorm"
    "ecommerce_api/models"
)

type UserRepository struct {
    db *gorm.DB
}

func NewUserRepository(db *gorm.DB) *UserRepository {
    return &UserRepository{db: db}
}

func (r *UserRepository) FindAll() ([]models.User, error) {
    var items []models.User
    result := r.db.Find(&items)
    return items, result.Error
}

func (r *UserRepository) FindByID(id string) (*models.User, error) {
    var item models.User
    result := r.db.First(&item, id)
    if result.Error != nil {
        return nil, result.Error
    }
    return &item, nil
}

func (r *UserRepository) Create(item *models.User) error {
    return r.db.Create(item).Error
}

func (r *UserRepository) Update(item *models.User) error {
    return r.db.Save(item).Error
}

func (r *UserRepository) Delete(id string) error {
    return r.db.Delete(&models.User{}, id).Error
}