package repositories

import (


    "gorm.io/gorm"
    "ecommerce_api/models"
)

type RoleRepository struct {
    db *gorm.DB
}

func NewRoleRepository(db *gorm.DB) *RoleRepository {
    return &RoleRepository{db: db}
}

func (r *RoleRepository) FindAll() ([]models.Role, error) {
    var items []models.Role
    result := r.db.Find(&items)
    return items, result.Error
}

func (r *RoleRepository) FindByID(id uint) (*models.Role, error) {
    var item models.Role
    result := r.db.First(&item, id)
    if result.Error != nil {
        return nil, result.Error
    }
    return &item, nil
}

func (r *RoleRepository) Create(item *models.Role) error {
    return r.db.Create(item).Error
}

func (r *RoleRepository) Update(item *models.Role) error {
    return r.db.Save(item).Error
}

func (r *RoleRepository) Delete(id uint) error {
    return r.db.Delete(&models.Role{}, id).Error
}