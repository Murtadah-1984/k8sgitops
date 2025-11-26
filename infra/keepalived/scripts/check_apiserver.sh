#!/bin/bash
curl --silent --max-time 1 https://127.0.0.1:6443/healthz -k | grep -q ok

