package models

import (
    "time"

)

type Role struct {



    ID uint `json:"id" gorm:"primaryKey;autoIncrement"`



    Code string `json:"code" gorm:"type:varchar(255)"`



    Label string `json:"label" gorm:"type:varchar(255)"`



    CreatedAt time.Time `json:"created_at" gorm:"autoCreateTime"`



    UpdatedAt time.Time `json:"updated_at" gorm:"autoUpdateTime"`


}

func (Role) TableName() string {
    return "role"
}

