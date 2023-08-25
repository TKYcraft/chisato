#!/bin/sh
echo "start rails server with exec."
set -e
rm -f ./tmp/pids/server.pid
exec bin/rails s -b 0.0.0.0
