DROP TABLE IF EXISTS `ethernet`;
CREATE TABLE `ethernet` (
  `address` varchar(17) NOT NULL default '',
  `host_id` int(11) default NULL,
  `switch_id` int(11) default NULL,
  `port` varchar(10) default NULL,
  `notes` text,
  `last_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`address`),
  KEY `ethernet_host_id` (`host_id`),
  KEY `ethernet_switch_id` (`switch_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `hosts`;
CREATE TABLE `hosts` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default 'unknown',
  `os` varchar(64) default NULL,
  `osversion` varchar(255) default NULL,
  `arch` varchar(24) default NULL,
  `tz` char(3) default NULL,
  `snmp` int(11) default '-1',
  `snmp_community` varchar(24) default NULL,
  `ntp` int(11) default '-1',
  `ntphost` varchar(255) default NULL,
  `notes` text,
  `last_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  KEY `hosts_name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `switches`;
CREATE TABLE `switches` (
  `id` int(11) NOT NULL default '0',
  `name` varchar(255) NOT NULL default '',
  `brand` varchar(64) default NULL,
  `model` varchar(255) default NULL,
  `notes` text,
  `last_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
