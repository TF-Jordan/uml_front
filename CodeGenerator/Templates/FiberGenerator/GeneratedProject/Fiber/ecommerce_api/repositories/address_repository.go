package repositories

import (


    "gorm.io/gorm"
    "ecommerce_api/models"
)

type AddressRepository struct {
    db *gorm.DB
}

func NewAddressRepository(db *gorm.DB) *AddressRepository {
    return &AddressRepository{db: db}
}

func (r *AddressRepository) FindAll() ([]models.Address, error) {
    var items []models.Address
    result := r.db.Find(&items)
    return items, result.Error
}

func (r *AddressRepository) FindByID(id uint) (*models.Address, error) {
    var item models.Address
    result := r.db.First(&item, id)
    if result.Error != nil {
        return nil, result.Error
    }
    return &item, nil
}

func (r *AddressRepository) Create(item *models.Address) error {
    return r.db.Create(item).Error
}

func (r *AddressRepository) Update(item *models.Address) error {
    return r.db.Save(item).Error
}

func (r *AddressRepository) Delete(id uint) error {
    return r.db.Delete(&models.Address{}, id).Error
}