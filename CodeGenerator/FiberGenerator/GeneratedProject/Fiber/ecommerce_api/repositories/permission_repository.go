package repositories

import (


    "gorm.io/gorm"
    "ecommerce_api/models"
)

type PermissionRepository struct {
    db *gorm.DB
}

func NewPermissionRepository(db *gorm.DB) *PermissionRepository {
    return &PermissionRepository{db: db}
}

func (r *PermissionRepository) FindAll() ([]models.Permission, error) {
    var items []models.Permission
    result := r.db.Find(&items)
    return items, result.Error
}

func (r *PermissionRepository) FindByID(id uint) (*models.Permission, error) {
    var item models.Permission
    result := r.db.First(&item, id)
    if result.Error != nil {
        return nil, result.Error
    }
    return &item, nil
}

func (r *PermissionRepository) Create(item *models.Permission) error {
    return r.db.Create(item).Error
}

func (r *PermissionRepository) Update(item *models.Permission) error {
    return r.db.Save(item).Error
}

func (r *PermissionRepository) Delete(id uint) error {
    return r.db.Delete(&models.Permission{}, id).Error
}