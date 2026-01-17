package repositories

import (


    "gorm.io/gorm"
    "ecommerce_api/models"
)

type PaymentRepository struct {
    db *gorm.DB
}

func NewPaymentRepository(db *gorm.DB) *PaymentRepository {
    return &PaymentRepository{db: db}
}

func (r *PaymentRepository) FindAll() ([]models.Payment, error) {
    var items []models.Payment
    result := r.db.Find(&items)
    return items, result.Error
}

func (r *PaymentRepository) FindByID(id uint) (*models.Payment, error) {
    var item models.Payment
    result := r.db.First(&item, id)
    if result.Error != nil {
        return nil, result.Error
    }
    return &item, nil
}

func (r *PaymentRepository) Create(item *models.Payment) error {
    return r.db.Create(item).Error
}

func (r *PaymentRepository) Update(item *models.Payment) error {
    return r.db.Save(item).Error
}

func (r *PaymentRepository) Delete(id uint) error {
    return r.db.Delete(&models.Payment{}, id).Error
}