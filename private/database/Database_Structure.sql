-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema OEEE_Visual
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `OEEE_Visual` ;

-- -----------------------------------------------------
-- Schema OEEE_Visual
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `OEEE_Visual` DEFAULT CHARACTER SET utf8 ;
USE `OEEE_Visual` ;

-- -----------------------------------------------------
-- Table `OEEE_Visual`.`Type`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `OEEE_Visual`.`Type` (
  `idType` INT NOT NULL,
  `name` VARCHAR(45) NULL,
  `Avg_pr` DECIMAL(10,2) NULL,
  PRIMARY KEY (`idType`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `OEEE_Visual`.`Machine`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `OEEE_Visual`.`Machine` (
  `idMachine` INT NOT NULL AUTO_INCREMENT,
  `state` VARCHAR(20) NOT NULL,
  `type` INT NOT NULL,
  `place` VARCHAR(45) NULL,
  PRIMARY KEY (`idMachine`),
  INDEX `ty_idx` (`type` ASC) VISIBLE,
  CONSTRAINT `typeFK`
    FOREIGN KEY (`type`)
    REFERENCES `OEEE_Visual`.`Type` (`idType`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `OEEE_Visual`.`Error`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `OEEE_Visual`.`Error` (
  `idError` INT NOT NULL,
  `Faultmode` VARCHAR(45) NULL,
  PRIMARY KEY (`idError`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `OEEE_Visual`.`Production`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `OEEE_Visual`.`Production` (
  `Machine_ID` INT NOT NULL,
  `production_time` DATETIME NOT NULL,
  `produced` INT NOT NULL,
  PRIMARY KEY (`Machine_ID`, `production_time`),
  CONSTRAINT `productionFK`
    FOREIGN KEY (`Machine_ID`)
    REFERENCES `OEEE_Visual`.`Machine` (`idMachine`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `OEEE_Visual`.`Error_instance`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `OEEE_Visual`.`Error_instance` (
  `ID_ErrorInstance` INT NOT NULL AUTO_INCREMENT,
  `ID_Error` INT NOT NULL,
  `Machine_ID` INT NOT NULL,
  `Error_time` DATETIME NOT NULL,
  `Finished_time` DATETIME NULL,
  `operation_result` VARCHAR(20) NULL,
  PRIMARY KEY (`ID_ErrorInstance`),
  INDEX `error_machineFK_idx` (`Machine_ID` ASC) VISIBLE,
  CONSTRAINT `error_machineFK`
    FOREIGN KEY (`Machine_ID`)
    REFERENCES `OEEE_Visual`.`Machine` (`idMachine`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `errorFK`
    FOREIGN KEY (`ID_Error`)
    REFERENCES `OEEE_Visual`.`Error` (`idError`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `OEEE_Visual`.`technician`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `OEEE_Visual`.`technician` (
  `idtechnician` INT NOT NULL,
  `name` VARCHAR(45) NOT NULL,
  `lastname` VARCHAR(45) NOT NULL,
  `mail` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`idtechnician`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `OEEE_Visual`.`Repair`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `OEEE_Visual`.`Repair` (
  `ErrorInstance` INT NOT NULL,
  `technician` INT NOT NULL,
  `Comment` VARCHAR(45) NULL,
  `Asigned_time` DATETIME NOT NULL,
  PRIMARY KEY (`ErrorInstance`, `technician`),
  INDEX `technicianFK_idx` (`technician` ASC) VISIBLE,
  CONSTRAINT `error_instanceFK`
    FOREIGN KEY (`ErrorInstance`)
    REFERENCES `OEEE_Visual`.`Error_instance` (`ID_ErrorInstance`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `technicianFK`
    FOREIGN KEY (`technician`)
    REFERENCES `OEEE_Visual`.`technician` (`idtechnician`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
