package repositories

import (


    "gorm.io/gorm"
    "ecommerce_api/models"
)

type CategoryRepository struct {
    db *gorm.DB
}

func NewCategoryRepository(db *gorm.DB) *CategoryRepository {
    return &CategoryRepository{db: db}
}

func (r *CategoryRepository) FindAll() ([]models.Category, error) {
    var items []models.Category
    result := r.db.Find(&items)
    return items, result.Error
}

func (r *CategoryRepository) FindByID(id uint) (*models.Category, error) {
    var item models.Category
    result := r.db.First(&item, id)
    if result.Error != nil {
        return nil, result.Error
    }
    return &item, nil
}

func (r *CategoryRepository) Create(item *models.Category) error {
    return r.db.Create(item).Error
}

func (r *CategoryRepository) Update(item *models.Category) error {
    return r.db.Save(item).Error
}

func (r *CategoryRepository) Delete(id uint) error {
    return r.db.Delete(&models.Category{}, id).Error
}