############################################
# WAF v2 Web ACL for CloudFront (Complete)
############################################

resource "aws_wafv2_web_acl" "cf" {
  provider = aws.use1

  name  = "cf-waf"
  scope = "CLOUDFRONT"

  ##########################################
  # Default Action
  ##########################################
  default_action {
    allow {}
  }

  ##########################################
  # 1. Core Rule Set (OWASP Top 10)
  ##########################################
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common"
      sampled_requests_enabled   = true
    }
  }

  ##########################################
  # 2. SQL Injection Protection
  ##########################################
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "sqli"
      sampled_requests_enabled   = true
    }
  }

  ##########################################
  # 3. Known Bad Inputs
  ##########################################
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "knownbad"
      sampled_requests_enabled   = true
    }
  }

  ##########################################
  # 4. Amazon IP Reputation List
  ##########################################
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ipreputation"
      sampled_requests_enabled   = true
    }
  }

  ##########################################
  # Web ACL Visibility Config
  ##########################################
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cf-waf"
    sampled_requests_enabled   = true
  }
}
