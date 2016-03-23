-- MySQL dump 10.13  Distrib 5.1.73, for redhat-linux-gnu (x86_64)
--
-- Host: localhost    Database: lxj
-- ------------------------------------------------------
-- Server version	5.1.73

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `x_role`
--

DROP TABLE IF EXISTS `x_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `x_role` (
  `roleid` int(11) NOT NULL AUTO_INCREMENT COMMENT 'auto increment id in the database',
  `name` varchar(20) NOT NULL DEFAULT '' COMMENT 'role name',
  `acc` varchar(64) NOT NULL DEFAULT '' COMMENT 'acc',
  `base` blob COMMENT '玩家基本信息大字段',
  `info` blob COMMENT '玩家详细信息大字段',
  `gmlevel` int(11) NOT NULL COMMENT 'gm等级',
  `create_time` varchar(128) NOT NULL DEFAULT '' COMMENT 'create_time',
  PRIMARY KEY (`roleid`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='role';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `x_item`
--

DROP TABLE IF EXISTS `x_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `x_item` (
  `roleid` int(11) NOT NULL COMMENT 'role uid',
  `data` blob COMMENT 'items',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='item';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `x_task`
--

DROP TABLE IF EXISTS `x_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `x_task` (
  `roleid` int(11) NOT NULL COMMENT 'role uid',
  `data` blob COMMENT 'tasks',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='task';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `x_ectype_fast`
--

DROP TABLE IF EXISTS `x_ectype_fast`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `x_ectype_fast` (
  `id` int(11) NOT NULL COMMENT 'ectype id',
  `data` blob COMMENT 'data',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='ectype_fast';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `x_card`
--

DROP TABLE IF EXISTS `x_card`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;

CREATE TABLE `x_card` (
      `roleid` int(11) NOT NULL COMMENT 'role uid',
      `data` blob COMMENT 'cards',
      PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='card';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `x_club_info``
--

DROP TABLE IF EXISTS `x_club_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;

CREATE TABLE `x_club_info` (
      `roleid` int(11) NOT NULL COMMENT 'role uid',
      `data` blob COMMENT 'data',
      PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='club_info';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `x_ladder_info``
--

DROP TABLE IF EXISTS `x_ladder_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;

CREATE TABLE `x_ladder_info` (
      `roleid` int(11) NOT NULL COMMENT 'role uid',
      `data` blob COMMENT 'data',
	  `rank` int(11) NOT NULL COMMENT '赛季',
      PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='ladder_info';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `x_mail`
--

DROP TABLE IF EXISTS `x_mail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `x_mail` (
  `roleid` int(11) NOT NULL COMMENT 'role uid',
  `data` blob COMMENT 'mails',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='mail';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `x_recharge`
--

DROP TABLE IF EXISTS `x_recharge`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `x_recharge` (
  `roleid` int(11) NOT NULL COMMENT 'role uid',
  `data` blob COMMENT 'recharge order ',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='recharge';
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

--
-- Table structure for table `x_exchange_code`
--

DROP TABLE IF EXISTS `x_exchange`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `x_exchange` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'index',
  `exchange` varchar(128) NOT NULL DEFAULT '' COMMENT 'code name',
  `batchid` int(11) NOT NULL COMMENT '兑换码批次id',
  `exchange_type` int(11) NOT NULL COMMENT '兑换码类型',
  `gift_treasure` varchar(64) NOT NULL DEFAULT '' COMMENT '礼包组',
  `use_level` int(11) NOT NULL COMMENT '使用等级',
  `effective_time` varchar(128) NOT NULL DEFAULT '' COMMENT '使用日期区间',
  `roleid` int(11) NOT NULL COMMENT 'role uid',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='exchange_code';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `x_special_ectype`
--
DROP TABLE IF EXISTS `x_special_ectype`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `x_special_ectype` (
  `roleid` int(11) NOT NULL COMMENT 'role uid',
  `data` blob COMMENT 'special_ectype_data',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='special_ectype';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `x_special_ectype`
--
DROP TABLE IF EXISTS `x_endless_tower`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `x_endless_tower` (
  `roleid` int(11) NOT NULL COMMENT 'role uid',
  `data` blob COMMENT 'endless_tower',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='endless_tower';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `x_activity_money`
--
DROP TABLE IF EXISTS `x_activity_money`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `x_activity_money` (
  `roleid` int(11) NOT NULL COMMENT 'role uid',
  `name` varchar(20) NOT NULL DEFAULT '' COMMENT 'role name',
  `reward_money` int(11) NOT NULL,
  `difficulty` int(11) NOT NULL,
  PRIMARY KEY (`roleid`,`difficulty`)
)  ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='activity_money';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `x_activity_exp`
--
DROP TABLE IF EXISTS `x_activity_exp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `x_activity_exp` (
  `roleid` int(11) NOT NULL COMMENT 'role uid',
  `name` varchar(20) NOT NULL DEFAULT '' COMMENT 'role name',
  `over_time` int(32) NOT NULL,
  `difficulty` int(11) NOT NULL,
  `date_time` int(11) NOT NULL,
  `rank` int(11) NOT NULL,
  PRIMARY KEY (`roleid`,`difficulty`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='activity_exp';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `x_activity`
--
DROP TABLE IF EXISTS `x_activity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `x_activity` (
  `roleid` int(11) NOT NULL COMMENT 'role uid',
  `data` blob COMMENT 'data',
  PRIMARY KEY (`roleid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='activity';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `x_game_key`
--
DROP TABLE IF EXISTS `x_game_key`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `x_game_key` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'index',
  `game_key` varchar(128) NOT NULL DEFAULT '' COMMENT '激活码',
  `acc` varchar(128) NOT NULL DEFAULT '' COMMENT '账户名',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='game_key';
/*!40101 SET character_set_client = @saved_cs_client */;

-- Dump completed on 2014-09-21 11:47:05
