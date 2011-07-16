/var/log/engineyard/nginx/*.log {
	daily
	missingok
	rotate 28
	compress
	notifempty
	sharedscripts
	extension gz
	postrotate
		[ ! -f /var/run/nginx.pid ] || kill -USR1 `cat /var/run/nginx.pid`
	endscript
}