#!/bin/sh

BIN=`dirname $0`
BASE=$BIN/..
WEB=$BASE/..

php $BIN/carew build --base-dir=$BASE --web-dir=$WEB
