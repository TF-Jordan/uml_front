package services

import (
    "ecommerce_api/models"
    "ecommerce_api/repositories"
)

type CategoryService struct {
    repo *repositories.CategoryRepository
}

func NewCategoryService(repo *repositories.CategoryRepository) *CategoryService {
    return &CategoryService{repo: repo}
}

func (s *CategoryService) GetAll() ([]models.Category, error) {
    return s.repo.FindAll()
}

func (s *CategoryService) GetByID(id uint) (*models.Category, error) {
    return s.repo.FindByID(id)
}

func (s *CategoryService) Create(item *models.Category) error {
    return s.repo.Create(item)
}

func (s *CategoryService) Update(item *models.Category) error {
    return s.repo.Update(item)
}

func (s *CategoryService) Delete(id uint) error {
    return s.repo.Delete(id)
}