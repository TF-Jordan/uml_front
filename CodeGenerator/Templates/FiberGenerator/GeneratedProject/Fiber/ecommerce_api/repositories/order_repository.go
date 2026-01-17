package repositories

import (


    "gorm.io/gorm"
    "ecommerce_api/models"
)

type OrderRepository struct {
    db *gorm.DB
}

func NewOrderRepository(db *gorm.DB) *OrderRepository {
    return &OrderRepository{db: db}
}

func (r *OrderRepository) FindAll() ([]models.Order, error) {
    var items []models.Order
    result := r.db.Find(&items)
    return items, result.Error
}

func (r *OrderRepository) FindByID(id uint) (*models.Order, error) {
    var item models.Order
    result := r.db.First(&item, id)
    if result.Error != nil {
        return nil, result.Error
    }
    return &item, nil
}

func (r *OrderRepository) Create(item *models.Order) error {
    return r.db.Create(item).Error
}

func (r *OrderRepository) Update(item *models.Order) error {
    return r.db.Save(item).Error
}

func (r *OrderRepository) Delete(id uint) error {
    return r.db.Delete(&models.Order{}, id).Error
}