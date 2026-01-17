package services

import (
    "ecommerce_api/models"
    "ecommerce_api/repositories"
)

type ProductService struct {
    repo *repositories.ProductRepository
}

func NewProductService(repo *repositories.ProductRepository) *ProductService {
    return &ProductService{repo: repo}
}

func (s *ProductService) GetAll() ([]models.Product, error) {
    return s.repo.FindAll()
}

func (s *ProductService) GetByID(id uint) (*models.Product, error) {
    return s.repo.FindByID(id)
}

func (s *ProductService) Create(item *models.Product) error {
    return s.repo.Create(item)
}

func (s *ProductService) Update(item *models.Product) error {
    return s.repo.Update(item)
}

func (s *ProductService) Delete(id uint) error {
    return s.repo.Delete(id)
}