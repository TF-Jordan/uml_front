package models

import (
    "time"

)

type User struct {



    ID string `json:"id" gorm:"primaryKey"`



    Email string `json:"email" gorm:"type:varchar(255)"`



    Passwordhash string `json:"password_hash" gorm:"type:varchar(255)"`



    Createdat time.Time `json:"created_at" gorm:"type:timestamp"`



    CreatedAt time.Time `json:"created_at" gorm:"autoCreateTime"`



    UpdatedAt time.Time `json:"updated_at" gorm:"autoUpdateTime"`


}

func (User) TableName() string {
    return "user"
}

