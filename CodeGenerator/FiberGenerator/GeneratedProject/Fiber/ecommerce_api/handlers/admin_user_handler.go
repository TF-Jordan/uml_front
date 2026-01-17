package handlers

import (
    "github.com/gofiber/fiber/v2"
    "ecommerce_api/models"
    "ecommerce_api/services"

    "strconv"

)

type Admin_userHandler struct {
    service *services.Admin_userService
}

func NewAdmin_userHandler(service *services.Admin_userService) *Admin_userHandler {
    return &Admin_userHandler{service: service}
}

// Get all
func (h *Admin_userHandler) GetAll(c *fiber.Ctx) error {
    items, err := h.service.GetAll()
    if err != nil {
        return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
    }
    return c.JSON(items)
}

// Get by ID
func (h *Admin_userHandler) GetByID(c *fiber.Ctx) error {
    idParam := c.Params("id")
    var id uint

    id64, err := strconv.ParseUint(idParam, 10, 64)
    if err != nil {
        return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
    }
    id = uint(id64)


    item, err := h.service.GetByID(id)
    if err != nil {
        return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Admin_user not found"})
    }
    return c.JSON(item)
}

// Create
func (h *Admin_userHandler) Create(c *fiber.Ctx) error {
    var item models.Admin_user
    if err := c.BodyParser(&item); err != nil {
        return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
    }
    if err := h.service.Create(&item); err != nil {
        return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
    }
    return c.Status(fiber.StatusCreated).JSON(item)
}

// Update
func (h *Admin_userHandler) Update(c *fiber.Ctx) error {
    idParam := c.Params("id")
    var id uint

    id64, err := strconv.ParseUint(idParam, 10, 64)
    if err != nil {
        return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
    }
    id = uint(id64)


    var item models.Admin_user
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
func (h *Admin_userHandler) Delete(c *fiber.Ctx) error {
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