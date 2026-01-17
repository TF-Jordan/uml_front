package services

import (
    "ecommerce_api/models"
    "ecommerce_api/repositories"
)

type PaymentService struct {
    repo *repositories.PaymentRepository
}

func NewPaymentService(repo *repositories.PaymentRepository) *PaymentService {
    return &PaymentService{repo: repo}
}

func (s *PaymentService) GetAll() ([]models.Payment, error) {
    return s.repo.FindAll()
}

func (s *PaymentService) GetByID(id uint) (*models.Payment, error) {
    return s.repo.FindByID(id)
}

func (s *PaymentService) Create(item *models.Payment) error {
    return s.repo.Create(item)
}

func (s *PaymentService) Update(item *models.Payment) error {
    return s.repo.Update(item)
}

func (s *PaymentService) Delete(id uint) error {
    return s.repo.Delete(id)
}