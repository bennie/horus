# Horus 

Keep track of what is happening on your servers.

## Who is Horus?

Horus was the Egyption god who defeated Set, the god of chaos. Consequently, this is probably the most pretentionsly named software I've ever been a party to, but the purpose is clear: I'd like to end the chaos. 

## Perfection vs. Chaos

On that thought, I really hope that you never need to use this software. Yes, I know this is a website where I offer the software for people to use. I just hope you don't have too.

In a perfect world, you can use such wonderful products as Puppet to control your configurations authoratively. Via source control, access controls, and other common tools of the trade you can make your severs a wonderfully controlled, secured, and well used environment that runs like a well oiled machine. If you can do that, if you have a shot at perfection, you should not be here.

Sadly, I've dealt more with chaos than perfection in my technical career. 

## What is it?

Horus is a web system that helps you track your servers. You can cenrtrally store, distribute, and organize authentication information. In the background and on a regular basis, horus will examine the individual systems, record change to configurations, and generate both local and emailed reports.

Several hundred common linux configuration files are checked on each machine. Changes are analyzed and stored in internal change control so historic configurations can be compared against current.

A rudiment control system is in place that allows controlled access to sensative information, editing ability, etc.

## How to install

This is still rough, my apologies.

On your server, create a user. The code assumes the user will be user "horus" with a home in "/home/horus"

Download the contents of the repo into this user's home account.

Create a mysql database and import the schmea from "support/horus.sql"

Edit lib/Horus/DB.pm to match your DB connection string.

Create an apache virtual host that points to the "www" directory of the tar file. ExecCGI privaledges are required and the extension ".cgi" should be enabled as a CGI.

The CGIs and code requires several perl modules, including the VMware virtual client libraries. Install them in the standard locations.

Install the cron in "support/cron.d" as the user horus.
