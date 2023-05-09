#!/bin/bash
if [ -d .release ]; then rm -r .release; fi
mkdir -p .release/Broker_Cash
cp -r libs locales Broker_Cash.* *.md .release/Broker_Cash
version=$(awk 'match($0, /## Version: ([0-9.]+)/, a) {print a[1]}' Broker_Cash.toc)
cd .release
7z a "Broker_Cash-v$version.zip" Broker_Cash
rm -r Broker_Cash