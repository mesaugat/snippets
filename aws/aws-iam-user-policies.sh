#!/bin/bash

set -e

###
# List of IAM users and their attached policies in AWS for a quick audit.
# Note: Doesn't include inline policies.
#
# Requirements: aws-cli, jq
#
# Usage:
#   ./aws-iam-user-policies.sh
#
# Output:
#   AWS IAM Users and Policies
#
#   | Username                                 | Policies
#   | etl_dev                                  | etl_dev_s3_policy
#   | etl_prod                                 | etl_prod_s3_policy
#   | somebody_that_i_used_to_know             | IAMUserChangePassword - (g) AdministratorAccess
###

users=$(aws iam list-users | jq -r ".Users[].UserName")

if [ -z "${users}" ]; then
  printf "Your AWS account no users. Woah! ¯\_(ツ)_/¯"

  exit 1
fi

printf "AWS IAM Users and Policies\n\n"
printf "| %-40s | %s \n" "Username" "Policies"

for user in $users; do
  policies=$(aws iam list-attached-user-policies --user-name "$user" | jq -r '.AttachedPolicies | map(.PolicyName) | join(", ")')
  user_groups=$(aws iam list-groups-for-user --user-name "$user" | jq -r '.Groups[].GroupName')
  group_policies=

  for group in $user_groups; do
    group_policies+=$(aws iam list-attached-group-policies --group-name "$group" | jq -r ".AttachedPolicies[].PolicyName")
    group_policies+=", "
  done

  if [ -n "$group_policies" ]; then
    policies+=" - (g) ${group_policies%??}"
  fi

  printf "| %-40s | %s\n" "$user" "$policies"
done