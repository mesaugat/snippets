#!/bin/bash

set -e

###
#
# List of IAM users and their attached policies in AWS for a quick audit.
# Note: Doesn't include inline policies.
#
# Requirements: aws-cli, jq
#
# Usage:
#   ./aws-iam-user-policies.sh
#   ./aws-iam-user-policies.sh --profile something
#
# Output:
#   AWS IAM Users and Policies
#
#   | Username                                 | Policies
#   | etl_dev                                  | DevS3Policy
#   | etl_prod                                 | ProdS3Policy
#   | somebody_that_i_used_to_know             | IAMUserChangePassword - (g) AdministratorAccess
#
###

users=$(aws "$@" iam list-users | jq -r ".Users[].UserName")

if [ -z "${users}" ]; then
  printf "Your AWS account has no users. Woah! ¯\_(ツ)_/¯"

  exit 1
fi

printf "AWS IAM Users and Policies\n\n"
printf "| %-40s | %s \n" "Username" "Policies"

for user in $users; do
  policies=$(aws "$@" iam list-attached-user-policies --user-name "$user" | jq -r '.AttachedPolicies | map(.PolicyName) | join(", ")')
  user_groups=$(aws "$@" iam list-groups-for-user --user-name "$user" | jq -r '.Groups[].GroupName')
  group_policies=

  for group in $user_groups; do
    group_policies+=$(aws "$@" iam list-attached-group-policies --group-name "$group" | jq -r '.AttachedPolicies | map(.PolicyName) | join(", ")')

    if [ -n "$group_policies" ]; then
      group_policies+=", "
    fi
  done

  if [ -n "$policies" ] && [ -n "$group_policies" ]; then
    policies+=" - "
  fi

  if [ -n "$group_policies" ]; then
    policies+="(g) ${group_policies%??}"
  fi

  printf "| %-40s | %s\n" "$user" "$policies"
done
