<?php

namespace console\controllers;

use console\models\ModelRegularCalculation;
use Exception;
use sn\core\console\controller\ControllerBase;

class ControllerCalculation extends ControllerBase{

    /**
     * @throws \Exception
     */
    protected function RegularCalculation(){
        ModelRegularCalculation::CalculationStart();
    }

    /**
     * @console
     */
    public function regular(){
        try {
            $this->RegularCalculation();
            fwrite(STDOUT, "Calculation was done successfully\r\n");
        } catch(Exception $e) {
            fwrite(STDOUT, $e->getMessage());
        }
    }

}
