package models

import (
    "time"

)

type Order_item struct {



    ID uint `json:"id" gorm:"primaryKey;autoIncrement"`



    Quantity int `json:"quantity" gorm:"type:int"`



    Unitprice float64 `json:"unit_price" gorm:"type:decimal(10,2)"`



    CreatedAt time.Time `json:"created_at" gorm:"autoCreateTime"`



    UpdatedAt time.Time `json:"updated_at" gorm:"autoUpdateTime"`


}

func (Order_item) TableName() string {
    return "order_item"
}

