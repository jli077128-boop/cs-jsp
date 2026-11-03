#!/usr/bin/env bash
# =========================================================
# 智服 AI —— Ubuntu 一键部署脚本（Ubuntu 22.04 / 24.04）
# 安装 JDK 17 + Maven + MySQL 8 + Tomcat 9，导入数据库，打包并启动。
#
# 用法（在项目根目录执行）：
#   sudo bash deploy/install-ubuntu.sh            # 首次部署 / 改代码后重新部署
#   sudo bash deploy/install-ubuntu.sh --reset-db # 同时把数据库重置为演示数据
#
# 部署完成后浏览器打开：http://<虚拟机IP>:8080/cs/
# 演示账号：admin / agent01 / user01，密码都是 123456
# =========================================================
set -euo pipefail

TOMCAT_HOME=/opt/tomcat9
TOMCAT_FALLBACK_VER=9.0.123
DB_NAME=cs_db
DB_USER=cs
DB_PASS=123456
APP_NAME=cs

RESET_DB=0
[[ "${1:-}" == "--reset-db" ]] && RESET_DB=1

if [[ $EUID -ne 0 ]]; then
  echo "请用 sudo 运行：sudo bash deploy/install-ubuntu.sh"; exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"
step() { echo; echo "==> $*"; }

# ---------- 1. 安装依赖 ----------
step "1/6 安装 JDK 17、Maven、MySQL、curl"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y openjdk-17-jdk-headless maven mysql-server curl tar
JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"
echo "JAVA_HOME=$JAVA_HOME"
java -version

# ---------- 2. MySQL ----------
step "2/6 启动 MySQL，创建数据库账号 ${DB_USER}"
systemctl enable --now mysql
mysql -uroot <<SQL
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
CREATE DATABASE IF NOT EXISTS ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

TABLES=$(mysql -uroot -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}'")
if [[ "$TABLES" == "0" || $RESET_DB -eq 1 ]]; then
  step "3/6 导入 sql/init.sql（演示数据）"
  mysql -uroot --default-character-set=utf8mb4 < sql/init.sql
else
  step "3/6 数据库已存在（${TABLES} 张表），跳过导入。需要重置请加 --reset-db"
fi

# ---------- 3. Tomcat 9 ----------
step "4/6 安装 Tomcat 9 到 ${TOMCAT_HOME}"
if [[ ! -x "$TOMCAT_HOME/bin/catalina.sh" ]]; then
  VER=$(curl -fsSL --max-time 15 https://mirrors.aliyun.com/apache/tomcat/tomcat-9/ \
        | grep -o 'v9\.[0-9]*\.[0-9]*/' | tr -d 'v/' | sort -V | tail -1 || true)
  VER=${VER:-$TOMCAT_FALLBACK_VER}
  TGZ="apache-tomcat-${VER}.tar.gz"
  echo "Tomcat 版本：$VER"
  curl -fL --max-time 300 -o "/tmp/$TGZ" "https://mirrors.aliyun.com/apache/tomcat/tomcat-9/v${VER}/bin/${TGZ}" \
    || curl -fL --max-time 300 -o "/tmp/$TGZ" "https://archive.apache.org/dist/tomcat/tomcat-9/v${VER}/bin/${TGZ}"
  mkdir -p "$TOMCAT_HOME"
  tar -xzf "/tmp/$TGZ" -C "$TOMCAT_HOME" --strip-components=1
  rm -rf "$TOMCAT_HOME"/webapps/{docs,examples}
  id tomcat &>/dev/null || useradd -r -M -d "$TOMCAT_HOME" -s /usr/sbin/nologin tomcat
fi

cat > /etc/systemd/system/tomcat9.service <<EOF
[Unit]
Description=Apache Tomcat 9 (cs-jsp)
After=network.target mysql.service

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment=JAVA_HOME=${JAVA_HOME}
Environment=CATALINA_HOME=${TOMCAT_HOME}
Environment=CATALINA_BASE=${TOMCAT_HOME}
Environment=CATALINA_PID=${TOMCAT_HOME}/temp/tomcat.pid
Environment="JAVA_OPTS=-Dfile.encoding=UTF-8 -Djava.security.egd=file:/dev/./urandom"
ExecStart=${TOMCAT_HOME}/bin/startup.sh
ExecStop=${TOMCAT_HOME}/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload

# ---------- 4. 打包 ----------
step "5/6 Maven 打包（使用阿里云镜像）"
mvn -B -q -s deploy/maven-settings.xml clean package -DskipTests
[[ -d target/${APP_NAME} ]] || { echo "打包失败：没有 target/${APP_NAME}"; exit 1; }

# ---------- 5. 部署并启动 ----------
step "6/6 部署到 Tomcat 并启动"
systemctl stop tomcat9 2>/dev/null || true
rm -rf "$TOMCAT_HOME/webapps/${APP_NAME}" "$TOMCAT_HOME/webapps/${APP_NAME}.war"
cp -r "target/${APP_NAME}" "$TOMCAT_HOME/webapps/${APP_NAME}"
# 虚拟机上用专门的数据库账号 cs / 123456，端口 3306
CONF="$TOMCAT_HOME/webapps/${APP_NAME}/WEB-INF/classes/dbcpconfig.properties"
sed -i -E "s#^url=jdbc:mysql://[^/]+/#url=jdbc:mysql://localhost:3306/#; s#^username=.*#username=${DB_USER}#; s#^password=.*#password=${DB_PASS}#" "$CONF"
chown -R tomcat:tomcat "$TOMCAT_HOME"
systemctl enable --now tomcat9

if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
  ufw allow 8080/tcp
fi

echo -n "等待 Tomcat 启动"
for i in $(seq 1 30); do
  if curl -fs -o /dev/null "http://localhost:8080/${APP_NAME}/"; then echo " OK"; break; fi
  echo -n "."; sleep 2
done

IP=$(hostname -I | awk '{print $1}')
echo
echo "================================================="
echo " 部署完成！浏览器打开： http://${IP}:8080/${APP_NAME}/"
echo " 演示账号 admin / agent01 / user01，密码 123456"
echo " 查看日志： sudo tail -f ${TOMCAT_HOME}/logs/catalina.out"
echo " 重启服务： sudo systemctl restart tomcat9"
echo "================================================="
