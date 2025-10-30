#!/usr/bin/env bash

# Script para APAGAR um utilizador em todas as máquinas
if [[ $# -ne 1 ]]; then
  echo "Usage: sudo $0 <username_to_delete>"
  exit 1
fi

USERNAME=$1
SERVERS=("sol" "terra" "marte" "venus")
REMOTE_USER="admin" #utilizador admin

# Apagar o utilizador localmente (no lua)
echo "A apagar o utilizador $USERNAME localmente (no lua)..."
if ! sudo userdel -r "$USERNAME"; then
  echo "Aviso: Não foi possível apagar o utilizador $USERNAME no lua (talvez já não exista)."
fi

# Pedir a palavra-passe do admin uma vez
read -s -p "Palavra-passe para o utilizador remoto $REMOTE_USER: " REMOTE_PASS
echo

# Apagar o utilizador remotamente
for host in "${SERVERS[@]}"; do
  echo "[$host] A tentar apagar o utilizador $USERNAME..."
  
  REMOTE_COMMAND="echo '$REMOTE_PASS' | sudo -S userdel -r $USERNAME"

  ssh "$REMOTE_USER@$host" "$REMOTE_COMMAND" &>/dev/null

  if [[ $? -ne 0 ]]; then
    # O código de erro 6 (userdel) significa "utilizador não existe", o que para nós está OK.
    if [[ $? -eq 6 ]]; then
        echo "[$host] Utilizador $USERNAME não existia (o que é bom)."
    else
        echo "[$host] FALHA ao apagar o utilizador $USERNAME."
    fi
  else
    echo "[$host] Utilizador $USERNAME apagado com sucesso."
  fi
done

echo "Processo de remoção concluído."
