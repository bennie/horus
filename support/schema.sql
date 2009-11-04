-- MySQL dump 10.9
--
-- Host: mysql01.fusionone.com    Database: horus
-- ------------------------------------------------------
-- Server version	5.0.45

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `host_configs`
--

DROP TABLE IF EXISTS `host_configs`;
CREATE TABLE `host_configs` (
  `host_id` int(11) NOT NULL default '0',
  `config_name` varchar(255) NOT NULL default '',
  `config_text` mediumtext,
  `hash` varchar(32) default NULL,
  `created` timestamp NOT NULL default '0000-00-00 00:00:00',
  `last_modified` timestamp NOT NULL default '0000-00-00 00:00:00',
  `config_rcs` mediumtext,
  PRIMARY KEY  (`host_id`,`config_name`),
  KEY `host_id` (`host_id`),
  CONSTRAINT `host_configs_ibfk_1` FOREIGN KEY (`host_id`) REFERENCES `hosts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `host_data_text`
--

DROP TABLE IF EXISTS `host_data_text`;
CREATE TABLE `host_data_text` (
  `host_id` int(11) NOT NULL default '0',
  `data_name` varchar(255) NOT NULL default '',
  `data_value` varchar(255) default NULL,
  `created` timestamp NOT NULL default '0000-00-00 00:00:00',
  `last_modified` timestamp NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`host_id`,`data_name`),
  KEY `host_id` (`host_id`),
  CONSTRAINT `host_data_text_ibfk_1` FOREIGN KEY (`host_id`) REFERENCES `hosts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `hosts`
--

DROP TABLE IF EXISTS `hosts`;
CREATE TABLE `hosts` (
  `id` int(11) NOT NULL auto_increment,
  `customer` varchar(100) default NULL,
  `category` varchar(100) default NULL,
  `type` varchar(100) default NULL,
  `name` varchar(255) default 'unknown',
  `username` varchar(100) default NULL,
  `password` varchar(100) default NULL,
  `os` varchar(64) default NULL,
  `osversion` varchar(255) default NULL,
  `osrelease` varchar(255) default NULL,
  `arch` varchar(24) default NULL,
  `tz` char(3) default NULL,
  `machine_brand` varchar(255) default NULL,
  `machine_model` varchar(255) default NULL,
  `uptime` text,
  `notes` text,
  `skip` int(11) default '0',
  `snmp` int(11) default '-1',
  `snmp_community` varchar(24) default NULL,
  `ntp` int(11) default '-1',
  `ntphost` varchar(255) default NULL,
  `vm` int(11) default '-1',
  `vmhost` varchar(255) default NULL,
  `created` timestamp NOT NULL default '0000-00-00 00:00:00',
  `last_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `decomissioned` int(11) default '0',
  `ram` varchar(50) default NULL,
  `remote` varchar(255) default NULL,
  `rack` varchar(25) default NULL,
  `rack_position` varchar(25) default NULL,
  `rack_patching` varchar(255) default NULL,
  `switch_ports` varchar(255) default NULL,
  `serial` varchar(100) default NULL,
  `remote_user` varchar(100) default NULL,
  `remote_pass` varchar(100) default NULL,
  PRIMARY KEY  (`id`),
  KEY `customer` (`customer`),
  CONSTRAINT `hosts_ibfk_1` FOREIGN KEY (`customer`) REFERENCES `list_customer` (`customer`)
) ENGINE=InnoDB AUTO_INCREMENT=470 DEFAULT CHARSET=latin1;

--
-- Table structure for table `list_customer`
--

DROP TABLE IF EXISTS `list_customer`;
CREATE TABLE `list_customer` (
  `customer` varchar(100) NOT NULL default '',
  `representative` varchar(100) default NULL,
  `status` enum('Production','Beta','Demo','Offsite','Decomm.','Dead') default NULL,
  `notes` text,
  PRIMARY KEY  (`customer`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `list_entitytype`
--

DROP TABLE IF EXISTS `list_entitytype`;
CREATE TABLE `list_entitytype` (
  `type` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `network`
--

DROP TABLE IF EXISTS `network`;
CREATE TABLE `network` (
  `address` varchar(17) NOT NULL default '',
  `host_id` int(11) default NULL,
  `host_interface` varchar(10) default NULL,
  `switch_id` int(11) default NULL,
  `port` varchar(10) default NULL,
  `current_speed` varchar(10) default NULL,
  `max_speed` varchar(10) default NULL,
  `link_detected` int(11) default '-1',
  `notes` text,
  `created` timestamp NOT NULL default '0000-00-00 00:00:00',
  `last_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`address`),
  KEY `host_id` (`host_id`),
  KEY `ethernet_host_id` (`host_id`),
  KEY `ethernet_switch_id` (`switch_id`),
  CONSTRAINT `network_ibfk_1` FOREIGN KEY (`host_id`) REFERENCES `hosts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Table structure for table `reports`
--

DROP TABLE IF EXISTS `reports`;
CREATE TABLE `reports` (
  `name` varchar(25) NOT NULL,
  `part` int(11) NOT NULL,
  `report` text,
  `last_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`name`,`part`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `reports_historic`
--

DROP TABLE IF EXISTS `reports_historic`;
CREATE TABLE `reports_historic` (
  `name` varchar(25) NOT NULL,
  `date` datetime NOT NULL,
  `report` text,
  `last_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`name`,`date`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `switches`
--

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

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

