#!/bin/sh

BIN=`dirname $0`
BASE=$BIN/..
WEB=$BASE/..

php $BIN/../vendor/carew/carew/bin/carew build --base-dir=$BASE --web-dir=$WEB
