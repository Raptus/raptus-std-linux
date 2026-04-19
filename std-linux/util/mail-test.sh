#!/bin/bash

MAILTO="yourname@domain.tld"
MAILFROM="hostname@domain.tld"
SUBJECT="This is a test mail. Please ignore it"

(
  echo "To: $MAILTO"
  echo "From: $MAILFROM"
  echo "Subject: $SUBJECT"
  echo ""

  echo "This mail has been sent to you in order to test your mail system functionality."
  echo
  echo "Hostmaster"
  echo
  echo
) 2>&1 | /usr/lib/sendmail -f $MAILFROM -t
exit 0

# eof
