package services

import (
    "ecommerce_api/models"
    "ecommerce_api/repositories"
)

type OrderService struct {
    repo *repositories.OrderRepository
}

func NewOrderService(repo *repositories.OrderRepository) *OrderService {
    return &OrderService{repo: repo}
}

func (s *OrderService) GetAll() ([]models.Order, error) {
    return s.repo.FindAll()
}

func (s *OrderService) GetByID(id uint) (*models.Order, error) {
    return s.repo.FindByID(id)
}

func (s *OrderService) Create(item *models.Order) error {
    return s.repo.Create(item)
}

func (s *OrderService) Update(item *models.Order) error {
    return s.repo.Update(item)
}

func (s *OrderService) Delete(id uint) error {
    return s.repo.Delete(id)
}