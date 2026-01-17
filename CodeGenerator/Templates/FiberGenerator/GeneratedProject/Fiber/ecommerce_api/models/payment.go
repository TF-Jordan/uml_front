package models

import (
    "time"

)

type Payment struct {



    ID uint `json:"id" gorm:"primaryKey;autoIncrement"`



    Reference string `json:"reference" gorm:"type:varchar(255)"`



    Method string `json:"method" gorm:"type:varchar(255)"`



    Paidat time.Time `json:"paid_at" gorm:"type:timestamp"`



    Amount float64 `json:"amount" gorm:"type:decimal(10,2)"`



    CreatedAt time.Time `json:"created_at" gorm:"autoCreateTime"`



    UpdatedAt time.Time `json:"updated_at" gorm:"autoUpdateTime"`


}

func (Payment) TableName() string {
    return "payment"
}

