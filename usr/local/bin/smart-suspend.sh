#!/bin/bash
# Smart suspend script that calculates wake time based on day of week

LOG_FILE="/var/log/hestia-sleep-wake.log"

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Get current day of week (1=Mon, 7=Sun)
DOW=$(date +%u)

# Calculate wake time based on schedule:
# Mon-Fri: wake at 7am
# Sat-Sun: wake at 9am
case $DOW in
    1|2|3|4) # Mon-Thu: wake at 7am tomorrow
        WAKE_TIME=$(date -d "tomorrow 07:00" +%s)
        WAKE_DESC="7:00 AM tomorrow (weekday)"
        ;;
    5) # Friday: wake at 9am on Saturday
        WAKE_TIME=$(date -d "tomorrow 09:00" +%s)
        WAKE_DESC="9:00 AM Saturday"
        ;;
    6) # Saturday: wake at 9am on Sunday
        WAKE_TIME=$(date -d "tomorrow 09:00" +%s)
        WAKE_DESC="9:00 AM Sunday"
        ;;
    7) # Sunday: wake at 7am on Monday
        WAKE_TIME=$(date -d "tomorrow 07:00" +%s)
        WAKE_DESC="7:00 AM Monday"
        ;;
esac

log_msg "Setting RTC wake alarm for $WAKE_DESC (timestamp: $WAKE_TIME)"

# Set the RTC wake alarm
if rtcwake -m no -t "$WAKE_TIME"; then
    log_msg "RTC wake alarm set successfully"
else
    log_msg "ERROR: Failed to set RTC wake alarm"
    exit 1
fi

# Give a moment for the RTC to be configured
sleep 1

log_msg "Suspending system now"

# Suspend the system
systemctl suspend
