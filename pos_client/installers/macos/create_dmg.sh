#!/bin/bash
# filepath: pos_client/create_dmg.sh

rm -rf POS.dmg
# 使用 appdmg 產生 DMG 檔案
appdmg config.json "POS.dmg"