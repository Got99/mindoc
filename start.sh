#!/bin/bash
set -eux

APP_BIN="/mindoc/mindoc_linux_amd64"
INIT_MODE="${MINDOC_INIT_MODE:-auto}"
INIT_MARKER="/mindoc/runtime/.mindoc_initialized"
DB_ADAPTER="${MINDOC_DB_ADAPTER:-sqlite3}"
DB_DATABASE="${MINDOC_DB_DATABASE:-./database/mindoc.db}"

if [[ "${DB_DATABASE}" == ./* ]]; then
  DB_DATABASE="/mindoc/${DB_DATABASE#./}"
fi

# 默认资源
if [ ! -d "/mindoc/conf" ]; then mkdir -p "/mindoc/conf" ; fi
if [[ -z "$(ls -A -- "/mindoc/conf")" ]] ; then cp -r "/mindoc/__default_assets__/conf" "/mindoc/" ; fi

if [ ! -d "/mindoc/static" ]; then mkdir -p "/mindoc/static" ; fi
if [[ -z "$(ls -A -- "/mindoc/static")" ]] ; then cp -r "/mindoc/__default_assets__/static" "/mindoc/" ; fi

if [ ! -d "/mindoc/views" ]; then mkdir -p "/mindoc/views" ; fi
if [[ -z "$(ls -A -- "/mindoc/views")" ]] ; then cp -r "/mindoc/__default_assets__/views" "/mindoc/" ; fi

if [ ! -d "/mindoc/uploads" ]; then mkdir -p "/mindoc/uploads" ; fi
if [[ -z "$(ls -A -- "/mindoc/uploads")" ]] ; then cp -r "/mindoc/__default_assets__/uploads" "/mindoc/" ; fi

# 如果配置文件不存在就复制
cp --no-clobber /mindoc/conf/app.conf.example /mindoc/conf/app.conf

mkdir -p /mindoc/runtime

run_init() {
  if [[ "$1" == "install" ]]; then
    "$APP_BIN" install
  else
    "$APP_BIN" update
  fi
  touch "$INIT_MARKER"
}

if [[ "${INIT_MODE}" == "install" ]]; then
  run_init install
elif [[ "${INIT_MODE}" == "update" ]]; then
  run_init update
else
  if [[ "${DB_ADAPTER}" == "sqlite3" && -s "${DB_DATABASE}" ]]; then
    run_init update
  elif [[ -f "${INIT_MARKER}" ]]; then
    run_init update
  else
    run_init install
  fi
fi

# 运行
"$APP_BIN"

# # Debug Dockerfile
# while [ 1 ]
# do
#     echo "log ..."
#     sleep 5s
# done
