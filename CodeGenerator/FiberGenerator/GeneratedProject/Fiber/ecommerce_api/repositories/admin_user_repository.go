package repositories

import (


    "gorm.io/gorm"
    "ecommerce_api/models"
)

type Admin_userRepository struct {
    db *gorm.DB
}

func NewAdmin_userRepository(db *gorm.DB) *Admin_userRepository {
    return &Admin_userRepository{db: db}
}

func (r *Admin_userRepository) FindAll() ([]models.Admin_user, error) {
    var items []models.Admin_user
    result := r.db.Find(&items)
    return items, result.Error
}

func (r *Admin_userRepository) FindByID(id uint) (*models.Admin_user, error) {
    var item models.Admin_user
    result := r.db.First(&item, id)
    if result.Error != nil {
        return nil, result.Error
    }
    return &item, nil
}

func (r *Admin_userRepository) Create(item *models.Admin_user) error {
    return r.db.Create(item).Error
}

func (r *Admin_userRepository) Update(item *models.Admin_user) error {
    return r.db.Save(item).Error
}

func (r *Admin_userRepository) Delete(id uint) error {
    return r.db.Delete(&models.Admin_user{}, id).Error
}