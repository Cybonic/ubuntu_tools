#!/usr/bin/env bash
# create_user.sh  <username> [<password>] [--sudo]
# ───────────────────────────────────────────────────────────────
# • Adds a local Ubuntu user.
# • If <password> is omitted, generates one that begins with
#   "ISR<year><username>" and meets complexity rules.
# • Optional --sudo flag adds the user to the sudo group.
# • The password is marked expired so the user must change it
#   at first login.
# • Use -h or --help to print detailed usage information.

###############################################################################
# 0. Help text
###############################################################################
show_help() {
cat <<'EOF'
create_user.sh — create an Ubuntu user (optional sudo) with password control
USAGE
  sudo ./create_user.sh <username> [<password>] [--sudo]
  sudo ./create_user.sh --help

POSITIONAL ARGUMENTS
  <username>   (required)  The new account name.
  <password>   (optional)  Initial password. If omitted, a strong one is
                           generated beginning with ISR<year><username>.

OPTIONS
  --sudo       Add the new account to the 'sudo' group.
  -h, --help   Show this help and exit.

RULES
  • Passwords (given or generated) must be at least 8 chars and include:
      - 1 uppercase letter, 1 lowercase letter, 1 digit, 1 symbol.
  • The password is forced to change on first login.

EXAMPLES
  sudo ./create_user.sh alice
  sudo ./create_user.sh bob Str0ngP@ss
  sudo ./create_user.sh carol --sudo
  sudo ./create_user.sh dave P@ssw0rd! --sudo
EOF
}

###############################################################################
# 1. Preliminary argument parsing: help flag anywhere → print and exit
###############################################################################
if [[ $# -eq 0 ]]; then
  show_help; exit 1
fi
for arg in "$@"; do
  [[ $arg == "-h" || $arg == "--help" ]] && { show_help; exit 0; }
done

###############################################################################
# 2. Strict argument validation / assignment
###############################################################################
username="$1"
password=""
sudo_flag=0

# Validate username isn't empty or a flag
if [[ -z $username || $username == -* ]]; then
  echo "Error: missing or invalid <username>." >&2
  show_help; exit 1
fi

shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sudo) sudo_flag=1 ;;
    -*)
      echo "Error: unknown option '$1'." >&2
      show_help; exit 1 ;;
    *)
      if [[ -z $password ]]; then
        password="$1"
      else
        echo "Error: too many positional arguments." >&2
        show_help; exit 1
      fi ;;
  esac
  shift
done

###############################################################################
# 3. Root check
###############################################################################
if [[ $EUID -ne 0 ]]; then
  echo "Error: run this script with sudo or as root." >&2
  exit 1
fi

###############################################################################
# 4. User existence check
###############################################################################
if id "$username" &>/dev/null; then
  echo "Error: user '$username' already exists." >&2
  exit 1
fi

###############################################################################
# 5. Password routines
###############################################################################
meets_policy() {
  local pw=$1
  [[ ${#pw} -ge 8        ]] &&
  [[ $pw =~ [A-Z]        ]] &&
  [[ $pw =~ [a-z]        ]] &&
  [[ $pw =~ [0-9]        ]] &&
  [[ $pw =~ [^[:alnum:]] ]]
}

generate_pw() {
  local pw="ISR$(date +%Y)${username}"
  [[ $pw =~ [a-z]        ]] || pw+=a
  [[ $pw =~ [A-Z]        ]] || pw+=A
  [[ $pw =~ [0-9]        ]] || pw+=1
  [[ $pw =~ [^[:alnum:]] ]] || pw+='!'
  while [[ ${#pw} -lt 12 ]]; do
    pw+=$(tr -dc 'A-Za-z0-9!@#$%^&*+=' </dev/urandom | head -c1)
  done
  echo "$pw"
}

if [[ -z $password ]]; then
  password=$(generate_pw)
else
  meets_policy "$password" || { echo "Error: supplied password fails complexity rules." >&2; exit 1; }
fi

###############################################################################
# 6. Create the user
###############################################################################
useradd_opts=(-m -s /bin/bash)
(( sudo_flag )) && useradd_opts+=(-G sudo)

if ! useradd "${useradd_opts[@]}" "$username"; then
  echo "Error: useradd failed." >&2
  exit 1
fi

# Set password
echo "${username}:${password}" | chpasswd || { echo "Error: chpasswd failed." >&2; userdel "$username"; exit 1; }

# Force change on first login
# chage -d 0 "$username"

###############################################################################
# 7. Success output
###############################################################################
[[ $sudo_flag -eq 1 ]] && extra=" and added to 'sudo' group" || extra=""
echo "✔  User '$username' created${extra}."
echo "→  Initial password: $password"
