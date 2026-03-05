#!/bin/bash
set -e

# ============================================
# WireGuard 서버 자동 설치 스크립트
# Terraform templatefile()로 변수 주입됨
# ============================================

# Terraform에서 주입되는 변수들
SERVER_NAME="${server_name}"
PUBLIC_IP="${PUBLIC_IP}"
WG_PORT="${WG_PORT}"
WG_MTU="${WG_MTU}"
VPC_CIDR="${VPC_CIDR}"
WG_INTERFACE=wg0

echo "=========================================="
echo "WireGuard Server Installation Started"
echo "Server Name: $SERVER_NAME"
echo "Public IP: $PUBLIC_IP"
echo "WireGuard Port: $WG_PORT"
echo "MTU: $WG_MTU"
echo "=========================================="

# ============================================
# 1. 시스템 업데이트
# ============================================

echo "[1/8] System Update"
yum update -y
yum install -y wireguard-tools iptables-services

# ============================================
# 2. Kernel 모듈 로드
# ============================================

echo "[2/8] Loading WireGuard Kernel Module"
modprobe wireguard || true

# ============================================
# 3. 키 생성
# ============================================

echo "[3/8] Generating WireGuard Keys"
WG_DIR="/etc/wireguard"
mkdir -p $WG_DIR
cd $WG_DIR

# 서버 키 생성
wg genkey | tee server_private.key | wg pubkey > server_public.key

# 클라이언트 키 생성 (테스트용 기본 클라이언트)
wg genkey | tee client1_private.key | wg pubkey > client1_public.key
wg genkey | tee client2_private.key | wg pubkey > client2_public.key

chmod 600 server_private.key client1_private.key client2_private.key

echo "✓ Keys generated successfully"

# ============================================
# 4. WireGuard 서버 설정
# ============================================

echo "[4/8] Creating WireGuard Server Configuration"

SERVER_PRIVKEY=$(cat server_private.key)
CLIENT1_PUBKEY=$(cat client1_public.key)
CLIENT2_PUBKEY=$(cat client2_public.key)

cat > $WG_DIR/wg0.conf << EOF
[Interface]
Address = 10.0.0.1/24
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIVKEY
MTU = $WG_MTU

# PostUp/PostDown for NAT (VPC 내부 접근용)
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o ens5 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -o ens5 -j MASQUERADE

[Peer]
# Client1
PublicKey = $CLIENT1_PUBKEY
AllowedIPs = 10.0.0.2/32

[Peer]
# Client2
PublicKey = $CLIENT2_PUBKEY
AllowedIPs = 10.0.0.3/32
EOF

chmod 600 $WG_DIR/wg0.conf
echo "✓ Server configuration created"

# ============================================
# 5. 클라이언트 설정 생성
# ============================================

echo "[5/8] Creating Client Configurations"

SERVER_PUBKEY=$(cat server_public.key)

# Client1 설정
CLIENT1_PRIVKEY=$(cat client1_private.key)
cat > $WG_DIR/client1.conf << EOF
[Interface]
PrivateKey = $CLIENT1_PRIVKEY
Address = 10.0.0.2/32
DNS = 8.8.8.8
MTU = $WG_MTU

[Peer]
PublicKey = $SERVER_PUBKEY
Endpoint = $PUBLIC_IP:$WG_PORT
AllowedIPs = 10.0.0.0/24, $VPC_CIDR
PersistentKeepalive = 25
EOF

# Client2 설정
CLIENT2_PRIVKEY=$(cat client2_private.key)
cat > $WG_DIR/client2.conf << EOF
[Interface]
PrivateKey = $CLIENT2_PRIVKEY
Address = 10.0.0.3/32
DNS = 8.8.8.8
MTU = $WG_MTU

[Peer]
PublicKey = $SERVER_PUBKEY
Endpoint = $PUBLIC_IP:$WG_PORT
AllowedIPs = 10.0.0.0/24, $VPC_CIDR
PersistentKeepalive = 25
EOF

chmod 600 $WG_DIR/client1.conf $WG_DIR/client2.conf
echo "✓ Client configurations created (Elastic IP: $PUBLIC_IP)"

# ============================================
# 6. IP Forwarding 활성화
# ============================================

echo "[6/8] Enabling IP Forwarding"
echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
sysctl -p > /dev/null
echo "✓ IP forwarding enabled"

# ============================================
# 7. iptables 규칙 설정 (기본 설정)
# ============================================

echo "[7/8] Configuring iptables"

# INPUT: UDP WireGuard 포트 허용
iptables -A INPUT -p udp --dport $WG_PORT -j ACCEPT

# iptables 규칙 저장
iptables-save > /etc/sysconfig/iptables
systemctl enable iptables

echo "✓ iptables configured"

# ============================================
# 8. WireGuard 시작 및 활성화
# ============================================

echo "[8/8] Starting WireGuard Service"

# WireGuard 활성화
wg-quick up wg0

# 부팅 시 자동 시작
systemctl enable wg-quick@wg0

echo "✓ WireGuard service started"

# ============================================
# 완료 메시지 및 상태 저장
# ============================================

echo ""
echo "=========================================="
echo "WireGuard Installation Completed!"
echo "=========================================="
echo ""
echo "📍 Server Information:"
echo "  - Interface: wg0"
echo "  - Server IP: 10.0.0.1/24"
echo "  - Public IP: $PUBLIC_IP"
echo "  - Listen Port: $WG_PORT"
echo "  - MTU: $WG_MTU"
echo "  - Server Name: $SERVER_NAME"
echo ""
echo "🔑 Keys Location: /etc/wireguard/"
echo "  - server_private.key"
echo "  - server_public.key"
echo "  - client1_private.key / client1_public.key"
echo "  - client2_private.key / client2_public.key"
echo ""
echo "📄 Configurations:"
echo "  - /etc/wireguard/wg0.conf (Server)"
echo "  - /etc/wireguard/client1.conf"
echo "  - /etc/wireguard/client2.conf"
echo ""
echo "✅ Status:"
wg show wg0
echo ""
echo "=========================================="

# 설치 완료 마커 파일 생성
echo "Installation completed at $(date)" > /etc/wireguard/.install_complete
echo "Server: $SERVER_NAME" >> /etc/wireguard/.install_complete
echo "Public IP: $PUBLIC_IP" >> /etc/wireguard/.install_complete
