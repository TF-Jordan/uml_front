package models

import (
    "time"

)

type Category struct {



    ID uint `json:"id" gorm:"primaryKey;autoIncrement"`



    Name string `json:"name" gorm:"type:varchar(255)"`



    Parentid string `json:"parent_id" gorm:"type:varchar(255)"`



    CreatedAt time.Time `json:"created_at" gorm:"autoCreateTime"`



    UpdatedAt time.Time `json:"updated_at" gorm:"autoUpdateTime"`


}

func (Category) TableName() string {
    return "category"
}

