#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # 색상 초기화

# 작업 공간 디렉토리 설정
WORKSPACE_DIR="/root/t1rntx"

# 기존 디렉토리 삭제 (존재하는 경우)
if [ -d "$WORKSPACE_DIR" ]; then
    echo -e "${YELLOW}기존 작업 공간을 삭제합니다...${NC}"
    rm -rf "$WORKSPACE_DIR"
fi

# 새로운 작업 공간 디렉토리 생성
echo -e "${GREEN}새로운 작업 공간을 생성합니다...${NC}"
mkdir -p "$WORKSPACE_DIR"

# 필요한 패키지 설치
echo -e "${GREEN}필요한 패키지를 설치합니다...${NC}"
pip install web3

# 개인 키 입력 받기
echo -e "${YELLOW}개인 키를 입력하세요 (쉼표로 구분):${NC}"
read -r private_keys

# 트랜잭션 수 입력 받기
echo -e "${YELLOW}각 개인 키에 대해 보낼 트랜잭션 수를 입력하세요:${NC}"
read -r num_transactions

# 개인 키를 privatekey.txt 파일에 저장
echo -e "${GREEN}개인 키를 ${WORKSPACE_DIR}/privatekey.txt 파일에 저장합니다...${NC}"
echo "$private_keys" > "$WORKSPACE_DIR/privatekey.txt"

# t1rn_tx.py 파일 생성
cat << 'EOF' > "$WORKSPACE_DIR/t1rn_tx.py"
from web3 import Web3
import sys

# Arbitrum Sepolia 노드에 연결
w3 = Web3(Web3.HTTPProvider('https://sepolia.arbitrum.io/rpc'))

# 연결 확인
if not w3.isConnected():
    raise Exception("Arbitrum Sepolia 노드에 연결할 수 없습니다.")

# 계정 설정
private_key = sys.argv[1]  # 명령행 인수로 개인 키 입력
account = w3.eth.account.privateKeyToAccount(private_key)

# 계약 주소 및 입력 데이터 정의
contract_address = '0x8D86c3573928CE125f9b2df59918c383aa2B514D'
input_data = '0x56591d59627373700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004CBB1421DF1CF362DC618d887056802d8adB7BC000000000000000000000000000000000000000000000000000005ae1a09d680e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005af3107a4000'

# 거래 파라미터 정의
gas_limit = 2000000
gas_price = w3.toWei('10', 'gwei')
chain_id = 421614  # Arbitrum Sepolia 체인 ID

# 계약에 거래를 보내는 함수
def send_transaction(amount):
    nonce = w3.eth.getTransactionCount(account.address)
    transaction = {
        'to': contract_address,
        'data': input_data,
        'value': w3.toWei(amount, 'ether'),
        'gas': gas_limit,
        'gasPrice': gas_price,
        'nonce': nonce,
        'chainId': chain_id
    }

    signed_txn = w3.eth.account.signTransaction(transaction, private_key)
    txn_hash = w3.eth.sendRawTransaction(signed_txn.rawTransaction)
    return txn_hash

# 반복적으로 거래 전송
num_transactions = int(sys.argv[2])  # 명령행 인수로 거래 수 입력
amount_per_transaction = 0.0001  # ETH 단위의 금액

for i in range(num_transactions):
    txn_hash = send_transaction(amount_per_transaction)
    print(f'거래 해시: {txn_hash.hex()}')
EOF

# 개인 키에 대해 t1rn_tx.py 실행
IFS=',' read -r -a keys_array <<< "$private_keys"
for index in "${!keys_array[@]}"; do
    private_key="${keys_array[$index]}"
    echo -e "${GREEN}현재 사용 중인 지갑: $(($index + 1))${NC}"
    
    # 스크립트 실행 (명령행 인수로 개인 키 및 트랜잭션 수 전달)
    python3 "$WORKSPACE_DIR/t1rn_tx.py" "$private_key" "$num_transactions"
done

echo -e "${GREEN}모든 작업이 완료되었습니다. 컨트롤+A+D로 스크린을 종료해주세요.${NC}"
echo -e "${GREEN}스크립트 작성자: https://t.me/kjkresearch${NC}"
