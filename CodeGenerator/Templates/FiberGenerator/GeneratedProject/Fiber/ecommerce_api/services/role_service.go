package services

import (
    "ecommerce_api/models"
    "ecommerce_api/repositories"
)

type RoleService struct {
    repo *repositories.RoleRepository
}

func NewRoleService(repo *repositories.RoleRepository) *RoleService {
    return &RoleService{repo: repo}
}

func (s *RoleService) GetAll() ([]models.Role, error) {
    return s.repo.FindAll()
}

func (s *RoleService) GetByID(id uint) (*models.Role, error) {
    return s.repo.FindByID(id)
}

func (s *RoleService) Create(item *models.Role) error {
    return s.repo.Create(item)
}

func (s *RoleService) Update(item *models.Role) error {
    return s.repo.Update(item)
}

func (s *RoleService) Delete(id uint) error {
    return s.repo.Delete(id)
}