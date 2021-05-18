#!/usr/bin/env bash
## Created 20210515
## Thilina Pathirana

PROG="`basename $0`"
HOSTNAME="`hostname`"


function Usage() {
cat << EOF

The following are mandatory:
  -4 HOSTADDRESS (\$address$)
  -6 HOSTADDRESS6 (\$address6$)
  -d LONGDATETIME (\$icinga.long_date_time$)
  -l HOSTALIAS (\$host.name$)
  -n HOSTDISPLAYNAME (\$host.display_name$)
  -o HOSTOUTPUT (\$host.output$)
  -s HOSTSTATE (\$host.state$)
  -t NOTIFICATIONTYPE (\$notification.type$)
  -x Telegram TOKENCODE
  -y Telegram CHAT ID

And these are optional:
  -b NOTIFICATIONAUTHORNAME (\$notification.author$)
  -c NOTIFICATIONCOMMENT (\$notification.comment$)
  -i ICINGAWEB2URL (\$icingaweb2url$, Default: unset)
  -f MAILFROM (\$notification_mailfrom$, Default: "Icinga 2 Monitoring <icinga@$HOSTNAME>")
  -v VERBOSE (\$notification_sendtosyslog$)

EOF

exit 1;
}

while getopts 4:6::b:c:d:f:hi:l:n:o:s:t:v: opt
do
  case "$opt" in
    4) HOSTADDRESS=$OPTARG ;;
    6) HOSTADDRESS6=$OPTARG ;;
    b) NOTIFICATIONAUTHORNAME=$OPTARG ;;
    c) NOTIFICATIONCOMMENT=$OPTARG ;;
    d) LONGDATETIME=$OPTARG ;;
    f) MAILFROM=$OPTARG ;;
    h) Usage ;;
    i) ICINGAWEB2URL=$OPTARG ;;
    l) HOSTALIAS=$OPTARG ;;
    n) HOSTDISPLAYNAME=$OPTARG ;;
    o) HOSTOUTPUT=$OPTARG ;;
    s) HOSTSTATE=$OPTARG ;;
    t) NOTIFICATIONTYPE=$OPTARG ;;
    v) VERBOSE=$OPTARG ;;
    x) TOKENCODE=$OPTARG ;;
    y) CHATID=$OPTARG ;;
   \?) echo "ERROR: Invalid option -$OPTARG" >&2
       Usage ;;
    :) echo "Missing option argument for -$OPTARG" >&2
       Usage ;;
    *) echo "Unimplemented option: -$OPTARG" >&2
       Usage ;;
  esac
done

shift $((OPTIND - 1))


## Build the message's subject
SUBJECT="[$NOTIFICATIONTYPE] Host $HOSTDISPLAYNAME is $HOSTSTATE!"

## Build the notification message
NOTIFICATION_MESSAGE=`cat << EOF
<b>Subject:</b> **$SUBJECT**
***** Icinga 2 Host Monitoring on $HOSTNAME *****

==> $HOSTDISPLAYNAME ($HOSTALIAS) is $HOSTSTATE! <==

Info?    $HOSTOUTPUT

When?    $LONGDATETIME
Host?    $HOSTALIAS (aka "$HOSTDISPLAYNAME)
IPv4?	 $HOSTADDRESS
EOF
`

## Is this host IPv6 capable? Put its address into the message.
if [ -n "$HOSTADDRESS6" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
IPv6?	 $HOSTADDRESS6"
fi

## Are there any comments? Put them into the message.
if [ -n "$NOTIFICATIONCOMMENT" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE

Comment by $NOTIFICATIONAUTHORNAME:
  $NOTIFICATIONCOMMENT"
fi

## Are we using Icinga Web 2? Put the URL into the message.
if [ -n "$ICINGAWEB2URL" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE

Get live status:
  $ICINGAWEB2URL/monitoring/host/show?host=$HOSTALIAS"
fi

## Are we verbose? Then put a message to syslog.
if [ "$VERBOSE" == "true" ] ; then
  logger "$PROG sends $SUBJECT => Telegram"
fi


APIURL="https://api.telegram.org/bot""$TOKENCODE""/sendMessage"
APIOPTION="chat_id=""$CHATID""&text=$NOTIFICATION_MESSAGE"

/usr/bin/curl -X POST "$APIURL" -d "$APIOPTION"
