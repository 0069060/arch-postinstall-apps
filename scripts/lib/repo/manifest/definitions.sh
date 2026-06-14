#!/usr/bin/env bash
# shellcheck shell=bash

managed_repo_manifest_init() {
  managed_repo_manifest_reset
  register_managed_repo "install" \
    "dir=$INSTALL_DIR" \
    "https_url=$REPO_HTTPS_URL" \
    "ssh_url=$REPO_SSH_URL" \
    "label=arch-postinstall-apps" \
    "environment=0"
  register_managed_repo "easyeffects_preset" \
    "dir=$EASY_EFFECTS_PRESET_DIR" \
    "https_url=$EASY_EFFECTS_PRESET_REPO_HTTPS_URL" \
    "ssh_url=$EASY_EFFECTS_PRESET_REPO_SSH_URL" \
    "label=EasyEffects-Preset" \
    "environment=1"
  register_managed_repo "terminal_lyrics" \
    "dir=$TERMINAL_LYRICS_DIR" \
    "https_url=$TERMINAL_LYRICS_REPO_HTTPS_URL" \
    "ssh_url=$TERMINAL_LYRICS_REPO_SSH_URL" \
    "label=terminal-lyrics" \
    "environment=1"
  register_managed_repo "synthetic_profile_generator" \
    "dir=$SYNTHETIC_PROFILE_GENERATOR_DIR" \
    "https_url=$SYNTHETIC_PROFILE_GENERATOR_REPO_HTTPS_URL" \
    "ssh_url=$SYNTHETIC_PROFILE_GENERATOR_REPO_SSH_URL" \
    "label=synthetic-profile-generator" \
    "environment=1"
  register_managed_repo "obslove_dots" \
    "dir=$OBSLOVE_DOTS_DIR" \
    "https_url=$OBSLOVE_DOTS_REPO_HTTPS_URL" \
    "ssh_url=$OBSLOVE_DOTS_REPO_SSH_URL" \
    "label=obslove" \
    "environment=1"
  register_managed_repo "dots_hyprland" \
    "dir=$DOTS_HYPRLAND_DIR" \
    "https_url=$DOTS_HYPRLAND_REPO_HTTPS_URL" \
    "ssh_url=$DOTS_HYPRLAND_REPO_SSH_URL" \
    "label=dots-hyprland" \
    "environment=1" \
    "preferred_transport=ssh"
  register_managed_repo "ii_vynx" \
    "dir=$II_VYNX_DIR" \
    "https_url=$II_VYNX_REPO_HTTPS_URL" \
    "ssh_url=$II_VYNX_REPO_SSH_URL" \
    "label=ii-vynx" \
    "environment=1" \
    "clone_submodules=1" \
    "preferred_transport=https"
}
