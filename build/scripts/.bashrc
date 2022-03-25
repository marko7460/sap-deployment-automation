PS1='[\u@\h \W]\$ '

if [[ -z "${CFT_DISABLE_INIT_CREDENTIALS:-}" ]]; then
  echo 'Loading /usr/local/bin/task_helper_functions.sh from ~/.bashrc' >&2
  # shellcheck disable=1091
  source /usr/local/bin/task_helper_functions.sh
  #echo 'Invoking init_credentials from ~/.bashrc' >&2
  #echo 'Disable this behavior by setting CFT_DISABLE_INIT_CREDENTIALS=yes' >&2
  init_tf_plugin_cache
  #init_credentials
fi