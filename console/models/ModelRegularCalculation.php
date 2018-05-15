<?php

namespace console\models;

use sn\core\model\ModelProcedureBase;

/**
 * Class ModelConsole
 * @package console\models
 */
class ModelRegularCalculation extends ModelProcedureBase{

    protected static $procedure = 'calculation_start';

    /**
     * @throws \PDOException
     * @throws \sn\core\exceptions\BeginTransactionException
     * @throws \sn\core\exceptions\RollBackTransactionException
     */
    public static function CalculationStart(){

        static::BeginTransaction();
        try {
            static::Execute(['inOnDate' => strtotime(date('Y-m-d'))]);
            static::Commit();
        } catch(\Exception $e) {
            static::RollBack();
            throw $e;
        }
    }

}