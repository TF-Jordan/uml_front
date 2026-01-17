package services

import (
    "ecommerce_api/models"
    "ecommerce_api/repositories"
)

type Admin_userService struct {
    repo *repositories.Admin_userRepository
}

func NewAdmin_userService(repo *repositories.Admin_userRepository) *Admin_userService {
    return &Admin_userService{repo: repo}
}

func (s *Admin_userService) GetAll() ([]models.Admin_user, error) {
    return s.repo.FindAll()
}

func (s *Admin_userService) GetByID(id uint) (*models.Admin_user, error) {
    return s.repo.FindByID(id)
}

func (s *Admin_userService) Create(item *models.Admin_user) error {
    return s.repo.Create(item)
}

func (s *Admin_userService) Update(item *models.Admin_user) error {
    return s.repo.Update(item)
}

func (s *Admin_userService) Delete(id uint) error {
    return s.repo.Delete(id)
}