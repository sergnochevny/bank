<?php
namespace console\controllers;

use sn\core\App;
use sn\core\console\controller\ControllerBase;
use console\models\ModelConsole;
use Exception;

class ControllerCalculate extends ControllerBase{


  public function build_search_filter(&$filter, $view = false){
    $search = null;
    $type = isset($filter['type']) ? $filter['type'] : null;
    $res = parent::build_search_filter($filter, $view);
    $filter['fields']['a.pnumber'] = ['not' => true, 'condition' => 'is', 'value' => null];
    if(!isset($filter['fields']['a.priceyard']) && !isset($filter['a.priceyard'])) {
      $filter['fields']['a.priceyard'] = ['not' => false, 'condition' => '>', 'value' => '0.00'];
    }
    $filter['fields']['a.pvisible'] = ['not' => false, 'condition' => '=', 'value' => '1'];
    $filter['fields']['a.image1'] = ['not' => true, 'condition' => 'is', 'value' => null];

    if(isset($type)) {
      $filter['type'] = $type;
      $res['type'] = $type;
      switch($type) {
        case 'best':
          unset($filter['a.best']);
          unset($res['a.best']);
          $filter['fields']['a.best'] = ['not' => false, 'condition' => '=', 'value' => '1'];
          $res['fields']['a.best'] = ['not' => false, 'condition' => '=', 'value' => '1'];
          break;
        case 'specials':
          unset($filter['a.specials']);
          unset($res['a.specials']);
          $filter['fields']['a.specials'] = ['not' => false, 'condition' => '=', 'value' => '1'];
          $res['fields']['a.specials'] = ['not' => false, 'condition' => '=', 'value' => '1'];
          break;
        case 'discounted':
          unset($filter['a.specials']);
          unset($res['a.specials']);
          $filter['fields']['a.specials'] = ['not' => false, 'condition' => '=', 'value' => '1'];
          $res['fields']['a.specials'] = ['not' => false, 'condition' => '=', 'value' => '1'];
          break;
      }
    }

    return $res;
  }

  protected function build_order(&$sort, $view = false, $filter = null){
    $type = isset($filter['type']) ? $filter['type'] : null;
    if(isset($type)) {
      switch($type) {
        case 'last':
          $sort['a.dt'] = 'desc';
          $sort['a.pid'] = 'desc';
          break;
        case 'popular':
          $sort['a.popular'] = 'desc';
          break;
        case 'bestsellers':
          $sort['s'] = 'desc';
          break;
        default:
          $sort['a.pid'] = 'desc';
      }
    } else {
      $sort['b.displayorder'] = 'asc';
      $sort['shop_product_categories.display_order'] = 'asc';
    }
  }

  /**
   * @param string $type
   * @param int $limit
   * @return array|null
   * @throws \Exception
   */
  protected function get_list_by_type($type = 'last', $limit = 60){
    $filter['type'] = $type;
    $this->build_search_filter($filter);
    $sort = $this->load_sort($filter);
    $rows = ModelShop::get_list(false, 0, $limit, $res_count_rows, $filter, $sort);

    return $rows;
  }

  /**
   * @throws \Exception
   */
  protected function collect_under(){
    ModelConsole::transaction();
    try {
      $limit = App::$app->keyStorage()->shop_under_limit;
      $trigger = ModelCollectionTrigger::get_one([
        'fields' => [
          'type' => [
            'not' => false, 'condition' => '=', 'value' => 3
          ]
        ]
      ]);
      if(!empty($trigger) && ($trigger['trigger'] == 1)) {
        ModelCollectionTrigger::save(['type' => 3, 'trigger' => 0]);
        ModelCollection::delete(['fields' => ['type' => ['not' => false, 'condition' => '=', 'value' => 3]]]);
        $start = 0;
        $terminate = false;
        do {
          $rows = ModelShop::get_widget_list_by_type('under', $start, $limit, $row_count);
          if(!empty($rows) && (count($rows) > 0)) {
            foreach($rows as $row) {
              if($row['saleprice'] <= 100) {
                ModelCollection::save(['type' => 3, 'pid' => $row['pid'], 'price' => $row['saleprice']]);
              }
            }
            $start += $limit;
          } else $terminate = true;
        } while(!$terminate);
      }
      ModelConsole::commit();
    } catch(Exception $e) {
      ModelConsole::rollback();
      throw $e;
    }
  }

