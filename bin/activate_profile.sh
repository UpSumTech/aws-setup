#!/usr/bin/env bash

all_available_profiles() {
  local profiles=( \
    "admin" \
    "superuser" \
    "developer" \
  )
  echo "${profiles[@]}"
}

which_profile_is_active() {
  if [[ ! -z "$CURRENT_PROFILE" ]]; then
    echo "Current active profile is $CURRENT_PROFILE"
  else
    echo "No currently active profile"
  fi
}

clean_active_profile() {
  case $CURRENT_PROFILE in
  developer)
    deactivate_profile_for_developer
    echo "Unset current profile from developer"
    ;;
  admin)
    deactivate_profile_for_admin
    echo "Unset current profile from admin"
    ;;
  superuser)
    deactivate_profile_for_superuser
    echo "Unset current profile from superuser"
    ;;
  *)
    echo "No valid profile currently active"
    ;;
  esac
}

activate_profile_for_developer() {
  clean_active_profile
  export AWS_ACCESS_KEY_ID="$DEVELOPER_AWS_ACCESS_KEY_ID"
  export AWS_SECRET_ACCESS_KEY="$DEVELOPER_AWS_SECRET_ACCESS_KEY"
  export AWS_ACCOUNT_ID="$DEVELOPER_AWS_ACCOUNT_ID"
  export AWS_ACCESS_KEY="$DEVELOPER_AWS_ACCESS_KEY_ID"
  export AWS_SECRET_KEY="$DEVELOPER_AWS_SECRET_ACCESS_KEY"
  activate_profile_helper "developer"
}

deactivate_profile_for_developer() {
  deactivate_profile_helper
}

activate_profile_for_admin() {
  clean_active_profile
  export AWS_ACCESS_KEY_ID="$ADMIN_AWS_ACCESS_KEY_ID"
  export AWS_SECRET_ACCESS_KEY="$ADMIN_AWS_SECRET_ACCESS_KEY"
  export AWS_ACCOUNT_ID="$ADMIN_AWS_ACCOUNT_ID"
  export AWS_ACCESS_KEY="$ADMIN_AWS_ACCESS_KEY_ID"
  export AWS_SECRET_KEY="$ADMIN_AWS_SECRET_ACCESS_KEY"
  activate_profile_helper "admin"
}

deactivate_profile_for_admin() {
  deactivate_profile_helper
}

activate_profile_for_superuser() {
  clean_active_profile
  export AWS_ACCESS_KEY_ID="$SUPERUSER_AWS_ACCESS_KEY_ID"
  export AWS_SECRET_ACCESS_KEY="$SUPERUSER_AWS_SECRET_ACCESS_KEY"
  export AWS_ACCOUNT_ID="$SUPERUSER_AWS_ACCOUNT_ID"
  export AWS_ACCESS_KEY="$SUPERUSER_AWS_ACCESS_KEY_ID"
  export AWS_SECRET_KEY="$SUPERUSER_AWS_SECRET_ACCESS_KEY"
  activate_profile_helper "superuser"
}

deactivate_profile_for_superuser() {
  deactivate_profile_helper
}

activate_profile_helper() {
  export CURRENT_PROFILE="$1"
  echo "Set current profile to $CURRENT_PROFILE"
}

deactivate_profile_helper() {
  unset CURRENT_PROFILE
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_ACCOUNT_ID
}

activate_help() {
  echo "
    Valid profiles are : $(_all_available_profiles)
    Valid options for calling acivate profile are
      activate_profile_for_developer
      deactivate_profile_for_developer
      activate_profile_for_admin
      deactivate_profile_for_admin
      activate_profile_for_superuser
      deactivate_profile_for_superuser
      activate_help
      all_available_profiles
      clean_active_profile
  "
}
