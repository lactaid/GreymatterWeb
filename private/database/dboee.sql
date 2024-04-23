-- MySQL dump 10.13  Distrib 8.0.33, for Win64 (x86_64)
--
-- Host: localhost    Database: oeee_visual
-- ------------------------------------------------------
-- Server version	8.0.33

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `error`
--

DROP TABLE IF EXISTS `error`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `error` (
  `idError` int NOT NULL,
  `Faultmode` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`idError`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `error`
--

LOCK TABLES `error` WRITE;
/*!40000 ALTER TABLE `error` DISABLE KEYS */;
INSERT INTO `error` VALUES (1,'Power'),(2,'Stuck'),(3,'Material');
/*!40000 ALTER TABLE `error` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `error_instance`
--

DROP TABLE IF EXISTS `error_instance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `error_instance` (
  `ID_ErrorInstance` int NOT NULL AUTO_INCREMENT,
  `ID_Error` int NOT NULL,
  `Machine_ID` int NOT NULL,
  `Error_time` datetime NOT NULL,
  `Finished_time` datetime DEFAULT NULL,
  `operation_result` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`ID_ErrorInstance`),
  KEY `error_machineFK_idx` (`Machine_ID`),
  KEY `errorFK` (`ID_Error`),
  CONSTRAINT `error_machineFK` FOREIGN KEY (`Machine_ID`) REFERENCES `machine` (`idMachine`),
  CONSTRAINT `errorFK` FOREIGN KEY (`ID_Error`) REFERENCES `error` (`idError`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `error_instance`
--

LOCK TABLES `error_instance` WRITE;
/*!40000 ALTER TABLE `error_instance` DISABLE KEYS */;
INSERT INTO `error_instance` VALUES (1,2,1,'2024-04-05 11:51:02','2024-04-05 12:17:46',NULL),(2,1,1,'2024-04-05 12:39:14','2024-04-05 12:40:01',NULL),(3,3,1,'2024-04-05 14:55:27','2024-04-05 14:55:50',NULL),(4,3,1,'2024-04-05 14:56:10','2024-04-05 14:56:19',NULL);
/*!40000 ALTER TABLE `error_instance` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `before_error_instance_insert` BEFORE INSERT ON `error_instance` FOR EACH ROW BEGIN
    DECLARE existe INT;
    SET existe = 0;
    
    -- Verificar si la tupla ya existe
    SELECT COUNT(*) INTO existe FROM oeee_visual.error_instance 
    WHERE finished_time IS NULL
    AND Machine_ID = NEW.Machine_ID
    AND Error_time >= curdate()
	AND Error_time < curdate() + INTERVAL 1 DAY;
    
    IF existe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La máquina ya tiene un error';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `after_error_instance_insert` AFTER INSERT ON `error_instance` FOR EACH ROW UPDATE oeee_visual.machine
    SET state = 'Blocked'
    WHERE idMachine = NEW.Machine_ID */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `machine`
--

DROP TABLE IF EXISTS `machine`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `machine` (
  `idMachine` int NOT NULL AUTO_INCREMENT,
  `state` varchar(20) NOT NULL,
  `type` int NOT NULL,
  `place` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`idMachine`),
  KEY `ty_idx` (`type`),
  CONSTRAINT `typeFK` FOREIGN KEY (`type`) REFERENCES `type` (`idType`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `machine`
--

LOCK TABLES `machine` WRITE;
/*!40000 ALTER TABLE `machine` DISABLE KEYS */;
INSERT INTO `machine` VALUES (1,'Blocked',3,'A1'),(2,'Operative',3,'A2'),(3,'Operative',2,'A3');
/*!40000 ALTER TABLE `machine` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `production`
--

DROP TABLE IF EXISTS `production`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `production` (
  `Machine_ID` int NOT NULL,
  `production_time` datetime NOT NULL,
  `produced` int NOT NULL,
  PRIMARY KEY (`Machine_ID`,`production_time`),
  CONSTRAINT `productionFK` FOREIGN KEY (`Machine_ID`) REFERENCES `machine` (`idMachine`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `production`
--

LOCK TABLES `production` WRITE;
/*!40000 ALTER TABLE `production` DISABLE KEYS */;
INSERT INTO `production` VALUES (1,'2024-04-05 12:24:32',5),(1,'2024-04-05 15:36:04',4),(1,'2024-04-05 15:36:14',6),(1,'2024-04-05 15:36:24',6),(1,'2024-04-05 15:36:34',5),(1,'2024-04-05 15:36:44',5),(1,'2024-04-05 15:42:06',4),(1,'2024-04-05 15:42:16',4),(1,'2024-04-05 15:42:26',6),(1,'2024-04-05 15:42:36',5),(1,'2024-04-05 15:42:47',6),(1,'2024-04-05 15:42:57',6),(1,'2024-04-05 15:43:07',4);
/*!40000 ALTER TABLE `production` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `repair`
--

DROP TABLE IF EXISTS `repair`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `repair` (
  `ErrorInstance` int NOT NULL,
  `technician` int NOT NULL,
  `Comment` varchar(45) DEFAULT NULL,
  `Asigned_time` datetime NOT NULL,
  PRIMARY KEY (`ErrorInstance`,`technician`),
  KEY `technicianFK_idx` (`technician`),
  CONSTRAINT `error_instanceFK` FOREIGN KEY (`ErrorInstance`) REFERENCES `error_instance` (`ID_ErrorInstance`),
  CONSTRAINT `technicianFK` FOREIGN KEY (`technician`) REFERENCES `technician` (`idtechnician`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `repair`
--

LOCK TABLES `repair` WRITE;
/*!40000 ALTER TABLE `repair` DISABLE KEYS */;
INSERT INTO `repair` VALUES (1,1,NULL,'2024-04-05 12:12:21'),(2,1,NULL,'2024-04-05 12:39:37'),(2,2,NULL,'2024-04-05 12:39:48');
/*!40000 ALTER TABLE `repair` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `technician`
--

DROP TABLE IF EXISTS `technician`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `technician` (
  `idtechnician` int NOT NULL,
  `name` varchar(45) NOT NULL,
  `lastname` varchar(45) NOT NULL,
  `mail` varchar(45) NOT NULL,
  PRIMARY KEY (`idtechnician`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `technician`
--

LOCK TABLES `technician` WRITE;
/*!40000 ALTER TABLE `technician` DISABLE KEYS */;
INSERT INTO `technician` VALUES (1,'Juan','Escobar','juanescobar@example.com'),(2,'Carlos','Ramirez','carlosr@example.com');
/*!40000 ALTER TABLE `technician` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `type`
--

DROP TABLE IF EXISTS `type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `type` (
  `idType` int NOT NULL,
  `name` varchar(45) DEFAULT NULL,
  `Avg_pr` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`idType`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `type`
--

LOCK TABLES `type` WRITE;
/*!40000 ALTER TABLE `type` DISABLE KEYS */;
INSERT INTO `type` VALUES (1,'Manual',50.00),(2,'Semi',100.00),(3,'Auto',120.00);
/*!40000 ALTER TABLE `type` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2024-04-05 15:49:03
