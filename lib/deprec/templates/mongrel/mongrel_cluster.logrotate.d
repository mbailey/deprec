/var/log/mongrel/<%= application %>/*.log {
	daily
	missingok
	rotate 28
	compress
	notifempty
	sharedscripts
	extension gz
	postrotate
		for i in `ls /data/<%= @username %>/shared/log/*.pid`; do
			kill -USR2 `cat $i`
		done      
	endscript
}