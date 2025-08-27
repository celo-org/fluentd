variable "gcp_provider_project" {
  type        = string
  description = "The project to connect to and store the state in"
}

variable "gcp_provider_region" {
  type        = string
  description = "The gcp region"
}

#variable "google_credentials" {
#  type        = string
#  description = "Google credentials from gh actions auth"
#}
#
#variable "access_id" {
#  type        = string
#  description = "akeyless access id"
#}
#
#variable "access_key" {
#  type        = string
#  description = "akeyless access key"
#  default     = ""
#}
#
#variable "api_gateway_address" {
#  type        = string
#  description = "akeyless api gateway"
#}
#
#variable "okta_org" {
#  type        = string
#  description = "okta organization (subdomain of okta url)"
#}
#
#variable "okta_base_url" {
#  type        = string
#  description = "okta url (okta.com or oktapreview.com usually)"
#}
#
#variable "okta_api_key_path" {
#  type        = string
#  description = "akeyless path to static secret for okta api key"
#}
#
#variable "okta_users" {
#  type        = any
#  description = "list of okta users"
#}
#
#variable "okta_group_rules" {
#  type        = map(map(string))
#  description = "list of okta group rules"
#}
#
#variable "okta_profiles" {
#  type        = any
#  description = "okta user profile attributes"
#  default     = {}
#}
#
#variable "email_group_rules" {
#  type        = any
#  description = "list of email group rules"
#}
variable "image" {
  type        = any
  description = "fluentd container image to deploy"
}
variable "instance_name" {
  type        = any
  description = "name of instance"
}
