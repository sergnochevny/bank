-- --------------------------------------------------------
-- Хост:                         localhost
-- Версия сервера:               5.6.38 - MySQL Community Server (GPL)
-- Операционная система:         Win64
-- HeidiSQL Версия:              9.5.0.5196
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT = @@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS = 0 */;
/*!40101 SET @OLD_SQL_MODE = @@SQL_MODE, SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO' */;

-- Дамп структуры для таблица bank.account
DROP TABLE IF EXISTS `account`;
CREATE TABLE IF NOT EXISTS `account` (
  `id`          int(11) unsigned NOT NULL AUTO_INCREMENT,
  `contract_id` int(11) unsigned NOT NULL,
  `amount`      decimal(10, 4)   NOT NULL DEFAULT '0.0000',
  `created_at`  int(11) unsigned          DEFAULT NULL,
  `updated_at`  int(11) unsigned          DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `account_contract_id_uindex` (`contract_id`),
  KEY `account_contract_id_fk` (`contract_id`),
  CONSTRAINT `account_contract_id_fk` FOREIGN KEY (`contract_id`) REFERENCES `contract` (`id`)
    ON DELETE CASCADE
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8;

-- Дамп данных таблицы bank.account: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `account`
  DISABLE KEYS */;
/*!40000 ALTER TABLE `account`
  ENABLE KEYS */;

-- Дамп структуры для таблица bank.account_type
DROP TABLE IF EXISTS `account_type`;
CREATE TABLE IF NOT EXISTS `account_type` (
  `id`         int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name`       varchar(50)      NOT NULL,
  `created_at` int(11) unsigned          DEFAULT NULL,
  `updated_at` int(11) unsigned          DEFAULT NULL,
  PRIMARY KEY (`id`)
)
  ENGINE = InnoDB
  AUTO_INCREMENT = 3
  DEFAULT CHARSET = utf8;

-- Дамп данных таблицы bank.account_type: ~2 rows (приблизительно)
/*!40000 ALTER TABLE `account_type`
  DISABLE KEYS */;
INSERT INTO `account_type` (`id`, `name`, `created_at`, `updated_at`) VALUES
  (1, 'debit', 1526169600, NULL),
  (2, 'credit', 1526169600, NULL);
/*!40000 ALTER TABLE `account_type`
  ENABLE KEYS */;

-- Дамп структуры для таблица bank.bank_account
DROP TABLE IF EXISTS `bank_account`;
CREATE TABLE IF NOT EXISTS `bank_account` (
  `id`              int(11) unsigned NOT NULL AUTO_INCREMENT,
  `account_type_id` int(11) unsigned NOT NULL,
  `amount`          decimal(10, 4)   NOT NULL DEFAULT '0.0000',
  `created_at`      int(11) unsigned          DEFAULT NULL,
  `updated_at`      int(11) unsigned          DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `bank_account_account_type_id_fk` (`account_type_id`),
  CONSTRAINT `bank_account_account_type_id_fk` FOREIGN KEY (`account_type_id`) REFERENCES `account_type` (`id`)
)
  ENGINE = InnoDB
  AUTO_INCREMENT = 3
  DEFAULT CHARSET = utf8;

-- Дамп данных таблицы bank.bank_account: ~2 rows (приблизительно)
/*!40000 ALTER TABLE `bank_account`
  DISABLE KEYS */;
INSERT INTO `bank_account` (`id`, `account_type_id`, `amount`, `created_at`, `updated_at`) VALUES
  (1, 1, 0.0000, 1526169600, NULL),
  (2, 2, 0.0000, 1526169600, NULL);
/*!40000 ALTER TABLE `bank_account`
  ENABLE KEYS */;

-- Дамп структуры для процедура bank.calculate_by_account
DROP PROCEDURE IF EXISTS `calculate_by_account`;
DELIMITER //
CREATE DEFINER =`root`@`%` PROCEDURE `calculate_by_account`(
  IN inOnDate        INT UNSIGNED,
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

      IF ContinueSuite
      THEN
        CALL call_handler(
            CurrentHandler,
            inOnDate,
            inContractId
        );
      END IF;

    END WHILE;

    CLOSE handlers_cur;

    UPDATE contract_features
    SET last_calc_date = inOnDate
    WHERE contract_id = inContractId;

  END//
DELIMITER ;

-- Дамп структуры для таблица bank.calculation
DROP TABLE IF EXISTS `calculation`;
CREATE TABLE IF NOT EXISTS `calculation` (
  `id`              int(11) unsigned NOT NULL AUTO_INCREMENT,
  `account_type_id` int(11) unsigned NOT NULL,
  `name`            varchar(50)      NOT NULL,
  `created_at`      int(11) unsigned          DEFAULT NULL,
  `updated_at`      int(11) unsigned          DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `calculation_account_type_id_fk` (`account_type_id`),
  CONSTRAINT `calculation_account_type_id_fk` FOREIGN KEY (`account_type_id`) REFERENCES `account_type` (`id`)
)
  ENGINE = InnoDB
  AUTO_INCREMENT = 2
  DEFAULT CHARSET = utf8;

-- Дамп данных таблицы bank.calculation: ~1 rows (приблизительно)
/*!40000 ALTER TABLE `calculation`
  DISABLE KEYS */;
INSERT INTO `calculation` (`id`, `account_type_id`, `name`, `created_at`, `updated_at`) VALUES
  (1, 1, 'default', 1526169600, NULL);
/*!40000 ALTER TABLE `calculation`
  ENABLE KEYS */;

-- Дамп структуры для процедура bank.calculation_for_first_month_day
DROP PROCEDURE IF EXISTS `calculation_for_first_month_day`;
DELIMITER //
CREATE DEFINER =`root`@`%` PROCEDURE `calculation_for_first_month_day`(IN inOnDate INT(11) UNSIGNED)
  BEGIN
    DECLARE ContinueSuite BOOLEAN DEFAULT TRUE;
    DECLARE ContractId INT UNSIGNED;
    DECLARE CalculationId INT UNSIGNED;

    DECLARE contracts_cur CURSOR FOR
      SELECT
        contract_id,
        calculation_id
      FROM contracts_calculation_prms
      WHERE last_calc_date < inOnDate AND
            contract_begin_at < inOnDate AND contract_end_at > inOnDate;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET ContinueSuite = FALSE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION ROLLBACK;
    DECLARE EXIT HANDLER FOR SQLWARNING ROLLBACK;
    DECLARE EXIT HANDLER FOR SQLSTATE '45000' ROLLBACK;

    OPEN contracts_cur;

    WHILE ContinueSuite DO

      FETCH contracts_cur
      INTO
        ContractId,
        CalculationId;

      IF ContinueSuite
      THEN
        START TRANSACTION;
        CALL calculate_by_account(
            inOnDate,
            ContractId,
            CalculationId
        );
        COMMIT;
      END IF;

    END WHILE;

    CLOSE contracts_cur;
  END//
DELIMITER ;

-- Дамп структуры для процедура bank.calculation_for_last_month_day
DROP PROCEDURE IF EXISTS `calculation_for_last_month_day`;
DELIMITER //
CREATE DEFINER =`root`@`%` PROCEDURE `calculation_for_last_month_day`(IN inOnDate INT(11) UNSIGNED)
  BEGIN
    DECLARE ContinueSuite BOOLEAN DEFAULT TRUE;
    DECLARE ContractId INT UNSIGNED;
    DECLARE CalculationId INT UNSIGNED;

    DECLARE contracts_cur CURSOR FOR
      SELECT
        contract_id,
        calculation_id
      FROM contracts_calculation_prms
      WHERE last_month_day = TRUE AND last_calc_date < inOnDate AND
            contract_begin_at < inOnDate AND contract_end_at > inOnDate;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET ContinueSuite = FALSE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION ROLLBACK;
    DECLARE EXIT HANDLER FOR SQLWARNING ROLLBACK;
    DECLARE EXIT HANDLER FOR SQLSTATE '45000' ROLLBACK;

    OPEN contracts_cur;

    WHILE ContinueSuite DO

      FETCH contracts_cur
      INTO
        ContractId,
        CalculationId;

      IF ContinueSuite
      THEN
        START TRANSACTION;
        CALL calculate_by_account(
            inOnDate,
            ContractId,
            CalculationId
        );
        COMMIT;
      END IF;

    END WHILE;

    CLOSE contracts_cur;
  END//
DELIMITER ;

-- Дамп структуры для процедура bank.calculation_for_regular_day
DROP PROCEDURE IF EXISTS `calculation_for_regular_day`;
DELIMITER //
CREATE DEFINER =`root`@`%` PROCEDURE `calculation_for_regular_day`(IN inOnDate INT(11) UNSIGNED)
  BEGIN
    DECLARE ContinueSuite BOOLEAN DEFAULT TRUE;
    DECLARE ContractId INT UNSIGNED;
    DECLARE CalculationId INT UNSIGNED;

    DECLARE contracts_cur CURSOR FOR
      SELECT
        contract_id,
        calculation_id
      FROM contracts_calculation_prms
      WHERE month_day = dayofmonth(from_unixtime(inOnDate))
            AND last_month_day = FALSE AND last_calc_date < inOnDate AND
            contract_begin_at < inOnDate AND contract_end_at > inOnDate;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET ContinueSuite = FALSE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION ROLLBACK;
    DECLARE EXIT HANDLER FOR SQLWARNING ROLLBACK;
    DECLARE EXIT HANDLER FOR SQLSTATE '45000' ROLLBACK;

    OPEN contracts_cur;

    WHILE ContinueSuite DO

      FETCH contracts_cur
      INTO
        ContractId,
        CalculationId;

      IF ContinueSuite
      THEN
        START TRANSACTION;
        CALL calculate_by_account(
            inOnDate,
            ContractId,
            CalculationId
        );
        COMMIT;
      END IF;

    END WHILE;

    CLOSE contracts_cur;
  END//
DELIMITER ;

-- Дамп структуры для таблица bank.calculation_handler
DROP TABLE IF EXISTS `calculation_handler`;
CREATE TABLE IF NOT EXISTS `calculation_handler` (
  `id`             int(11) unsigned    NOT NULL AUTO_INCREMENT,
  `calculation_id` int(11) unsigned    NOT NULL,
  `name`           varchar(50)         NOT NULL,
  `priority`       tinyint(3) unsigned NOT NULL DEFAULT '0',
  `created_at`     int(11) unsigned             DEFAULT NULL,
  `updated_at`     int(11) unsigned             DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `calculation_handler_calculation_id_fk` (`calculation_id`),
  CONSTRAINT `calculation_handler_calculation_id_fk` FOREIGN KEY (`calculation_id`) REFERENCES `calculation` (`id`)
    ON DELETE CASCADE
)
  ENGINE = InnoDB
  AUTO_INCREMENT = 3
  DEFAULT CHARSET = utf8;

-- Дамп данных таблицы bank.calculation_handler: ~2 rows (приблизительно)
/*!40000 ALTER TABLE `calculation_handler`
  DISABLE KEYS */;
INSERT INTO `calculation_handler` (`id`, `calculation_id`, `name`, `priority`, `created_at`, `updated_at`) VALUES
  (1, 1, 'deposit_calculation_default', 0, 1557705600, NULL),
  (2, 1, 'deposit_calculation_commission_default', 1, 1557705600, NULL);
/*!40000 ALTER TABLE `calculation_handler`
  ENABLE KEYS */;

-- Дамп структуры для процедура bank.calculation_start
DROP PROCEDURE IF EXISTS `calculation_start`;
DELIMITER //
CREATE DEFINER =`root`@`%` PROCEDURE `calculation_start`(IN inOnDate INT(11) UNSIGNED)
  BEGIN

    IF DAYOFMONTH(FROM_UNIXTIME(inOnDate)) = DAYOFMONTH(LAST_DAY(FROM_UNIXTIME(inOnDate)))
    THEN
      CALL calculation_for_last_month_day(inOnDate);
    ELSEIF DAYOFMONTH(FROM_UNIXTIME(inOnDate)) = 1
      THEN
        CALL calculation_for_first_month_day(inOnDate);
    ELSE
      CALL calculation_for_regular_day(inOnDate);
    END IF;

  END//
DELIMITER ;

-- Дамп структуры для процедура bank.call_handler
DROP PROCEDURE IF EXISTS `call_handler`;
DELIMITER //
CREATE DEFINER =`root`@`%` PROCEDURE `call_handler`(
  IN inCallHandler VARCHAR(50),
  IN inOnDate      INT(11) UNSIGNED,
  IN inContractId  INT(11) UNSIGNED
)
  BEGIN

    SET @Q = CONCAT('CALL ', inCallHandler, '(?, ?, ?, ?, ?, ?)');
    SET @inOnDate = inOnDate;
    SET @inContractId = inContractId;

    PREPARE Statement FROM @Q;
    EXECUTE Statement
    USING @inOnDate, @inContractId, @AccountId, @BankAccountId, @Debit, @Credit;
    DEALLOCATE PREPARE Statement;

    IF ((@Debit IS NOT NULL) AND (@Debit > 0.00)) OR ((@Credit IS NOT NULL) AND (@Credit > 0.00))
    THEN
      IF @Debit IS NULL
      THEN
        SET @Debit = 0.00;
      END IF;
      IF @Credit IS NULL
      THEN
        SET @Credit = 0.00;
      END IF;
      INSERT INTO transactions
      SET debit = @Debit, credit = @Credit, account_id = @AccountId, bank_account_id = @BankAccountId;
    END IF;
  END//
DELIMITER ;

-- Дамп структуры для таблица bank.client
DROP TABLE IF EXISTS `client`;
CREATE TABLE IF NOT EXISTS `client` (
  `id`         int(11) unsigned    NOT NULL AUTO_INCREMENT,
  `name`       varchar(50)         NOT NULL,
  `last_name`  varchar(50)         NOT NULL,
  `id_number`  varchar(50)         NOT NULL,
  `sex`        tinyint(1) unsigned NOT NULL,
  `birth_day`  int(11) unsigned    NOT NULL,
  `created_at` int(11) unsigned             DEFAULT NULL,
  `updated_at` int(11) unsigned             DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_number` (`id_number`),
  KEY `client_birth_day_index` (`birth_day`)
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8;

-- Дамп данных таблицы bank.client: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `client`
  DISABLE KEYS */;
/*!40000 ALTER TABLE `client`
  ENABLE KEYS */;

-- Дамп структуры для таблица bank.conditions
DROP TABLE IF EXISTS `conditions`;
CREATE TABLE IF NOT EXISTS `conditions` (
  `id`             int(11) unsigned NOT NULL AUTO_INCREMENT,
  `contract_id`    int(11) unsigned NOT NULL,
  `calculation_id` int(11) unsigned NOT NULL,
  `percent`        decimal(10, 4)   NOT NULL DEFAULT '0.0000',
  `created_at`     int(11) unsigned          DEFAULT NULL,
  `updated_at`     int(11) unsigned          DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `conditions_contract_id_fk` (`contract_id`),
  KEY `conditions_calculation_id_fk` (`calculation_id`),
  CONSTRAINT `conditions_calculation_id_fk` FOREIGN KEY (`calculation_id`) REFERENCES `calculation` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `conditions_contract_id_fk` FOREIGN KEY (`contract_id`) REFERENCES `contract` (`id`)
    ON DELETE CASCADE
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8;

-- Дамп данных таблицы bank.conditions: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `conditions`
  DISABLE KEYS */;
/*!40000 ALTER TABLE `conditions`
  ENABLE KEYS */;

-- Дамп структуры для таблица bank.contract
DROP TABLE IF EXISTS `contract`;
CREATE TABLE IF NOT EXISTS `contract` (
  `id`              int(11) unsigned NOT NULL AUTO_INCREMENT,
  `client_id`       int(11) unsigned NOT NULL,
  `account_type_id` int(11) unsigned NOT NULL,
  `amount`          decimal(10, 4)   NOT NULL,
  `begin_at`        int(11) unsigned NOT NULL,
  `end_at`          int(11) unsigned          DEFAULT NULL,
  `created_at`      int(11) unsigned          DEFAULT NULL,
  `updated_at`      int(11) unsigned          DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `contract_client_id_fk` (`client_id`),
  KEY `contract_account_type_id_fk` (`account_type_id`),
  KEY `contract_begin_at_end_at_index` (`begin_at`, `end_at`),
  CONSTRAINT `contract_account_type_id_fk` FOREIGN KEY (`account_type_id`) REFERENCES `account_type` (`id`),
  CONSTRAINT `contract_client_id_fk` FOREIGN KEY (`client_id`) REFERENCES `client` (`id`)
    ON DELETE CASCADE
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8;

-- Дамп данных таблицы bank.contract: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `contract`
  DISABLE KEYS */;
/*!40000 ALTER TABLE `contract`
  ENABLE KEYS */;

-- Дамп структуры для представление bank.contracts_calculation_prms
DROP VIEW IF EXISTS `contracts_calculation_prms`;
-- Создание временной таблицы для обработки ошибок зависимостей представлений
CREATE TABLE `contracts_calculation_prms` (
  `account_id`        INT(11) UNSIGNED    NOT NULL,
  `contract_id`       INT(11) UNSIGNED    NOT NULL,
  `calculation_id`    INT(11) UNSIGNED    NOT NULL,
  `month_day`         TINYINT(4) UNSIGNED NOT NULL,
  `last_month_day`    TINYINT(1)          NOT NULL,
  `last_calc_date`    INT(11) UNSIGNED    NULL,
  `contract_begin_at` INT(11) UNSIGNED    NULL,
  `contract_end_at`   INT(11) UNSIGNED    NULL
)
  ENGINE = MyISAM;

-- Дамп структуры для таблица bank.contract_features
DROP TABLE IF EXISTS `contract_features`;
CREATE TABLE IF NOT EXISTS `contract_features` (
  `id`             int(11) unsigned    NOT NULL AUTO_INCREMENT,
  `contract_id`    int(11) unsigned             DEFAULT NULL,
  `month_day`      tinyint(4) unsigned NOT NULL,
  `last_month_day` tinyint(1)          NOT NULL DEFAULT '0',
  `closed`         tinyint(1) unsigned NOT NULL DEFAULT '0',
  `last_calc_date` int(11) unsigned             DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `contract_features_contract_id_fk` (`contract_id`),
  KEY `contract_features_month_day_last_month_day_last_calc_date_index` (`month_day`, `last_month_day`, `last_calc_date`),
  KEY `contract_features_c_md_lmd_lcd_index` (`closed`, `month_day`, `last_month_day`, `last_calc_date`),
  KEY `contract_features_closed_last_month_day_last_calc_date_index` (`closed`, `last_month_day`, `last_calc_date`),
  KEY `contract_features_closed_last_calc_date_index` (`closed`, `last_calc_date`),
  KEY `contract_features_last_calc_date_index` (`last_calc_date`),
  KEY `contract_features_closed_index` (`closed`),
  CONSTRAINT `contract_features_contract_id_fk` FOREIGN KEY (`contract_id`) REFERENCES `contract` (`id`)
    ON DELETE CASCADE
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8;

-- Дамп структуры для процедура bank.deposit_calculation_commission_default
DROP PROCEDURE IF EXISTS `deposit_calculation_commission_default`;
DELIMITER //
CREATE DEFINER =`root`@`%` PROCEDURE `deposit_calculation_commission_default`(
  IN  inOnDate         INT(11) UNSIGNED,
  IN  inContractId     INT(11) UNSIGNED,
  OUT outAccountId     INT(11) UNSIGNED,
  OUT outBankAccountId INT(11) UNSIGNED,
  OUT outDebit         DECIMAL(10, 4),
  OUT outCredit        DECIMAL(10, 4))
  BEGIN
    DECLARE AccountType VARCHAR(50);
    DECLARE Amount DECIMAL(10, 4);
    DECLARE calcAmount DECIMAL(10, 4);
    DECLARE k INT(11) UNSIGNED;
    DECLARE ContractBeginDate INT(11) UNSIGNED;
    DECLARE LastCalcDate INT(11) UNSIGNED;
    DECLARE LastCalcMeDate INT(11) UNSIGNED;
    DECLARE PrevMonthDate INT(11) UNSIGNED;
    DECLARE OnDay INT(11) UNSIGNED;

    SELECT
      a.amount,
      c.begin_at,
      cf.last_calc_date,
      at.name,
      a.id
    FROM contract c
      JOIN conditions cn ON c.id = cn.contract_id
      JOIN contract_features cf ON c.id = cf.contract_id
      JOIN account_type at ON c.account_type_id = at.id
      LEFT JOIN account a ON c.id = a.contract_id
    WHERE c.id = inContractId
    INTO Amount, ContractBeginDate, LastCalcDate, AccountType, outAccountId;

    SET outDebit = NULL;
    SET outCredit = NULL;
    SET OnDay = DAYOFMONTH(FROM_UNIXTIME(inOnDate));

    IF (Amount > 0) AND (OnDay = 1)
    THEN
      SET LastCalcMeDate = UNIX_TIMESTAMP(
          DATE_SUB(FROM_UNIXTIME(LastCalcDate), INTERVAL DAYOFMONTH(FROM_UNIXTIME(LastCalcDate)) - 1 DAY));
      SET PrevMonthDate = UNIX_TIMESTAMP(DATE_SUB(FROM_UNIXTIME(inOnDate), INTERVAL 1 MONTH));
      IF (LastCalcMeDate = inOnDate)
      THEN
        SET LastCalcMeDate = PrevMonthDate;
      END IF;
      SET k = TIMESTAMPDIFF(MONTH, FROM_UNIXTIME(LastCalcMeDate), FROM_UNIXTIME(inOnDate));

      IF LastCalcMeDate <= ContractBeginDate
      THEN
        SET LastCalcDate = ContractBeginDate;
        IF LastCalcMeDate < PrevMonthDate
        THEN
          SET PrevMonthDate = UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(LastCalcMeDate), INTERVAL 1 MONTH));
          SET k = k - 1 + (TO_DAYS(FROM_UNIXTIME(PrevMonthDate)) - TO_DAYS(FROM_UNIXTIME(LastCalcDate))) /
                          (TO_DAYS(FROM_UNIXTIME(PrevMonthDate)) - TO_DAYS(FROM_UNIXTIME(LastCalcMeDate)));
        ELSE
          SET k = (TO_DAYS(FROM_UNIXTIME(inOnDate)) - TO_DAYS(FROM_UNIXTIME(LastCalcDate))) /
                  (TO_DAYS(FROM_UNIXTIME(inOnDate)) - TO_DAYS(FROM_UNIXTIME(PrevMonthDate)));
        END IF;
      END IF;

      CASE
        WHEN Amount < 1000.00
        THEN
          SET calcAmount = Amount * 0.05 * k;
          SET @minAmount = 50.00 * (TRUNCATE(k, 0) + 1);
          IF calcAmount < @minAmount
          THEN
            SET calcAmount = @minAmount;
          END IF;
        WHEN Amount <= 10000.00
        THEN
          SET calcAmount = Amount * 0.06 * k;
      ELSE
        SET calcAmount = Amount * 0.07 * k;
        SET @maxAmount = 5000.00 * (TRUNCATE(k, 0) + 1);
        IF calcAmount > @maxAmount
        THEN
          SET calcAmount = @maxAmount;
        END IF;
      END CASE;

      IF AccountType = 'debit'
      THEN
        SET outCredit = calcAmount;
      ELSE
        SET outDebit = calcAmount;
      END IF;

      SELECT CAST(`value` AS UNSIGNED)
      FROM key_storage
      WHERE `key` = 'bank_debit_account'
      INTO outBankAccountId;

    END IF;

  END//
DELIMITER ;

-- Дамп структуры для процедура bank.deposit_calculation_default
DROP PROCEDURE IF EXISTS `deposit_calculation_default`;
DELIMITER //
CREATE DEFINER =`root`@`%` PROCEDURE `deposit_calculation_default`(
  IN  inOnDate         INT(11) UNSIGNED,
  IN  inContractId     INT(11) UNSIGNED,
  OUT outAccountId     INT(11) UNSIGNED,
  OUT outBankAccountId INT(11) UNSIGNED,
  OUT outDebit         DECIMAL(10, 4),
  OUT outCredit        DECIMAL(10, 4)
)
  BEGIN
    DECLARE AccountType VARCHAR(50);
    DECLARE Percent DECIMAL(10, 4);
    DECLARE Amount DECIMAL(10, 4);
    DECLARE calcAmount DECIMAL(10, 4);
    DECLARE PerDays INT(11) UNSIGNED;
    DECLARE ContractDays INT(11) UNSIGNED;
    DECLARE ContractBeginDate INT(11) UNSIGNED;
    DECLARE ContractEndDate INT(11) UNSIGNED;
    DECLARE LastCalcDate INT(11) UNSIGNED;
    DECLARE LastMonthDay BOOLEAN DEFAULT FALSE;
    DECLARE ContractLastMonthDay BOOLEAN DEFAULT FALSE;
    DECLARE OnDay INT(11) UNSIGNED;

    SELECT
      cn.percent,
      a.amount,
      c.begin_at,
      c.end_at,
      cf.last_month_day,
      cf.last_calc_date,
      at.name,
      a.id
    FROM contract c
      JOIN conditions cn ON c.id = cn.contract_id
      JOIN contract_features cf ON c.id = cf.contract_id
      JOIN account_type at ON c.account_type_id = at.id
      LEFT JOIN account a ON c.id = a.contract_id
    WHERE c.id = inContractId
    INTO Percent, Amount, ContractBeginDate, ContractEndDate, ContractLastMonthDay, LastCalcDate, AccountType, outAccountId;

    SET outDebit = NULL;
    SET outCredit = NULL;

    IF Amount > 0
    THEN
      SET OnDay = DAYOFMONTH(FROM_UNIXTIME(inOnDate));
      SET LastMonthDay = (OnDay = DAYOFMONTH(LAST_DAY(FROM_UNIXTIME(inOnDate))));
      SET ContractDays = TO_DAYS(FROM_UNIXTIME(ContractEndDate)) - TO_DAYS(FROM_UNIXTIME(ContractBeginDate));
      SET PerDays = TO_DAYS(FROM_UNIXTIME(inOnDate)) - TO_DAYS(FROM_UNIXTIME(LastCalcDate));


      IF (!LastMonthDay AND !ContractLastMonthDay) OR (LastMonthDay AND ContractLastMonthDay)
      THEN
        SET calcAmount = Amount * Percent * PerDays / ContractDays;

        IF AccountType = 'debit'
        THEN
          SET outDebit = calcAmount;
        ELSE
          SET outCredit = calcAmount;
        END IF;

        SELECT CAST(`value` AS UNSIGNED)
        FROM key_storage
        WHERE `key` = 'bank_credit_account'
        INTO outBankAccountId;

      END IF;
    END IF;

  END//
DELIMITER ;

-- Дамп структуры для таблица bank.fk
DROP TABLE IF EXISTS `fk`;
CREATE TABLE IF NOT EXISTS `fk` (
  `id`             int(11) unsigned NOT NULL AUTO_INCREMENT,
  `transaction_id` int(11) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_transaction_id_fk` (`transaction_id`),
  CONSTRAINT `fk_transaction_id_fk` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`)
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8;

-- Дамп данных таблицы bank.fk: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `fk`
  DISABLE KEYS */;
/*!40000 ALTER TABLE `fk`
  ENABLE KEYS */;

-- Дамп структуры для таблица bank.key_storage
DROP TABLE IF EXISTS `key_storage`;
CREATE TABLE IF NOT EXISTS `key_storage` (
  `id`    int(11)      NOT NULL AUTO_INCREMENT,
  `key`   varchar(128) NOT NULL,
  `value` text         NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `key_storage_key_uindex` (`key`)
)
  ENGINE = InnoDB
  AUTO_INCREMENT = 3
  DEFAULT CHARSET = utf8;

-- Дамп данных таблицы bank.key_storage: ~2 rows (приблизительно)
/*!40000 ALTER TABLE `key_storage`
  DISABLE KEYS */;
INSERT INTO `key_storage` (`id`, `key`, `value`) VALUES
  (1, 'bank_debit_account', '1'),
  (2, 'bank_credit_account', '2');
/*!40000 ALTER TABLE `key_storage`
  ENABLE KEYS */;

-- Дамп структуры для таблица bank.transactions
DROP TABLE IF EXISTS `transactions`;
CREATE TABLE IF NOT EXISTS `transactions` (
  `id`              int(11) unsigned NOT NULL AUTO_INCREMENT,
  `account_id`      int(11) unsigned NOT NULL,
  `bank_account_id` int(11) unsigned NOT NULL,
  `debit`           decimal(10, 4)   NOT NULL DEFAULT '0.0000',
  `credit`          decimal(10, 4)   NOT NULL DEFAULT '0.0000',
  `created_at`      int(11) unsigned          DEFAULT NULL,
  `updated_at`      int(11) unsigned          DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `transactions_account_id_fk` (`account_id`),
  KEY `transactions_bank_account_id_fk` (`bank_account_id`),
  CONSTRAINT `transactions_account_id_fk` FOREIGN KEY (`account_id`) REFERENCES `account` (`id`),
  CONSTRAINT `transactions_bank_account_id_fk` FOREIGN KEY (`bank_account_id`) REFERENCES `bank_account` (`id`)
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8;

-- Дамп данных таблицы bank.transactions: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `transactions`
  DISABLE KEYS */;
/*!40000 ALTER TABLE `transactions`
  ENABLE KEYS */;

-- Дамп структуры для таблица bank.url_sef
DROP TABLE IF EXISTS `url_sef`;
CREATE TABLE IF NOT EXISTS `url_sef` (
  `id`  int(11)      NOT NULL AUTO_INCREMENT,
  `url` varchar(250) NOT NULL,
  `sef` varchar(250) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `url_sef_url_uindex` (`url`),
  UNIQUE KEY `url_sef_sef_uindex` (`sef`)
)
  ENGINE = InnoDB
  DEFAULT CHARSET = utf8;

-- Дамп данных таблицы bank.url_sef: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `url_sef`
  DISABLE KEYS */;
/*!40000 ALTER TABLE `url_sef`
  ENABLE KEYS */;

-- Дамп структуры для триггер bank.tr_account_bi
DROP TRIGGER IF EXISTS `tr_account_bi`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_account_bi`
  BEFORE INSERT
  ON `account`
  FOR EACH ROW
  BEGIN

    SET NEW.created_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_account_bu
DROP TRIGGER IF EXISTS `tr_account_bu`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_account_bu`
  BEFORE UPDATE
  ON `account`
  FOR EACH ROW
  BEGIN

    SET NEW.updated_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_account_type_bi
DROP TRIGGER IF EXISTS `tr_account_type_bi`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_account_type_bi`
  BEFORE INSERT
  ON `account_type`
  FOR EACH ROW
  BEGIN

    SET NEW.created_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_account_type_bu
DROP TRIGGER IF EXISTS `tr_account_type_bu`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_account_type_bu`
  BEFORE UPDATE
  ON `account_type`
  FOR EACH ROW
  BEGIN

    SET NEW.updated_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_calculation_bi
DROP TRIGGER IF EXISTS `tr_calculation_bi`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_calculation_bi`
  BEFORE INSERT
  ON `calculation`
  FOR EACH ROW
  BEGIN

    SET NEW.created_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_calculation_bu
DROP TRIGGER IF EXISTS `tr_calculation_bu`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_calculation_bu`
  BEFORE UPDATE
  ON `calculation`
  FOR EACH ROW
  BEGIN

    SET NEW.updated_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_calculation_handler_bi
DROP TRIGGER IF EXISTS `tr_calculation_handler_bi`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_calculation_handler_bi`
  BEFORE INSERT
  ON `calculation_handler`
  FOR EACH ROW
  BEGIN

    SET NEW.created_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_calculation_handler_bu
DROP TRIGGER IF EXISTS `tr_calculation_handler_bu`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_calculation_handler_bu`
  BEFORE UPDATE
  ON `calculation_handler`
  FOR EACH ROW
  BEGIN

    SET NEW.updated_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_client_bi
DROP TRIGGER IF EXISTS `tr_client_bi`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_client_bi`
  BEFORE INSERT
  ON `client`
  FOR EACH ROW
  BEGIN

    SET NEW.created_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_client_bu
DROP TRIGGER IF EXISTS `tr_client_bu`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_client_bu`
  BEFORE UPDATE
  ON `client`
  FOR EACH ROW
  BEGIN

    SET NEW.updated_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_conditions_bi
DROP TRIGGER IF EXISTS `tr_conditions_bi`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_conditions_bi`
  BEFORE INSERT
  ON `conditions`
  FOR EACH ROW
  BEGIN

    SET NEW.created_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_conditions_bu
DROP TRIGGER IF EXISTS `tr_conditions_bu`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_conditions_bu`
  BEFORE UPDATE
  ON `conditions`
  FOR EACH ROW
  BEGIN

    SET NEW.updated_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_contract_ai
DROP TRIGGER IF EXISTS `tr_contract_ai`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_contract_ai`
  AFTER INSERT
  ON `contract`
  FOR EACH ROW
  BEGIN

    INSERT INTO account
    SET amount    = NEW.amount,
      contract_id = NEW.id;

    INSERT INTO contract_features
    SET
      contract_id    = NEW.id,
      month_day      = DAYOFMONTH(FROM_UNIXTIME(NEW.begin_at)),
      last_month_day = (DAYOFMONTH(LAST_DAY(FROM_UNIXTIME(NEW.begin_at))) = DAYOFMONTH(FROM_UNIXTIME(NEW.begin_at))),
      last_calc_date = NEW.begin_at;

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_contract_au
DROP TRIGGER IF EXISTS `tr_contract_au`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_contract_au`
  AFTER UPDATE
  ON `contract`
  FOR EACH ROW
  BEGIN

    UPDATE contract_features
    SET month_day    = DAYOFMONTH(FROM_UNIXTIME(NEW.begin_at)),
      last_month_day = (DAYOFMONTH(LAST_DAY(FROM_UNIXTIME(NEW.begin_at))) = DAYOFMONTH(FROM_UNIXTIME(NEW.begin_at)))
    WHERE contract_id = NEW.id;

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_contract_bi
DROP TRIGGER IF EXISTS `tr_contract_bi`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_contract_bi`
  BEFORE INSERT
  ON `contract`
  FOR EACH ROW
  BEGIN

    SET NEW.created_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_contract_bu
DROP TRIGGER IF EXISTS `tr_contract_bu`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_contract_bu`
  BEFORE UPDATE
  ON `contract`
  FOR EACH ROW
  BEGIN

    SET NEW.updated_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_transactions_ad
DROP TRIGGER IF EXISTS `tr_transactions_ad`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_transactions_ad`
  AFTER DELETE
  ON `transactions`
  FOR EACH ROW
  BEGIN

    IF OLD.credit > 0.00
    THEN
      UPDATE account
      SET amount = amount + OLD.credit
      WHERE id = OLD.account_id;

      UPDATE bank_account
      SET amount = amount - OLD.credit
      WHERE id = OLD.bank_account_id;

    END IF;
    IF OLD.debit > 0.00
    THEN
      UPDATE account
      SET amount = amount - OLD.debit
      WHERE id = OLD.account_id;

      UPDATE bank_account
      SET amount = amount - OLD.debit
      WHERE id = OLD.bank_account_id;

    END IF;

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_transactions_ai
DROP TRIGGER IF EXISTS `tr_transactions_ai`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_transactions_ai`
  AFTER INSERT
  ON `transactions`
  FOR EACH ROW
  BEGIN

    IF NEW.credit > 0.00
    THEN
      UPDATE account
      SET amount = amount - NEW.credit
      WHERE id = NEW.account_id;

      UPDATE bank_account
      SET amount = amount + NEW.credit
      WHERE id = NEW.bank_account_id;

    END IF;
    IF NEW.debit > 0.00
    THEN
      UPDATE account
      SET amount = amount + NEW.debit
      WHERE id = NEW.account_id;

      UPDATE bank_account
      SET amount = amount + NEW.debit
      WHERE id = NEW.bank_account_id;

    END IF;

    INSERT INTO fk
    SET transaction_id = NEW.id;

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_transactions_au
DROP TRIGGER IF EXISTS `tr_transactions_au`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_transactions_au`
  AFTER UPDATE
  ON `transactions`
  FOR EACH ROW
  BEGIN

    IF OLD.credit > 0.00
    THEN
      UPDATE account
      SET amount = amount + OLD.credit
      WHERE id = OLD.account_id;

      UPDATE bank_account
      SET amount = amount - OLD.credit
      WHERE id = OLD.bank_account_id;

    END IF;
    IF OLD.debit > 0.00
    THEN
      UPDATE account
      SET amount = amount - OLD.debit
      WHERE id = OLD.account_id;

      UPDATE bank_account
      SET amount = amount - OLD.debit
      WHERE id = OLD.bank_account_id;

    END IF;

    IF NEW.credit > 0.00
    THEN
      UPDATE account
      SET amount = amount - NEW.credit
      WHERE id = NEW.account_id;

      UPDATE bank_account
      SET amount = amount + NEW.credit
      WHERE id = NEW.bank_account_id;

    END IF;
    IF NEW.debit > 0.00
    THEN
      UPDATE account
      SET amount = amount + NEW.debit
      WHERE id = NEW.account_id;

      UPDATE bank_account
      SET amount = amount + NEW.debit
      WHERE id = NEW.bank_account_id;

    END IF;

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_transactions_bi
DROP TRIGGER IF EXISTS `tr_transactions_bi`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_transactions_bi`
  BEFORE INSERT
  ON `transactions`
  FOR EACH ROW
  BEGIN

    SET NEW.created_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для триггер bank.tr_transactions_bu
DROP TRIGGER IF EXISTS `tr_transactions_bu`;
SET @OLDTMP_SQL_MODE = @@SQL_MODE, SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `tr_transactions_bu`
  BEFORE UPDATE
  ON `transactions`
  FOR EACH ROW
  BEGIN

    SET NEW.updated_at = UNIX_TIMESTAMP(CURRENT_TIMESTAMP());

  END//
DELIMITER ;
SET SQL_MODE = @OLDTMP_SQL_MODE;

-- Дамп структуры для представление bank.contracts_calculation_prms
DROP VIEW IF EXISTS `contracts_calculation_prms`;
-- Удаление временной таблицы и создание окончательной структуры представления
DROP TABLE IF EXISTS `contracts_calculation_prms`;
CREATE ALGORITHM = UNDEFINED
  DEFINER =`root`@`%`
  SQL SECURITY DEFINER VIEW contracts_calculation_prms (
    account_id,
    contract_id,
    calculation_id,
    month_day,
    last_month_day,
    last_calc_date,
    contract_begin_at,
    contract_end_at
) as
  select
    a.id              AS account_id,
    a.contract_id     AS contract_id,
    cc.id             AS calculation_id,
    cf.month_day      AS month_day,
    cf.last_month_day AS last_month_day,
    cf.last_calc_date AS last_calc_date,
    c.begin_at        AS contract_begin_at,
    c.end_at          AS contract_end_at
  from contract_features cf
    join contract c on cf.contract_id = c.id
    join account a on cf.contract_id = a.contract_id
    left join conditions cnd on cf.contract_id = cnd.contract_id
    join calculation cc on cnd.calculation_id = cc.id
  where (cf.closed = 0);

/*!40101 SET SQL_MODE = IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS = IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT = @OLD_CHARACTER_SET_CLIENT */;
