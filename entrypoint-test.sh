#!/bin/sh
cd `dirname $0`
set -eu

bundle config set --local with 'test'
bundle install
exec bundle exec rspec
