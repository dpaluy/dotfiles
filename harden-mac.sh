#!/usr/bin/env bash
#
# macOS Security Hardening Script
# Interactive — asks before applying each setting.
#
# Usage: ./harden-mac.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/install/lib.sh"

# macOS only
if [[ "$(detect_os)" != "macos" ]]; then
    error "This script is macOS-only."
    exit 1
fi

APPLIED=0
SKIPPED=0

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

apply() {
    local desc="$1"; shift
    if ask_yes_no "Apply: $desc?" "y"; then
        "$@"
        info "Applied: $desc"
        ((APPLIED++)) || true
    else
        warn "Skipped: $desc"
        ((SKIPPED++)) || true
    fi
}

check_status() {
    local label="$1"
    local status="$2"
    if has_gum; then
        gum style --foreground 39 "  $label: $status"
    else
        echo "  $label: $status"
    fi
}

# ------------------------------------------------------------------------------
# Banner + current status
# ------------------------------------------------------------------------------

echo ""
if has_gum; then
    gum style --border rounded --padding "1 3" --border-foreground 196 "macOS Security Hardening"
else
    echo "=================================="
    echo "   macOS Security Hardening"
    echo "=================================="
fi
echo ""

# Show current state of key settings before asking
header "Current Security Status"

fw_state=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -o "enabled\|disabled" || echo "unknown")
stealth_state=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2>/dev/null | grep -o "enabled\|disabled" || echo "unknown")
gatekeeper_state=$(spctl --status 2>/dev/null | grep -o "enabled\|disabled" || echo "unknown")
sip_state=$(csrutil status 2>/dev/null | grep -o "enabled\|disabled" || echo "unknown")
fv_state=$(fdesetup status 2>/dev/null | grep -o "On\|Off" || echo "unknown")
ssh_state=$(systemsetup -getremotelogin 2>/dev/null | grep -o "On\|Off" || echo "unknown")
autologin_state=$(defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || echo "disabled")
guest_state=$(defaults read /Library/Preferences/com.apple.loginwindow GuestEnabled 2>/dev/null || echo "0")

[[ "$autologin_state" == "disabled" ]] && autologin_label="disabled" || autologin_label="ENABLED ($autologin_state)"
[[ "$guest_state" == "0" ]] && guest_label="disabled" || guest_label="ENABLED"

check_status "Application Firewall" "$fw_state"
check_status "Stealth Mode       " "$stealth_state"
check_status "Gatekeeper         " "$gatekeeper_state"
check_status "System Integrity   " "$sip_state (read-only — change via Recovery Mode)"
check_status "FileVault          " "$fv_state"
check_status "Remote Login (SSH) " "$ssh_state"
check_status "Auto Login         " "$autologin_label"
check_status "Guest Account      " "$guest_label"
echo ""

# ------------------------------------------------------------------------------
# Network Security
# ------------------------------------------------------------------------------

header "Network Security"

apply "Enable Application Firewall" \
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

apply "Enable Stealth Mode (ignore ICMP pings and port scans)" \
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

if [[ "$ssh_state" == "On" ]]; then
    apply "Disable Remote Login / SSH (currently ON)" \
        sudo systemsetup -setremotelogin off
else
    info "Remote Login (SSH) is already off — skipping"
fi

apply "Disable Remote Apple Events" \
    sudo systemsetup -setremoteappleevents off

# ------------------------------------------------------------------------------
# Screen Lock & Session Security
# ------------------------------------------------------------------------------

header "Screen Lock & Session Security"

apply "Require password immediately after sleep or screensaver" bash -c '
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
'

apply "Set screensaver to activate after 5 minutes of inactivity" \
    defaults -currentHost write com.apple.screensaver idleTime -int 300

apply "Show screensaver lock message (set a custom message)" bash -c '
    sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "This Mac belongs to its owner. If found, please contact the owner."
'

# ------------------------------------------------------------------------------
# User Accounts
# ------------------------------------------------------------------------------

header "User Accounts"

if [[ "$guest_label" == "ENABLED" ]]; then
    apply "Disable Guest Account" \
        sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
else
    info "Guest Account is already disabled — skipping"
fi

if [[ "$autologin_label" != "disabled" ]]; then
    apply "Disable Automatic Login" \
        sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser
else
    info "Automatic Login is already disabled — skipping"
fi

# ------------------------------------------------------------------------------
# System Integrity
# ------------------------------------------------------------------------------

header "System Integrity"

if [[ "$gatekeeper_state" != "enabled" ]]; then
    apply "Enable Gatekeeper (block unsigned apps)" \
        sudo spctl --master-enable
else
    info "Gatekeeper is already enabled — skipping"
fi

if [[ "$fv_state" != "On" ]]; then
    warn "FileVault is OFF — your disk is unencrypted."
    warn "Enabling will prompt for your login password and print a recovery key."
    warn "SAVE the recovery key somewhere safe (password manager). Without it, a forgotten password = permanent data loss."
    apply "Enable FileVault full-disk encryption" \
        sudo fdesetup enable
else
    info "FileVault is already ON — skipping"
fi

if [[ "$sip_state" != "enabled" ]]; then
    warn "System Integrity Protection (SIP) is disabled."
    warn "Re-enable via Recovery Mode: run 'csrutil enable' in Terminal there."
else
    info "SIP is enabled — skipping"
fi

# ------------------------------------------------------------------------------
# Software Updates
# ------------------------------------------------------------------------------

header "Software Updates"

apply "Enable automatic update checks" bash -c '
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ScheduleFrequency -int 1
'

apply "Enable automatic security/data file updates" bash -c '
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true
'

apply "Enable automatic app updates from the App Store" \
    sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool true

# ------------------------------------------------------------------------------
# Privacy
# ------------------------------------------------------------------------------

header "Privacy"

apply "Disable Spotlight Siri data sharing (analytics)" bash -c '
    defaults write com.apple.assistant.support "Assistant Enabled" -bool false 2>/dev/null || true
    defaults write com.apple.Siri StatusMenuVisible -bool false 2>/dev/null || true
'

apply "Disable sending diagnostic data to Apple" bash -c '
    defaults write /Library/Application\ Support/CrashReporter DiagnosticMessagesHistory -bool false 2>/dev/null || true
    sudo defaults write /Library/Preferences/com.apple.SubmitDiagInfo AutoSubmit -bool false 2>/dev/null || true
'

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

echo ""
if has_gum; then
    gum style --border double --padding "1 3" --border-foreground 82 \
        "Hardening complete: $APPLIED applied, $SKIPPED skipped"
else
    echo "=================================="
    echo "  Hardening complete!"
    echo "  Applied: $APPLIED | Skipped: $SKIPPED"
    echo "=================================="
fi
echo ""

warn "Some settings take effect after a logout or reboot."
warn "Manual actions still required:"
echo "  - Verify SIP:       Boot to Recovery Mode, run: csrutil status"
echo "  - Firmware password: Boot to Recovery Mode, Utilities > Startup Security Utility"
echo ""
