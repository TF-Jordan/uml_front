package models

import (
    "time"

)

type Permission struct {



    ID uint `json:"id" gorm:"primaryKey;autoIncrement"`



    Name string `json:"name" gorm:"type:varchar(255)"`



    Description string `json:"description" gorm:"type:varchar(255)"`



    CreatedAt time.Time `json:"created_at" gorm:"autoCreateTime"`



    UpdatedAt time.Time `json:"updated_at" gorm:"autoUpdateTime"`


}

func (Permission) TableName() string {
    return "permission"
}

