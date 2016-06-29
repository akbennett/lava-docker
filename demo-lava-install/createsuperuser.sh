#!/usr/bin/expect -f
spawn lava-server manage createsuperuser
expect "Username (leave blank to use 'root'):"
send "admin\r"
expect "Email address:"
send "admin@localhost\r"
expect "Password:"
send "admin\r"
expect "Password (again):"
send "admin\r"
expect "Superuser created successfully."
