package models

import (
    "time"

)

type Admin_user struct {



    ID uint `json:"id" gorm:"primaryKey;autoIncrement"`



    Issuperadmin bool `json:"is_super_admin" gorm:"type:boolean"`



    CreatedAt time.Time `json:"created_at" gorm:"autoCreateTime"`



    UpdatedAt time.Time `json:"updated_at" gorm:"autoUpdateTime"`


}

func (Admin_user) TableName() string {
    return "admin_user"
}

