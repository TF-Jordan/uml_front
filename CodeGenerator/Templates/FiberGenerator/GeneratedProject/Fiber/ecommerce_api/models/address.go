package models

import (
    "time"

)

type Address struct {



    ID uint `json:"id" gorm:"primaryKey;autoIncrement"`



    Line1 string `json:"line1" gorm:"type:varchar(255)"`



    City string `json:"city" gorm:"type:varchar(255)"`



    Postalcode string `json:"postal_code" gorm:"type:varchar(255)"`



    Country string `json:"country" gorm:"type:varchar(255)"`



    CreatedAt time.Time `json:"created_at" gorm:"autoCreateTime"`



    UpdatedAt time.Time `json:"updated_at" gorm:"autoUpdateTime"`


}

func (Address) TableName() string {
    return "address"
}

