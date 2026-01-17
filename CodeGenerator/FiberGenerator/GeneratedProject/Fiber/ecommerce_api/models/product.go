package models

import (
    "time"

)

type Product struct {



    ID uint `json:"id" gorm:"primaryKey;autoIncrement"`



    Sku string `json:"sku" gorm:"type:varchar(255)"`



    Label string `json:"label" gorm:"type:varchar(255)"`



    Unitprice float64 `json:"unit_price" gorm:"type:decimal(10,2)"`



    Stockquantity int `json:"stock_quantity" gorm:"type:int"`



    CreatedAt time.Time `json:"created_at" gorm:"autoCreateTime"`



    UpdatedAt time.Time `json:"updated_at" gorm:"autoUpdateTime"`


}

func (Product) TableName() string {
    return "product"
}