  /**
   * @throws \Exception
   */
  protected function collect_specials(){
    ModelConsole::transaction();
    try {
      $select_type = ['specials_1', 'specials_2'];
      $specials = [];
      $limit = (int)App::$app->keyStorage()->shop_specials_limit;
      $terminate_limit = (int)App::$app->keyStorage()->shop_specials_amount;
      $trigger = ModelCollectionTrigger::get_one([
        'fields' => [
          'type' => [
            'not' => false, 'condition' => '=', 'value' => 2
          ]
        ]
      ]);
      if(!empty($trigger) && ($trigger['trigger'] == 1)) {
        ModelCollectionTrigger::save(['type' => 2, 'trigger' => 0]);
        ModelCollection::delete(['fields' => ['type' => ['not' => false, 'condition' => '=', 'value' => 2]]]);
        foreach($select_type as $type) {
          $start = 0;
          $tmp = [];
          $terminate = false;
          do {
            $rows = ModelShop::get_widget_list_by_type($type, $start, $limit, $row_count);
            if(!empty($rows) && (count($rows) > 0)) {
              foreach($rows as $row) {
                if($terminate) break;
                switch($type) {
                  case 'specials_1':
                    $tmp[] = $row;
                    break;
                  case 'specials_2':
                    if($row['discount']) $tmp[] = $row;
                    break;
                }
                if(count($tmp) >= $terminate_limit) $terminate = true;
              }
              $start += $limit;
            } else $terminate = true;
          } while(!$terminate);
          $specials = array_merge($specials, $tmp);
        }
        if(!empty($specials) && (count($specials) > 0)) {
          shuffle($specials);
          foreach($specials as $row) {
            ModelCollection::save(['type' => 2, 'pid' => $row['pid'], 'price' => $row['saleprice']]);
            if($terminate_limit-- <= 0) break;
          }
        }
      }
      ModelConsole::commit();
    } catch(Exception $e) {
      ModelConsole::rollback();
      throw $e;
    }
  }

  /**
   * @throws \Exception
   */
  protected function collect_bestsellers(){
    ModelConsole::transaction();
    try {
      $select_type = ['bestsellers_1', 'bestsellers_2'];
      $specials = [];
      $limit = (int)App::$app->keyStorage()->shop_bestsellers_limit;
      $terminate_limit = (int)App::$app->keyStorage()->shop_bestsellers_amount;
      $trigger = ModelCollectionTrigger::get_one([
        'fields' => [
          'type' => [
            'not' => false, 'condition' => '=', 'value' => 1
          ]
        ]
      ]);
      if(!empty($trigger) && ($trigger['trigger'] == 1)) {
        ModelCollectionTrigger::save(['type' => 1, 'trigger' => 0]);
        ModelCollection::delete(['fields' => ['type' => ['not' => false, 'condition' => '=', 'value' => 1]]]);
        foreach($select_type as $type) {
          $start = 0;
          $tmp = [];
          $terminate = false;
          do {
            $rows = ModelShop::get_widget_list_by_type($type, $start, $limit, $row_count);
            if(!empty($rows) && (count($rows) > 0)) {
              foreach($rows as $row) {
                if($terminate) break;
                switch($type) {
                  case 'bestsellers_1':
                    $tmp[] = $row;
                    break;
                  case 'bestsellers_2':
                    if($row['discount']) $tmp[] = $row;
                    break;
                }
                if(count($tmp) >= $terminate_limit) $terminate = true;
              }
              $start += $limit;
            } else $terminate = true;
          } while(!$terminate);
          $specials = array_merge($specials, $tmp);
        }
        if(!empty($specials) && (count($specials) > 0)) {
          shuffle($specials);
          foreach($specials as $row) {
            ModelCollection::save(['type' => 1, 'pid' => $row['pid'], 'price' => $row['saleprice']]);
            if($terminate_limit-- <= 0) break;
          }
        }
      }
      ModelConsole::commit();
    } catch(Exception $e) {
      ModelConsole::rollback();
      throw $e;
    }
  }

  /**
   * @console
   */
  public function run(){
    try {
      $this->collect_under();
      fwrite(STDOUT, "'under' list was collected successfully\r\n");
    } catch(Exception $e) {
      fwrite(STDOUT, $e->getMessage());
    }
    try {
      $this->collect_specials();
      fwrite(STDOUT, "'specials' list was collected successfully\r\n");
    } catch(Exception $e) {
      fwrite(STDOUT, $e->getMessage());
    }
    try {
      $this->collect_bestsellers();
      fwrite(STDOUT, "'bestsellers' list was collected successfully\r\n");
    } catch(Exception $e) {
      fwrite(STDOUT, $e->getMessage());
    }
  }

}
