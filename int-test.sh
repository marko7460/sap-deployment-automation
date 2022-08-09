#!/bin/bash

# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#set -u
set -e

setup_trap_handler() {
  # shellcheck disable=SC2124
  trap "finish $1" ERR
}

finish() {
  # This function executes on exit and destroys the working project
  echo "Error deploying test-setup"
  project_id=$(terraform -chdir="$1" output -raw project_id)
  gcloud projects delete "$project_id" --quiet
}

stack_dir="stacks/$1"
setup_directory="$stack_dir/test-setup"
cloudbuild_config="$stack_dir/cloudbuild.yaml"
playbook="$stack_dir/playbook.yml"
# shellcheck disable=SC2068
setup_trap_handler $setup_directory

#mkdir -p $TF_PLUGIN_CACHE_DIR
unset TF_PLUGIN_CACHE_DIR
terraform -chdir="${setup_directory}" init
terraform -chdir="${setup_directory}" apply -auto-approve

playbook_vars="${setup_directory}/vars.yml"
cat $playbook_vars
#gcloud builds submit --config ${cloudbuild_config} --substitutions _ANSIBLE_PLAYBOOK=$playbook,_ANSIBLE_VARIABLES=$playbook_vars .
