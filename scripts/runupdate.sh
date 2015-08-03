#!/bin/sh
date -u

echo "site: checking"
pushd "/webspace/redeclipse.net" 2>&1 >/dev/null
git pull --rebase
popd 2>&1 >/dev/null

echo "home: checking"
pushd "${HOME}/master" 2>&1 >/dev/null
RE_CUR_HOME=`git rev-parse HEAD`
git pull --rebase
RE_RUN_HOME=`git rev-parse HEAD`
popd 2>&1 >/dev/null
if [ -n "${RE_RUN_HOME}" ] && [ "${RE_CUR_HOME}" != "${RE_RUN_HOME}" ]; then
  echo "home: ${RE_CUR_HOME} -> ${RE_RUN_HOME}"
  for i in master stable; do
    RE_PID=`ps ax | grep "redeclipse-${i}" | grep -v "grep" | sed -e 's/^[ \t]*//g;s/[ \t].*$//'`
    if [ -n "${RE_PID}" ]; then
      echo "sending HUP to ${i} (${RE_PID})"
      kill -s HUP ${RE_PID}
    fi
  done
fi

echo "statsdb: checking"
pushd "${HOME}/statsdb-interface" 2>&1 >/dev/null
RE_CUR_STATS=`git rev-parse HEAD`
git pull --rebase
RE_RUN_STATS=`git rev-parse HEAD`
popd 2>&1 >/dev/null
if [ -n "${RE_RUN_STATS}" ] && [ "${RE_CUR_STATS}" != "${RE_RUN_STATS}" ]; then
  echo "statsdb: ${RE_CUR_STATS} -> ${RE_RUN_STATS}"
  RE_PID=`ps ax | grep "server.py ${HOME}/master/master" | grep -v "grep" | sed -e 's/^[ \t]*//g;s/[ \t].*$//'`
  if [ -n "${RE_PID}" ]; then
    echo "statsdb: sending TERM to ${RE_PID}"
    kill -s TERM ${RE_PID}
  fi
fi

echo "checking master server.."
if curl --progress-bar --fail --max-time 10 http://play.redeclipse.net:28800/version; then
  for i in master stable; do
    echo "${i}: checking"
    RE_CUR_VER=`cat "${HOME}/redeclipse-${i}/bin/version.txt"`
    RE_RUN_VER=`cat "/webspace/redeclipse.net/files/${i}/bins.txt"`
    if [ -n "${RE_RUN_VER}" ] && [ "${RE_CUR_VER}" != "${RE_RUN_VER}" ]; then
      echo "${i}: ${RE_CUR_VER} -> ${RE_RUN_VER}"
      RE_PID=`ps ax | grep "redeclipse-${i}" | grep -v "grep" | sed -e 's/^[ \t]*//g;s/[ \t].*$//'`
      if [ -n "${RE_PID}" ]; then
        echo "${i}: sending TERM to ${RE_PID}"
        kill -s TERM ${RE_PID}
      fi
    fi
  done
else
  echo "master server not responding, killing all servers"
  killall -KILL redeclipse_server_linux
fi

echo "-"
