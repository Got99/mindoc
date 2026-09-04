#!/bin/bash
set -eux

APP_HOME="/app"
APP_BIN="${APP_HOME}/server"
INIT_MODE="${MINDOC_INIT_MODE:-auto}"
INIT_MARKER="${APP_HOME}/runtime/.mindoc_initialized"
DB_ADAPTER="${MINDOC_DB_ADAPTER:-sqlite3}"
DB_DATABASE="${MINDOC_DB_DATABASE:-./database/mindoc.db}"

if [[ "${DB_DATABASE}" == ./* ]]; then
  DB_DATABASE="${APP_HOME}/${DB_DATABASE#./}"
fi

# 默认资源
if [ ! -d "${APP_HOME}/conf" ]; then mkdir -p "${APP_HOME}/conf" ; fi
if [[ -z "$(ls -A -- "${APP_HOME}/conf")" ]] ; then cp -r "${APP_HOME}/__default_assets__/conf" "${APP_HOME}/" ; fi

if [ ! -d "${APP_HOME}/static" ]; then mkdir -p "${APP_HOME}/static" ; fi
if [[ -z "$(ls -A -- "${APP_HOME}/static")" ]] ; then cp -r "${APP_HOME}/__default_assets__/static" "${APP_HOME}/" ; fi

if [ ! -d "${APP_HOME}/views" ]; then mkdir -p "${APP_HOME}/views" ; fi
if [[ -z "$(ls -A -- "${APP_HOME}/views")" ]] ; then cp -r "${APP_HOME}/__default_assets__/views" "${APP_HOME}/" ; fi

if [ ! -d "${APP_HOME}/uploads" ]; then mkdir -p "${APP_HOME}/uploads" ; fi
if [[ -z "$(ls -A -- "${APP_HOME}/uploads")" ]] ; then cp -r "${APP_HOME}/__default_assets__/uploads" "${APP_HOME}/" ; fi

# 如果配置文件不存在就复制
cp --no-clobber "${APP_HOME}/conf/app.conf.example" "${APP_HOME}/conf/app.conf"

mkdir -p "${APP_HOME}/runtime"

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
