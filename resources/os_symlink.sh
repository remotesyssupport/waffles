# == Name
#
# os.symlink
#
# === Description
#
# Manages symlinks
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the link. Required. namevar.
# * target: The target of the link.
#
# === Example
#
# ```shell
# os.symlink --name /usr/local/man --target /usr/share/man
# ```
#
function os.symlink {

  # Resource Options
  local -A options
  waffles.options.create_option state  "present"
  waffles.options.create_option name   "__required__"
  waffles.options.create_option target
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Internal Resource Configuration
  if [[ ${options[state]} != "absent" ]]; then
    if [[ -z ${options[target]} ]]; then
      log.error "target is required unless symlink is being removed."
    else
      if [[ ! -e ${options[target]} ]]; then
        log.error "${options[target]} does not exist."
        return 1
      fi
    fi
  fi

  # Process the resource
  waffles.resource.process "os.symlink" "${options[name]}"
}

function os.symlink.read {
  if [[ ! -e ${options[name]} ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  _stats=$(stat -c"%U:%G:%a:%F" "${options[name]}")
  string.split "$_stats" ':'
  _owner="${__split[0]}"
  _group="${__split[1]}"
  _mode="${__split[2]}"
  _type="${__split[3]}"

  if [[ $_type != "symbolic link" ]]; then
    log.error "${options[name]} exists and is not a symbolic link."
    waffles_resource_current_state="error"
    return
  fi

  waffles_resource_current_state="present"
}

function os.symlink.create {
  exec.capture_error ln -s "${options[target]}" "${options[name]}"
}

function os.symlink.update {
  os.symlink.delete
  os.symlink.create
}

function os.symlink.delete {
  exec.capture_error rm "${options[name]}"
}
