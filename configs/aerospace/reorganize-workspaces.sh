#!/bin/bash

aerospace move-workspace-to-monitor --workspace chat secondary sidecar main

if test "$(whoami)" != "spywhere"; then
  aerospace move-workspace-to-monitor --workspace mail secondary sidecar main
fi
