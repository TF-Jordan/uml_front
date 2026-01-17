package handlers

import (
    "github.com/gofiber/fiber/v2"
    "ecommerce_api/models"
    "ecommerce_api/services"

    "strconv"

)

type RoleHandler struct {
    service *services.RoleService
}

func NewRoleHandler(service *services.RoleService) *RoleHandler {
    return &RoleHandler{service: service}
}

// Get all
func (h *RoleHandler) GetAll(c *fiber.Ctx) error {
    items, err := h.service.GetAll()
    if err != nil {
        return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
    }
    return c.JSON(items)
}

// Get by ID
func (h *RoleHandler) GetByID(c *fiber.Ctx) error {
    idParam := c.Params("id")
    var id uint

    id64, err := strconv.ParseUint(idParam, 10, 64)
    if err != nil {
        return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
    }
    id = uint(id64)


    item, err := h.service.GetByID(id)
    if err != nil {
        return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Role not found"})
    }
    return c.JSON(item)
}

// Create
func (h *RoleHandler) Create(c *fiber.Ctx) error {
    var item models.Role
    if err := c.BodyParser(&item); err != nil {
        return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
    }
    if err := h.service.Create(&item); err != nil {
        return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
    }
    return c.Status(fiber.StatusCreated).JSON(item)
}

// Update
func (h *RoleHandler) Update(c *fiber.Ctx) error {
    idParam := c.Params("id")
    var id uint

    id64, err := strconv.ParseUint(idParam, 10, 64)
    if err != nil {
        return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
    }
    id = uint(id64)


    var item models.Role
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
func (h *RoleHandler) Delete(c *fiber.Ctx) error {
    idParam := c.Params("id")
    var id uint

    id64, err := strconv.ParseUint(idParam, 10, 64)
    if err != nil {
        return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
    }
    id = uint(id64)


    if err := h.service.Delete(id); err != nil {
        return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
    }
    return c.SendStatus(fiber.StatusNoContent)
}