package services

import (
    "ecommerce_api/models"
    "ecommerce_api/repositories"
)

type Order_itemService struct {
    repo *repositories.Order_itemRepository
}

func NewOrder_itemService(repo *repositories.Order_itemRepository) *Order_itemService {
    return &Order_itemService{repo: repo}
}

func (s *Order_itemService) GetAll() ([]models.Order_item, error) {
    return s.repo.FindAll()
}

func (s *Order_itemService) GetByID(id uint) (*models.Order_item, error) {
    return s.repo.FindByID(id)
}

func (s *Order_itemService) Create(item *models.Order_item) error {
    return s.repo.Create(item)
}

func (s *Order_itemService) Update(item *models.Order_item) error {
    return s.repo.Update(item)
}

func (s *Order_itemService) Delete(id uint) error {
    return s.repo.Delete(id)
}