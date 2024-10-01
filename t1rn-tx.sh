#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # 색상 초기화

# 변수 정의
PACKAGE_NAME="titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz"
DIR_NAME="titan-edge_v0.1.20_246b9dd_linux-amd64"

# 1. 기존 패키지 삭제
if [ -f "$PACKAGE_NAME" ]; then
    echo -e "${YELLOW}기존 패키지를 삭제합니다...${NC}"
    rm -f "$PACKAGE_NAME"
fi

# 2. 패키지 다운로드
echo -e "${YELLOW}패키지를 다운로드합니다...${NC}"
wget https://github.com/Titannet-dao/titan-node/releases/download/v0.1.20/titan-edge_v0.1.20_246b9dd_linux-amd64.tar.gz

# 3. 다운로드한 파일 압축 해제
echo -e "${YELLOW}패키지를 추출합니다...${NC}"
tar -xzvf "$PACKAGE_NAME"

# 4. 작업 폴더로 이동
cd "$DIR_NAME" || { echo -e "${RED}디렉토리로 이동 실패${NC}"; exit 1; }

# 5. 권한 설정 및 파일 복사
echo -e "${YELLOW}파일을 복사합니다...${NC}"
sudo cp titan-edge /usr/local/bin
sudo cp libgoworkerd.so /usr/local/lib

# 6. 환경 변수 설정
echo -e "${YELLOW}환경 변수를 설정합니다...${NC}"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

# 7. 프록시 목록 사용자 입력
echo -e "${YELLOW}보유하신 모든 Proxy를 chatgpt에게 다음과 같은 형식으로 변환해달라고 하세요.${NC}"
echo -e "${YELLOW}이러한 형태로 각 프록시를 한줄에 하나씩 입력하세요: http://username:password@proxy_host:port${NC}"
echo -e "${YELLOW}프록시 입력 후 엔터를 두번 누르면 됩니다.${NC}"

base_port=5000

# 프록시 목록을 proxy.txt 파일에 저장
> proxy.txt # 파일 초기화
while true; do
    read -r proxy
    if [ -z "$proxy" ]; then
        break
    fi
    echo "$proxy" >> proxy.txt
done

# 모든 프록시 처리
for proxy in $(< proxy.txt); do
    # 프록시가 비어있으면 넘어감
    if [ -z "$proxy" ]; then
        echo -e "${RED}프록시가 입력되지 않았습니다. 다음 프록시로 넘어갑니다.${NC}"
        continue  
    fi

    # 각 데몬에 고유 작업 디렉토리 생성 및 포트 할당
    repo_dir="/root/titan-edge-workspace/$current_port"
    mkdir -p "$repo_dir"

    # 각 데몬에 고유 포트 할당
    current_port=$((base_port++))

    echo -e "${YELLOW}프록시: ${proxy}를 사용하여 포트 ${current_port}에서 데몬을 실행합니다...${NC}"
    
    # 환경 변수로 프록시 설정
    export http_proxy=$proxy
    export https_proxy=$proxy
    
    echo -e "${YELLOW}프록시: ${proxy}를 사용하여 식별코드를 얻으세요:${NC}"
    echo -e "${YELLOW}해당 사이트에 방문하여 식별코드를 얻으세요: ${NC}"
    echo -e "${YELLOW}https://test1.titannet.io/newoverview/activationcodemanagement${NC}"
    
    # 사용자로부터 식별 코드 입력 받기
    read -p "$(echo -e ${YELLOW}식별 코드를 입력하세요: ${NC})" identifier

    # 9. 바인드 명령 실행
    echo -e "${YELLOW}바인드 명령을 실행합니다...${NC}"
    titan-edge bind --hash="$identifier" https://api-test1.container1.titannet.io/api/v2/device/binding
    
    # 10. 데몬 시작
    echo -e "${YELLOW}titan-edge 데몬을 시작합니다...${NC}"
    titan-edge daemon start --init --url https://cassini-locator.titannet.io:${current_port}/rpc/v0
    sudo ufw allow ${current_port}/tcp
    
    # 환경 변수 해제
    unset http_proxy https_proxy
done

echo -e "${GREEN}모든 작업이 완료되었습니다. 컨트롤+A+D로 스크린을 종료해주세요.${NC}"
echo -e "${GREEN}스크립트 작성자: https://t.me/kjkresearch${NC}"
