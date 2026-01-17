package repositories

import (


    "gorm.io/gorm"
    "ecommerce_api/models"
)

type Order_itemRepository struct {
    db *gorm.DB
}

func NewOrder_itemRepository(db *gorm.DB) *Order_itemRepository {
    return &Order_itemRepository{db: db}
}

func (r *Order_itemRepository) FindAll() ([]models.Order_item, error) {
    var items []models.Order_item
    result := r.db.Find(&items)
    return items, result.Error
}

func (r *Order_itemRepository) FindByID(id uint) (*models.Order_item, error) {
    var item models.Order_item
    result := r.db.First(&item, id)
    if result.Error != nil {
        return nil, result.Error
    }
    return &item, nil
}

func (r *Order_itemRepository) Create(item *models.Order_item) error {
    return r.db.Create(item).Error
}

func (r *Order_itemRepository) Update(item *models.Order_item) error {
    return r.db.Save(item).Error
}

func (r *Order_itemRepository) Delete(id uint) error {
    return r.db.Delete(&models.Order_item{}, id).Error
}