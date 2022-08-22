#!/bin/sh

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

setup_trap_handler() {
  # shellcheck disable=SC2124
  trap "finish $1 $2" EXIT
}

finish() {
  # This function executes on exit and destroys the working project
  echo "rc=$rc"
  echo $1 $2
  echo SAP_STATE=absent ansible-playbook -v "$1" -e @"$2"
  SAP_STATE=absent ansible-playbook -v "$1" -e @"$2"
  echo ansible-playbook -vv cloud_build_deployment/setup-playbooks/destroy-ssh-bastion.yaml -e @"$2"
  ansible-playbook -vv cloud_build_deployment/setup-playbooks/destroy-ssh-bastion.yaml -e @"$2"

  mkdir -p /workspace/.results
  # In case of the passing test we just log the results
  if [ $rc = "0" ]; then
    echo $rc > /workspace/.results/$SAP_TEST_ID
    ls -l /workspace/.results/
  # In case of the failing test we keep waiting until all the tests are executed
  else
    echo $rc > /workspace/.results/$SAP_TEST_ID
    ls -l /workspace/.results/
    total_tests_completed=$(ls /workspace/results/|wc -l)
    while [ $total_tests_completed -lt $TOTAL_TESTS ]
    do
      echo "Waiting for the rest of the tests to finish"
      sleep 10
      total_tests_completed=$(ls /workspace/results/|wc -l)
    done
  fi

}
# shellcheck disable=SC2068
setup_trap_handler $1 $2

#mkdir -p $TF_PLUGIN_CACHE_DIR
unset TF_PLUGIN_CACHE_DIR

rc=0 # return code for ansible playbook

echo ansible-playbook -vv cloud_build_deployment/setup-playbooks/setup-container.yaml -e @"$2"
ansible-playbook -vv cloud_build_deployment/setup-playbooks/setup-container.yaml -e @"$2"
pwd
env
rc=$?
if [ "$rc" != "0" ]; then
  exit $rc
fi

if [ -z "$3" ]; then
  retry=1;
else
  retry=$3
fi
# retry playbook in case of a failure
for i in $(seq 1 $retry); do
  echo ansible-playbook "$1" -e @"$2"
  # shellcheck disable=SC2068
  ansible-playbook -v "$1" -e @"$2"
  rc=$?
  echo "##################################################################################"
  echo "####################### rc=$rc" "try=$i ##############################################"
  echo "##################################################################################"
  echo ""
  if [ "$rc" = "0" ]; then
    break
  fi
done

exit $rc