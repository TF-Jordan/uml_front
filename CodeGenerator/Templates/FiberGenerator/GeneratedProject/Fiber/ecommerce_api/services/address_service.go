package services

import (
    "ecommerce_api/models"
    "ecommerce_api/repositories"
)

type AddressService struct {
    repo *repositories.AddressRepository
}

func NewAddressService(repo *repositories.AddressRepository) *AddressService {
    return &AddressService{repo: repo}
}

func (s *AddressService) GetAll() ([]models.Address, error) {
    return s.repo.FindAll()
}

func (s *AddressService) GetByID(id uint) (*models.Address, error) {
    return s.repo.FindByID(id)
}

func (s *AddressService) Create(item *models.Address) error {
    return s.repo.Create(item)
}

func (s *AddressService) Update(item *models.Address) error {
    return s.repo.Update(item)
}

func (s *AddressService) Delete(id uint) error {
    return s.repo.Delete(id)
}