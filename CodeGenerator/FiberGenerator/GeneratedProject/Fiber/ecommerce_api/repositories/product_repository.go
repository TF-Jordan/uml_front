package repositories

import (


    "gorm.io/gorm"
    "ecommerce_api/models"
)

type ProductRepository struct {
    db *gorm.DB
}

func NewProductRepository(db *gorm.DB) *ProductRepository {
    return &ProductRepository{db: db}
}

func (r *ProductRepository) FindAll() ([]models.Product, error) {
    var items []models.Product
    result := r.db.Find(&items)
    return items, result.Error
}

func (r *ProductRepository) FindByID(id uint) (*models.Product, error) {
    var item models.Product
    result := r.db.First(&item, id)
    if result.Error != nil {
        return nil, result.Error
    }
    return &item, nil
}

func (r *ProductRepository) Create(item *models.Product) error {
    return r.db.Create(item).Error
}

func (r *ProductRepository) Update(item *models.Product) error {
    return r.db.Save(item).Error
}

func (r *ProductRepository) Delete(id uint) error {
    return r.db.Delete(&models.Product{}, id).Error
}