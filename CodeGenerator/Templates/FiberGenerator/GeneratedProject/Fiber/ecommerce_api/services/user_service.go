package services

import (
    "ecommerce_api/models"
    "ecommerce_api/repositories"
)

type UserService struct {
    repo *repositories.UserRepository
}

func NewUserService(repo *repositories.UserRepository) *UserService {
    return &UserService{repo: repo}
}

func (s *UserService) GetAll() ([]models.User, error) {
    return s.repo.FindAll()
}

func (s *UserService) GetByID(id string) (*models.User, error) {
    return s.repo.FindByID(id)
}

func (s *UserService) Create(item *models.User) error {
    return s.repo.Create(item)
}

func (s *UserService) Update(item *models.User) error {
    return s.repo.Update(item)
}

func (s *UserService) Delete(id string) error {
    return s.repo.Delete(id)
}