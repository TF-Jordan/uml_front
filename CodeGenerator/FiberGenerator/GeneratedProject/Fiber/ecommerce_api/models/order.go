package models

import (
    "time"

)

type Order struct {



    ID uint `json:"id" gorm:"primaryKey;autoIncrement"`



    Number string `json:"number" gorm:"type:varchar(255)"`



    Status string `json:"status" gorm:"type:varchar(255)"`



    Totalamount float64 `json:"total_amount" gorm:"type:decimal(10,2)"`



    Placedat time.Time `json:"placed_at" gorm:"type:timestamp"`



    CreatedAt time.Time `json:"created_at" gorm:"autoCreateTime"`



    UpdatedAt time.Time `json:"updated_at" gorm:"autoUpdateTime"`


}

func (Order) TableName() string {
    return "order"
}

