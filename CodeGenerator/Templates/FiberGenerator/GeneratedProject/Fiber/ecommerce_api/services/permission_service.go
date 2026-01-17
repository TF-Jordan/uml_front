package services

import (
    "ecommerce_api/models"
    "ecommerce_api/repositories"
)

type PermissionService struct {
    repo *repositories.PermissionRepository
}

func NewPermissionService(repo *repositories.PermissionRepository) *PermissionService {
    return &PermissionService{repo: repo}
}

func (s *PermissionService) GetAll() ([]models.Permission, error) {
    return s.repo.FindAll()
}

func (s *PermissionService) GetByID(id uint) (*models.Permission, error) {
    return s.repo.FindByID(id)
}

func (s *PermissionService) Create(item *models.Permission) error {
    return s.repo.Create(item)
}

func (s *PermissionService) Update(item *models.Permission) error {
    return s.repo.Update(item)
}

func (s *PermissionService) Delete(id uint) error {
    return s.repo.Delete(id)
}