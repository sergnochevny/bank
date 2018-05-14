-- --------------------------------------------------------
-- Хост:                         127.0.0.1
-- Версия сервера:               5.6.34-log - MySQL Community Server (GPL)
-- Операционная система:         Win64
-- HeidiSQL Версия:              9.4.0.5125
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

-- Дамп структуры для таблица bank.key_storage
DROP TABLE IF EXISTS `key_storage`;
CREATE TABLE IF NOT EXISTS `key_storage` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key` varchar(128) NOT NULL,
  `value` text NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп структуры для таблица bank.url_sef
DROP TABLE IF EXISTS `url_sef`;
CREATE TABLE IF NOT EXISTS `url_sef` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` varchar(250) NOT NULL,
  `sef` varchar(250) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `url` (`url`),
  UNIQUE KEY `sef` (`sef`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп структуры для таблица bank.account
DROP TABLE IF EXISTS `account`;
CREATE TABLE IF NOT EXISTS `account` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `contract_id` int(11) unsigned NOT NULL,
  `amount` decimal(10,4) NOT NULL DEFAULT '0.0000',
  `created_at` int(11) unsigned NOT NULL,
  `updated_at` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `account_contract_id_fk` (`contract_id`),
  CONSTRAINT `account_contract_id_fk` FOREIGN KEY (`contract_id`) REFERENCES `contract` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- Дамп данных таблицы bank.account: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `account` DISABLE KEYS */;
INSERT INTO `account` (`id`, `contract_id`, `amount`, `created_at`, `updated_at`) VALUES
	(1, 3, 2000.0000, 1526158800, 4294967295);
/*!40000 ALTER TABLE `account` ENABLE KEYS */;

-- Дамп структуры для таблица bank.account_type
DROP TABLE IF EXISTS `account_type`;
CREATE TABLE IF NOT EXISTS `account_type` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `created_at` int(11) unsigned NOT NULL,
  `updated_at` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

-- Дамп данных таблицы bank.account_type: ~2 rows (приблизительно)
/*!40000 ALTER TABLE `account_type` DISABLE KEYS */;
INSERT INTO `account_type` (`id`, `name`, `created_at`, `updated_at`) VALUES
	(1, 'deposit', 1526211660, NULL),
	(2, 'credit', 1526211670, NULL);
/*!40000 ALTER TABLE `account_type` ENABLE KEYS */;

-- Дамп структуры для процедура bank.calculate_by_account
DROP PROCEDURE IF EXISTS `calculate_by_account`;
DELIMITER //
CREATE DEFINER=`root`@`%` PROCEDURE `calculate_by_account`(
  IN inOnDate        INT UNSIGNED,
  IN inAccountId     INT UNSIGNED,
  IN inContractId    INT UNSIGNED,
  IN inCalculationId INT UNSIGNED
)
BEGIN

    DECLARE ContinueSuite BOOLEAN DEFAULT TRUE;
    DECLARE CurrentHandler VARCHAR(50);

    DECLARE handlers_cur CURSOR FOR
      SELECT name
      FROM calculation_handler
      WHERE calculation_id = inCalculationId
      ORDER BY priority ASC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET ContinueSuite = FALSE;

    OPEN handlers_cur;

    WHILE ContinueSuite DO

      FETCH handlers_cur
      INTO CurrentHandler;

      CALL call_handler(
          CurrentHandler,
          inOnDate,
          inAccountId,
          inContractId
      );

    END WHILE;

    CLOSE handlers_cur;

  END//
DELIMITER ;

-- Дамп структуры для таблица bank.calculation
DROP TABLE IF EXISTS `calculation`;
CREATE TABLE IF NOT EXISTS `calculation` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `account_type_id` int(11) unsigned NOT NULL,
  `name` varchar(50) NOT NULL,
  `created_at` int(11) unsigned NOT NULL,
  `updated_at` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `calculation_account_type_id_fk` (`account_type_id`),
  CONSTRAINT `calculation_account_type_id_fk` FOREIGN KEY (`account_type_id`) REFERENCES `account_type` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- Дамп данных таблицы bank.calculation: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `calculation` DISABLE KEYS */;
INSERT INTO `calculation` (`id`, `account_type_id`, `name`, `created_at`, `updated_at`) VALUES
	(1, 1, 'default', 1557705600, NULL);
/*!40000 ALTER TABLE `calculation` ENABLE KEYS */;

-- Дамп структуры для таблица bank.calculation_handler
DROP TABLE IF EXISTS `calculation_handler`;
CREATE TABLE IF NOT EXISTS `calculation_handler` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `calculation_id` int(11) unsigned NOT NULL,
  `name` varchar(50) NOT NULL,
  `priority` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `created_at` int(11) unsigned NOT NULL,
  `updated_at` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `calculation_handler_calculation_id_fk` (`calculation_id`),
  CONSTRAINT `calculation_handler_calculation_id_fk` FOREIGN KEY (`calculation_id`) REFERENCES `calculation` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

-- Дамп данных таблицы bank.calculation_handler: ~2 rows (приблизительно)
/*!40000 ALTER TABLE `calculation_handler` DISABLE KEYS */;
INSERT INTO `calculation_handler` (`id`, `calculation_id`, `name`, `priority`, `created_at`, `updated_at`) VALUES
	(1, 1, 'deposit_calculation_default', 0, 1557705600, NULL),
	(2, 1, 'deposit_calculation_commission_default', 1, 1557705600, NULL);
/*!40000 ALTER TABLE `calculation_handler` ENABLE KEYS */;

-- Дамп структуры для процедура bank.calculation_start
DROP PROCEDURE IF EXISTS `calculation_start`;
DELIMITER //
CREATE DEFINER=`root`@`%` PROCEDURE `calculation_start`(IN inOnDate INT(11) UNSIGNED)
BEGIN
    DECLARE ContinueSuite BOOLEAN DEFAULT TRUE;
    DECLARE AccountId INT UNSIGNED;
    DECLARE ContractId INT UNSIGNED;
    DECLARE CalculationId INT UNSIGNED;

    DECLARE contracts_cur CURSOR FOR
      SELECT
        account_id,
        contract_id,
        calculation_id
      FROM contracts_calculation_prms
      WHERE month_day = dayofmonth(inOnDate);

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET ContinueSuite = FALSE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION ROLLBACK;
    DECLARE EXIT HANDLER FOR SQLWARNING ROLLBACK;
    DECLARE EXIT HANDLER FOR SQLSTATE '45000' ROLLBACK;

    OPEN contracts_cur;

    WHILE ContinueSuite DO

      FETCH contracts_cur
      INTO AccountId,
        ContractId,
        CalculationId;

      START TRANSACTION;
      CALL calculate_by_account(
          inOnDate,
          AccountId,
          ContractId,
          CalculationId
      );
      COMMIT;

    END WHILE;

    CLOSE contracts_cur;
  END//
DELIMITER ;

-- Дамп структуры для процедура bank.call_handler
DROP PROCEDURE IF EXISTS `call_handler`;
DELIMITER //
CREATE DEFINER=`root`@`%` PROCEDURE `call_handler`(
  IN inCallHandler VARCHAR(50),
  IN inOnDate      INT UNSIGNED,
  IN inAccountId   INT UNSIGNED,
  IN inContractId  INT UNSIGNED
)
BEGIN

    SET @Q = CONCAT('CALL ', inCallHandler, '(?, ?, ?)');

    PREPARE QUERY FROM @Q;
    EXECUTE QUERY
    USING @inOnDate, @inAccountId, @inContractId;
    DEALLOCATE PREPARE QUERY;

  END//
DELIMITER ;

-- Дамп структуры для таблица bank.client
DROP TABLE IF EXISTS `client`;
CREATE TABLE IF NOT EXISTS `client` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `id_number` varchar(50) NOT NULL,
  ` sex` tinyint(1) unsigned NOT NULL,
  `birth_day` int(11) unsigned NOT NULL,
  `created_at` int(11) unsigned NOT NULL,
  `updated_at` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_number` (`id_number`),
  KEY `client_birth_day_index` (`birth_day`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- Дамп данных таблицы bank.client: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `client` DISABLE KEYS */;
INSERT INTO `client` (`id`, `name`, `last_name`, `id_number`, ` sex`, `birth_day`, `created_at`, `updated_at`) VALUES
	(1, 'test', 'test', 'sdklfghdslkfj3543545', 1, 181699200, 1526169600, NULL);
/*!40000 ALTER TABLE `client` ENABLE KEYS */;

-- Дамп структуры для таблица bank.condition
DROP TABLE IF EXISTS `condition`;
CREATE TABLE IF NOT EXISTS `condition` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `contract_id` int(11) unsigned NOT NULL,
  `calculation_id` int(11) unsigned NOT NULL,
  `percent` decimal(10,4) NOT NULL DEFAULT '0.0000',
  `created_at` int(11) unsigned NOT NULL,
  `updated_at` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `condition_contract_id_fk` (`contract_id`),
  KEY `condition_calculation_id_fk` (`calculation_id`),
  CONSTRAINT `condition_calculation_id_fk` FOREIGN KEY (`calculation_id`) REFERENCES `calculation` (`id`) ON DELETE CASCADE,
  CONSTRAINT `condition_contract_id_fk` FOREIGN KEY (`contract_id`) REFERENCES `contract` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- Дамп данных таблицы bank.condition: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `condition` DISABLE KEYS */;
INSERT INTO `condition` (`id`, `contract_id`, `calculation_id`, `percent`, `created_at`, `updated_at`) VALUES
	(1, 3, 1, 0.2000, 1526158800, 4294967295);
/*!40000 ALTER TABLE `condition` ENABLE KEYS */;

-- Дамп структуры для таблица bank.contract
DROP TABLE IF EXISTS `contract`;
CREATE TABLE IF NOT EXISTS `contract` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `client_id` int(11) unsigned NOT NULL,
  `account_type_id` int(11) unsigned NOT NULL,
  `amount` decimal(10,4) NOT NULL,
  `begin_at` int(11) unsigned NOT NULL,
  `end_at` int(11) unsigned DEFAULT NULL,
  `created_at` int(11) unsigned NOT NULL,
  `updated_at` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `contract_client_id_fk` (`client_id`),
  KEY `contract_account_type_id_fk` (`account_type_id`),
  CONSTRAINT `contract_account_type_id_fk` FOREIGN KEY (`account_type_id`) REFERENCES `account_type` (`id`) ON DELETE CASCADE,
  CONSTRAINT `contract_client_id_fk` FOREIGN KEY (`client_id`) REFERENCES `client` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

-- Дамп данных таблицы bank.contract: ~1 rows (приблизительно)
/*!40000 ALTER TABLE `contract` DISABLE KEYS */;
INSERT INTO `contract` (`id`, `client_id`, `account_type_id`, `amount`, `begin_at`, `end_at`, `created_at`, `updated_at`) VALUES
	(3, 1, 1, 2000.0000, 1526169600, 1557705600, 1526169690, 4294967295);
/*!40000 ALTER TABLE `contract` ENABLE KEYS */;

-- Дамп структуры для представление bank.contracts_calculation_prms
DROP VIEW IF EXISTS `contracts_calculation_prms`;
-- Создание временной таблицы для обработки ошибок зависимостей представлений
CREATE TABLE `contracts_calculation_prms` (
	`account_id` INT(11) UNSIGNED NOT NULL,
	`contract_id` INT(11) UNSIGNED NOT NULL,
	`calculation_id` INT(11) UNSIGNED NOT NULL,
	`month_day` TINYINT(4) UNSIGNED NOT NULL
) ENGINE=MyISAM;

-- Дамп структуры для таблица bank.contract_features
DROP TABLE IF EXISTS `contract_features`;
CREATE TABLE IF NOT EXISTS `contract_features` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `contract_id` int(11) unsigned DEFAULT NULL,
  `month_day` tinyint(4) unsigned NOT NULL,
  `last_month_day` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `closed` tinyint(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `contract_features_contract_id_fk` (`contract_id`),
  KEY `contract_features_month_day_index` (`month_day`),
  KEY `contract_features_closed_index` (`closed`),
  CONSTRAINT `contract_features_contract_id_fk` FOREIGN KEY (`contract_id`) REFERENCES `contract` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

-- Дамп данных таблицы bank.contract_features: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `contract_features` DISABLE KEYS */;
INSERT INTO `contract_features` (`id`, `contract_id`, `month_day`, `last_month_day`, `closed`) VALUES
	(3, 3, 13, 0, 0);
/*!40000 ALTER TABLE `contract_features` ENABLE KEYS */;

-- Дамп структуры для процедура bank.deposit_calculation_commission_default
DROP PROCEDURE IF EXISTS `deposit_calculation_commission_default`;
DELIMITER //
CREATE DEFINER=`root`@`%` PROCEDURE `deposit_calculation_commission_default`(
  IN  inAmount   DECIMAL(10, 4),
  IN  inOnDate   INT(11) UNSIGNED,
  OUT commission DECIMAL(10, 4)
)
BEGIN

    SET commission = 0.00;

    IF DAYOFMONTH(LAST_DAY(FROM_UNIXTIME(inOnDate))) = DAYOFMONTH(FROM_UNIXTIME(inOnDate))
    THEN

      CASE
        WHEN inAmount < 1000
        THEN
          SET commission = inAmount * 0.05;
          IF commission < 50.00
          THEN
            SET commission = 50.00;
          END IF;
        WHEN inAmount <= 10000
        THEN
          SET commission = inAmount * 0.06;
      ELSE
        SET commission = inAmount * 0.07;
        IF commission > 5000.00
        THEN
          SET commission = 5000.00;
        END IF;
      END CASE;

    END IF;
    
  END//
DELIMITER ;

-- Дамп структуры для процедура bank.deposit_calculation_default
DROP PROCEDURE IF EXISTS `deposit_calculation_default`;
DELIMITER //
CREATE DEFINER=`root`@`%` PROCEDURE `deposit_calculation_default`(
  IN    inPercent DECIMAL(10, 4),
  IN    inPerDays INT,
  IN    inMonthDays INT,
  INOUT inAmount  DECIMAL(10, 4))
BEGIN
    SET inAmount = inAmount + inAmount * inPercent * inPerDays / inMonthDays;
  END//
DELIMITER ;

-- Дамп структуры для таблица bank.fk
DROP TABLE IF EXISTS `fk`;
CREATE TABLE IF NOT EXISTS `fk` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `transaction_id` int(11) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_transaction_id_fk` (`transaction_id`),
  CONSTRAINT `fk_transaction_id_fk` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы bank.fk: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `fk` DISABLE KEYS */;
/*!40000 ALTER TABLE `fk` ENABLE KEYS */;

-- Дамп структуры для таблица bank.transactions
DROP TABLE IF EXISTS `transactions`;
CREATE TABLE IF NOT EXISTS `transactions` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `account_id` int(11) unsigned NOT NULL,
  `debet` decimal(10,4) NOT NULL DEFAULT '0.0000',
  `credit` decimal(10,4) NOT NULL DEFAULT '0.0000',
  `created_at` int(11) unsigned NOT NULL,
  `updated_at` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `transactions_account_id_fk` (`account_id`),
  CONSTRAINT `transactions_account_id_fk` FOREIGN KEY (`account_id`) REFERENCES `account` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Дамп данных таблицы bank.transactions: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `transactions` DISABLE KEYS */;
/*!40000 ALTER TABLE `transactions` ENABLE KEYS */;

-- Дамп структуры для триггер bank.tr_account_bi
DROP TRIGGER IF EXISTS `tr_account_bi`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_account_bi` BEFORE INSERT ON `account` FOR EACH ROW BEGIN

    SET NEW.created_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_account_bu
DROP TRIGGER IF EXISTS `tr_account_bu`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_account_bu` BEFORE UPDATE ON `account` FOR EACH ROW BEGIN

    SET NEW.updated_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_account_type_bi
DROP TRIGGER IF EXISTS `tr_account_type_bi`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_account_type_bi` BEFORE INSERT ON `account_type` FOR EACH ROW BEGIN

    SET NEW.created_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_account_type_bu
DROP TRIGGER IF EXISTS `tr_account_type_bu`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_account_type_bu` BEFORE UPDATE ON `account_type` FOR EACH ROW BEGIN

    SET NEW.updated_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_calculation_bi
DROP TRIGGER IF EXISTS `tr_calculation_bi`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_calculation_bi` BEFORE INSERT ON `calculation` FOR EACH ROW BEGIN

    SET NEW.created_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_calculation_bu
DROP TRIGGER IF EXISTS `tr_calculation_bu`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_calculation_bu` BEFORE UPDATE ON `calculation` FOR EACH ROW BEGIN

    SET NEW.updated_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_calculation_handler_bi
DROP TRIGGER IF EXISTS `tr_calculation_handler_bi`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_calculation_handler_bi` BEFORE INSERT ON `calculation_handler` FOR EACH ROW BEGIN

    SET NEW.created_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_calculation_handler_bu
DROP TRIGGER IF EXISTS `tr_calculation_handler_bu`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_calculation_handler_bu` BEFORE UPDATE ON `calculation_handler` FOR EACH ROW BEGIN

    SET NEW.updated_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_client_bi
DROP TRIGGER IF EXISTS `tr_client_bi`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_client_bi` BEFORE INSERT ON `client` FOR EACH ROW BEGIN

    SET NEW.created_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_client_bu
DROP TRIGGER IF EXISTS `tr_client_bu`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_client_bu` BEFORE UPDATE ON `client` FOR EACH ROW BEGIN

    SET NEW.updated_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_condition_bi
DROP TRIGGER IF EXISTS `tr_condition_bi`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_condition_bi` BEFORE INSERT ON `condition` FOR EACH ROW BEGIN

    SET NEW.created_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_condition_bu
DROP TRIGGER IF EXISTS `tr_condition_bu`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_condition_bu` BEFORE UPDATE ON `condition` FOR EACH ROW BEGIN

    SET NEW.updated_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_contract_ai
DROP TRIGGER IF EXISTS `tr_contract_ai`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_contract_ai` AFTER INSERT ON `contract` FOR EACH ROW BEGIN

    INSERT INTO account
    SET amount    = NEW.amount,
      contract_id = NEW.id;

    INSERT INTO contract_features
    SET
      contract_id    = NEW.id,
      month_day      = DAYOFMONTH(FROM_UNIXTIME(NEW.begin_at)),
      last_month_day = (DAYOFMONTH(LAST_DAY(FROM_UNIXTIME(NEW.begin_at))) = DAYOFMONTH(FROM_UNIXTIME(NEW.begin_at)));

  END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_contract_au
DROP TRIGGER IF EXISTS `tr_contract_au`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_contract_au` AFTER UPDATE ON `contract` FOR EACH ROW BEGIN

    UPDATE contract_features
    SET month_day    = DAYOFMONTH(FROM_UNIXTIME(NEW.begin_at)),
      last_month_day = (DAYOFMONTH(LAST_DAY(FROM_UNIXTIME(NEW.begin_at))) = DAYOFMONTH(FROM_UNIXTIME(NEW.begin_at)))
    WHERE contract_id = NEW.id;

  END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_contract_bi
DROP TRIGGER IF EXISTS `tr_contract_bi`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_contract_bi` BEFORE INSERT ON `contract` FOR EACH ROW BEGIN

    SET NEW.created_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_contract_bu
DROP TRIGGER IF EXISTS `tr_contract_bu`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_contract_bu` BEFORE UPDATE ON `contract` FOR EACH ROW BEGIN

    SET NEW.updated_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_transactions_bi
DROP TRIGGER IF EXISTS `tr_transactions_bi`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_transactions_bi` BEFORE INSERT ON `transactions` FOR EACH ROW BEGIN

  SET NEW.created_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_transactions_bu
DROP TRIGGER IF EXISTS `tr_transactions_bu`;
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_transactions_bu` BEFORE UPDATE ON `transactions` FOR EACH ROW BEGIN

  SET NEW.updated_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Дамп структуры для представление bank.contracts_calculation_prms
DROP VIEW IF EXISTS `contracts_calculation_prms`;
-- Удаление временной таблицы и создание окончательной структуры представления
DROP TABLE IF EXISTS `contracts_calculation_prms`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `contracts_calculation_prms` AS select `a`.`id` AS `account_id`,`a`.`contract_id` AS `contract_id`,`cc`.`id` AS `calculation_id`,`cf`.`month_day` AS `month_day` from ((((`contract_features` `cf` join `contract` `c` on((`cf`.`contract_id` = `c`.`id`))) join `account` `a` on((`cf`.`contract_id` = `a`.`contract_id`))) left join `condition` `cnd` on((`cf`.`contract_id` = `cnd`.`contract_id`))) join `calculation` `cc` on((`cnd`.`calculation_id` = `cc`.`id`))) where (`cf`.`closed` = 0);

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
