variable "db_username" {
  type        = string
  sensitive = true
  description = "Username of the database"

}

variable "db_password" {
    description = "The password for the database"
    type = string 
    sensitive = true
}