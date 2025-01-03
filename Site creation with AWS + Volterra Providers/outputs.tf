#token value is sent as an output to the screen for troubleshooting if any issues. 
output "awstokenid" {
  value = volterra_token.smsv2-token.id
}
