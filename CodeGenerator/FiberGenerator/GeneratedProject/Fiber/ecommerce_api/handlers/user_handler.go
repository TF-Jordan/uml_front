package handlers

import (
    "github.com/gofiber/fiber/v2"
    "ecommerce_api/models"
    "ecommerce_api/services"

)

type UserHandler struct {
    service *services.UserService
}

func NewUserHandler(service *services.UserService) *UserHandler {
    return &UserHandler{service: service}
}

// Get all
func (h *UserHandler) GetAll(c *fiber.Ctx) error {
    items, err := h.service.GetAll()
    if err != nil {
        return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
    }
    return c.JSON(items)
}

// Get by ID
func (h *UserHandler) GetByID(c *fiber.Ctx) error {
    idParam := c.Params("id")
    var id string

    id = idParam


    item, err := h.service.GetByID(id)
    if err != nil {
        return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "User not found"})
    }
    return c.JSON(item)
}

// Create
func (h *UserHandler) Create(c *fiber.Ctx) error {
    var item models.User
    if err := c.BodyParser(&item); err != nil {
        return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
    }
    if err := h.service.Create(&item); err != nil {
        return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
    }
    return c.Status(fiber.StatusCreated).JSON(item)
}

// Update
func (h *UserHandler) Update(c *fiber.Ctx) error {
    idParam := c.Params("id")
    var id string

    id = idParam


    var item models.User
    if err := c.BodyParser(&item); err != nil {
        return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
    }
    item.ID = id

    if err := h.service.Update(&item); err != nil {
        return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
    }
    return c.JSON(item)
}

// Delete
func (h *UserHandler) Delete(c *fiber.Ctx) error {
    idParam := c.Params("id")
    var id string

    id = idParam


    if err := h.service.Delete(id); err != nil {
        return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
    }
    return c.SendStatus(fiber.StatusNoContent)
}