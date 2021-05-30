#!/usr/bin/env bash
## Code below will send Alerts to Emails based on Service Notifications on Icinga2 using sendmail.
## Originally made by Marianne M. Spiller <github@spiller.me>
## updated and customized by Thilina Pathirana <me@thilinapathirana.xyz>
## download this in to /etc/icinga2/scripts of your icinga installation.
## You need to set up telegram bot for this to work.
## 20210518

PROG="`basename $0`"
HOSTNAME="`hostname`"


function Usage() {
cat << EOF
The following are mandatory:
  -4 HOSTADDRESS (\$address$)
  -6 HOSTADDRESS (\$address6$)
  -d LONGDATETIME (\$icinga.long_date_time$)
  -e SERVICENAME (\$service.name$)
  -l HOSTALIAS (\$host.name$)
  -n HOSTDISPLAYNAME (\$host.display_name$)
  -o SERVICEOUTPUT (\$service.output$)
  -r USEREMAIL (\$user.email$)
  -s SERVICESTATE (\$service.state$)
  -t NOTIFICATIONTYPE (\$notification.type$)
  -u SERVICEDISPLAYNAME (\$service.display_name$)
  -x Slack API-URL

And these are optional:
  -b NOTIFICATIONAUTHORNAME (\$notification.author$)
  -c NOTIFICATIONCOMMENT (\$notification.comment$)
  -i ICINGAWEB2URL (\$icingaweb2url$, Default: unset)
  -f MAILFROM (\$notification_mailfrom$, Default: "Icinga 2 Monitoring <icinga@$HOSTNAME>")
  -v VERBOSE (\$notification_sendtosyslog$)
EOF
exit 1;
}

while getopts 4:6:b:c:d:e:f:hi:l:n:o:r:s:t:u:v:x:y: opt
do
  case "$opt" in
    4) HOSTADDRESS=$OPTARG ;;
    6) HOSTADDRESS6=$OPTARG ;;
    b) NOTIFICATIONAUTHORNAME=$OPTARG ;;
    c) NOTIFICATIONCOMMENT=$OPTARG ;;
    d) LONGDATETIME=$OPTARG ;;
    e) SERVICENAME=$OPTARG ;;
    f) MAILFROM=$OPTARG ;;
    h) Usage ;;
    i) ICINGAWEB2URL=$OPTARG ;;
    l) HOSTALIAS=$OPTARG ;;
    n) HOSTDISPLAYNAME=$OPTARG ;;
    o) SERVICEOUTPUT=$OPTARG ;;
    r) USEREMAIL=$OPTARG ;;
    s) SERVICESTATE=$OPTARG ;;
    t) NOTIFICATIONTYPE=$OPTARG ;;
    u) SERVICEDISPLAYNAME=$OPTARG ;;
    v) VERBOSE=$OPTARG ;;
    x) APIURL=$OPTARG ;;
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
SUBJECT="[$NOTIFICATIONTYPE] $SERVICEDISPLAYNAME on $HOSTDISPLAYNAME is $SERVICESTATE!"

## Build the notification message
NOTIFICATION_MESSAGE=`cat << EOF
*$SUBJECT*
Icinga 2 Service Monitoring on $HOSTNAME
-----------------------------------------------
*==> $SERVICEDISPLAYNAME on $HOSTDISPLAYNAME is $SERVICESTATE! <==*
Info:      $SERVICEOUTPUT
When:       $LONGDATETIME
Service:   $SERVICENAME (aka "$SERVICEDISPLAYNAME")
Host:      $HOSTALIAS (aka "$HOSTDISPLAYNAME")
IPv4: 	   $HOSTADDRESS
EOF
`

## Is this host IPv6 capable? Put its address into the message.
if [ -n "$HOSTADDRESS6" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
IPv6:    $HOSTADDRESS6"
fi

## Are there any comments? Put them into the message.
if [ -n "$NOTIFICATIONCOMMENT" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
=============================================  
Comment by $NOTIFICATIONAUTHORNAME:
  $NOTIFICATIONCOMMENT"
fi

## Are we using Icinga Web 2? Put the URL into the message.
if [ -n "$ICINGAWEB2URL" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
================  
Get live status:
  $ICINGAWEB2URL/monitoring/service/show?host=$HOSTALIAS&service=$SERVICENAME"
fi

## Are we verbose? Then put a message to syslog.
if [ "$VERBOSE" == "true" ] ; then
  logger "$PROG sends $SUBJECT => Slack"
fi


/usr/bin/curl -X POST -H 'Content-type: application/json' --data "{'text':'$NOTIFICATION_MESSAGE'}" $APIURL
