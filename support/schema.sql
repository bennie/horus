-- MySQL dump 10.9
--
-- Host: localhost    Database: horus
-- ------------------------------------------------------
-- Server version	4.1.20

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `ethernet`
--

DROP TABLE IF EXISTS `ethernet`;
CREATE TABLE `ethernet` (
  `address` varchar(17) NOT NULL default '',
  `host_id` int(11) default NULL,
  `host_interface` varchar(10) default NULL,
  `switch_id` int(11) default NULL,
  `port` varchar(10) default NULL,
  `current_speed` varchar(10) default NULL,
  `max_speed` varchar(10) default NULL,
  `link_detected` int(11) default '-1',
  `notes` text,
  `last_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`address`),
  KEY `ethernet_host_id` (`host_id`),
  KEY `ethernet_switch_id` (`switch_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `hosts`
--

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
  `vm` int(11) default '-1',
  `vmhost` varchar(255) default NULL,
  `notes` text,
  `last_modified` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `customer` varchar(100) default NULL,
  PRIMARY KEY  (`id`),
  KEY `hosts_name` (`name`),
  KEY `customer` (`customer`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `list_customer`
--

DROP TABLE IF EXISTS `list_customer`;
CREATE TABLE `list_customer` (
  `customer` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`customer`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `list_entitytype`
--

DROP TABLE IF EXISTS `list_entitytype`;
CREATE TABLE `list_entitytype` (
  `type` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`type`)
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

