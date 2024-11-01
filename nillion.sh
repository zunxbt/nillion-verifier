#!/bin/bash

curl -s https://raw.githubusercontent.com/zunxbt/logo/main/logo.sh | bash
sleep 2

# Styling variables
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

# Color codes
RED='\033[1;31m'      # Error messages
YELLOW='\033[1;33m'   # Progress messages
GREEN='\033[1;32m'    # Success messages
PINK='\033[1;35m'     # Default messages

show() {
    case $2 in
        "error")
            echo -e "${RED}${BOLD}❌ $1${NORMAL}"
            ;;
        "progress")
            echo -e "${YELLOW}${BOLD}⏳ $1${NORMAL}"
            ;;
        *)
            echo -e "${GREEN}${BOLD}✅ $1${NORMAL}"
            ;;
    esac
}

if ! command -v jq &> /dev/null; then
    show "jq is not installed. Installing jq..." "progress"
    sudo apt update && sudo apt install -y jq
    show "jq installed successfully."
else
    show "jq is already installed."
fi

if ! command -v npm &> /dev/null; then
    show "npm is not installed. Installing npm..." "progress"
    source <(wget -O - https://raw.githubusercontent.com/zunxbt/installation/main/node.sh)
    show "npm installed successfully."
else
    show "npm is already installed."
fi

if ! command -v docker &> /dev/null; then
    show "Docker is not installed. Installing Docker..." "progress"
    source <(wget -O - https://raw.githubusercontent.com/zunxbt/installation/main/docker.sh)
    show "Docker installed successfully."
else
    show "Docker is already installed."
fi

install_node() {
    if [[ -f nillion/verifier/credentials.json ]]; then
        show "Found existing credentials.json. Would you like to back it up and delete it? (y/n): " "progress"
        read -p "Type 'y' to backup and delete, or any other key to keep: " backup_choice
        if [[ "$backup_choice" =~ ^[yY]$ ]]; then
            show "Backing up credentials.json to nillion-existing-wallet.json..." "progress"
            cp nillion/verifier/credentials.json nillion-existing-wallet.json
            show "Backup created successfully."
            rm nillion/verifier/credentials.json
            show "Existing credentials.json deleted."
        else
            show "Keeping existing credentials.json."
        fi
    fi

    show "Creating required directories..." "progress"
    mkdir -p nillion/verifier

    if ! docker image inspect nillion/verifier:v1.0.1 &>/dev/null; then
        show "Pulling the Nillion verifier Docker image..." "progress"
        docker pull nillion/verifier:v1.0.1
    else
        show "Nillion verifier Docker image is already available."
    fi

    echo
    echo "Would you like to use an existing wallet or create a new one to run the verifier node? 🤔"
    read -p "Type '1' for a new wallet, or '2' for an existing wallet: " wallet_choice

    generate_pub_key_address() {
        show "Generating public key and address..." "progress"
        node -e "
const { DirectSecp256k1Wallet } = require('@cosmjs/proto-signing');

async function getAddressAndPubKeyFromPrivateKey(privateKeyHex) {
  const privateKeyBytes = Uint8Array.from(
    privateKeyHex.match(/.{1,2}/g).map((byte) => parseInt(byte, 16))
  );
  const wallet = await DirectSecp256k1Wallet.fromKey(privateKeyBytes, 'nillion');
  const [{ address, pubkey }] = await wallet.getAccounts();
  console.log(address);
  console.log(Buffer.from(pubkey).toString('hex'));
}

getAddressAndPubKeyFromPrivateKey('$private_key');
" > address_and_pubkey.txt

        wallet_address=$(sed -n '1p' address_and_pubkey.txt)
        pub_key=$(sed -n '2p' address_and_pubkey.txt)

        show "Address: $wallet_address"
        show "Public Key: $pub_key"
        echo
    }

    if [[ "$wallet_choice" == "2" ]]; then
        # Ask for the private key
        read -p "Enter your private key: " private_key
        echo

        npm install @cosmjs/proto-signing
        generate_pub_key_address

        cat <<EOF > nillion/verifier/credentials.json
{
  "priv_key": "$private_key",
  "pub_key": "$pub_key",
  "address": "$wallet_address"
}
EOF
    rm address_and_pubkey.txt

    elif [[ "$wallet_choice" == "1" ]]; then
        show "Creating a new verifier node..." "progress"
        docker run -v ./nillion/verifier:/var/tmp nillion/verifier:v1.0.1 initialise

        echo
        echo "Now visit: https://verifier.nillion.com/verifier"
        echo "Connect a new Keplr wallet."
        echo "Request faucet to the nillion address: https://faucet.testnet.nillion.com"
        echo

        read -p "Have you requested the faucet? (y/n): " faucet_requested
        if [[ ! "$faucet_requested" =~ ^[yY]$ ]]; then
            show "Please request the faucet and try again." "error"
            exit 1
        fi

        echo
        echo "Input the following information on the website: https://verifier.nillion.com/verifier"
        echo -e "Address: ${GREEN}$(jq -r '.address' nillion/verifier/credentials.json)${NORMAL}"
        echo -e "Public Key: ${GREEN}$(jq -r '.pub_key' nillion/verifier/credentials.json)${NORMAL}"
        echo

        read -p "Have you inputted the address and public key on the website? (y/n): " info_inputted
        if [[ ! "$info_inputted" =~ ^[yY]$ ]]; then
            show "Please input the information and try again." "error"
            exit 1
        fi
    else
        show "Invalid choice. Please select 1 or 2." "error"
    fi


show "Starting the verifier node..." "progress"
sudo docker run -d --name nillion -v ./nillion/verifier:/var/tmp nillion/verifier:v1.0.1 verify --rpc-endpoint "https://nillion-testnet-rpc.polkachu.com"
echo
show "Showing nillion container logs..." "progress"
sudo docker logs nillion -fn 50
}

delete_node() {
    show "Backing up credentials.json to nillion-backup.json..." "progress"
    if [[ -f nillion/verifier/credentials.json ]]; then
        cp nillion/verifier/credentials.json nillion-backup.json
        show "Backup created successfully."
    else
        show "No credentials.json found to back up." "error"
    fi

    show "Stopping and removing the Nillion Docker container..." "progress"
    sudo docker ps -a | grep nillion/verifier | awk '{print $1}' | xargs -r docker stop 2>/dev/null
    sudo docker ps -a | grep nillion/verifier | awk '{print $1}' | xargs -r docker rm 2>/dev/null

    show "Deleting the verifier node..." "progress"
    rm -rf nillion/verifier
    show "Verifier node deleted successfully."
}

while true; do
    echo
    echo "1. Install the verifier node"
    echo "2. Delete the verifier node"
    echo "3. Exit"
    echo
    read -p "Select an option: " option
    case $option in
        1) install_node ;;
        2) delete_node ;;
        3) exit 0 ;;
        *) show "Invalid option. Please try again." "error" ;;
    esac
done
