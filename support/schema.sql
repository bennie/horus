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
  `last_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  KEY `hosts_name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
