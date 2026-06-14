#!/usr/bin/env bash
# shellcheck shell=bash

ops_sudo_auth() {
  run_with_terminal_stdin sudo -v
}
