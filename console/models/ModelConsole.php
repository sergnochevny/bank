<?php

namespace console\models;

use sn\core\model\ModelBase;
use Exception;

/**
 * Class ModelConsole
 * @package console\models
 */
class ModelConsole extends ModelBase{

  /**
   * @param $filter
   * @param null $prms
   * @return string
   */
  public static function build_where(&$filter, &$prms = null){
    $result_where = "";
    $fields = !empty($filter['fields']) ? $filter['fields'] : [];
    foreach($fields as $field => $condition) {
      if(is_array($condition)) {
        $clause = $field . " ";
        $clause .= $condition['condition'] . " ";
        if(is_null($condition["value"]) || (strtolower($condition["value"]) == 'null')) {
          $clause .= ($condition['not'] ? "not " : "") . "null";
          $condition['not'] = false;
        } elseif($condition["condition"] == 'in') {
          if(is_array($condition["value"])) {
            $clause .= "(" . implode(', ', array_walk($condition["value"],
                function(&$value){
                  $value = "'" . static::prepare_for_sql($value) . "'";
                })) . ")";
          } else {
            $clause .= "(" . "'" . static::prepare_for_sql($condition["value"]) . "'" . ")";
          }
        } else {
          $clause .= "'" . static::prepare_for_sql($condition["value"]) . "'";
        }
        $clause = ($condition['not'] ? "not (" . $clause . ")" : $clause);
      } else {
        $clause = $field . " ";
        $clause .= (is_null($condition) ? "is" : "=") . " ";
        $clause .= (is_null($condition) ? "null" : "'" . static::prepare_for_sql($condition["value"]) . "'");
      }
      $result[] = $clause;
    }
    if(!empty($result) && (count($result) > 0)) {
      $result_where = implode(" AND ", $result);
      $result_where = (!empty($result_where) ? " WHERE " . $result_where : '');
    }

    return $result_where;
  }

  /**
   * @param null $filter
   * @return int|null
   * @throws \Exception
   */
  public static function get_total_count($filter = null){
    $response = 0;
    $query = "SELECT COUNT(*) FROM " . static::$table;
    if(!empty($filter)) $query .= static::build_where($filter, $prms);
    if($result = static::query($query, $prms)) {
      $response = static::fetch_value($result);
      static::free_result($result);
    } else {
      throw new Exception(static::error());
    }

    return $response;
  }

  /**
   * @param $filter
   * @return null
   * @throws \Exception
   */
  public static function get_one($filter){
    $data = null;
    if(!empty($filter)) {
      $query = "SELECT * FROM " . static::$table;
      $query .= static::build_where($filter, $prms);
      $query .= static::build_order($sort);
      $result = static::query($query, $prms);
      if($result) {
        $data = static::fetch_assoc($result);
      } else {
        throw new Exception(static::error());
      }
    }

    return $data;
  }

  /**
   * @param $prepare
   * @param $start
   * @param $limit
   * @param $res_count_rows
   * @param null $filter
   * @param null $sort
   * @return array|null
   * @throws \Exception
   */
  public static function get_list($prepare, $start, $limit, &$res_count_rows, &$filter = null, &$sort = null){
    $response = [];
    $query = "SELECT * FROM " . static::$table;
    $query .= static::build_where($filter, $prms);
    $query .= static::build_order($sort);
    if($limit != 0) $query .= " LIMIT $start, $limit";
    if($result = static::query($query, $prms)) {
      $res_count_rows = static::num_rows($result);
      while($row = static::fetch_assoc($result)) {
        $response[] = $row;
      }
    } else {
      throw new Exception(static::error());
    }

    return $response;
  }

  /**
   * @param $data
   * @return bool
   * @throws \Exception
   */
  public static function save($data){
    $prms = [];
    $res = false;
    if(!empty($data)) {
      $query = "REPLACE INTO `" . static::$table . "`";
      $fields = '';
      $values = '';
      foreach($data as $field => $value) {
        $fields .= (strlen($fields) ? ", " : "") . "`" . $field . "`";
        $values .= (strlen($values) ? ", " : "") . "'" . static::prepare_for_sql($value) . "'";
      }
      $query .= "(" . $fields . ") VALUES(" . $values . ")";
      if(!static::query($query, $prms)) throw new Exception(static::error());
    }

    return $res;
  }

  /**
   * @param $where
   * @return mixed
   */
  public static function delete($where){
    $query = "DELETE FROM " . static::$table;
    $query .= static::build_where($where, $prms);
    try {
      if(!($res = static::query($query, $prms))) throw new Exception(static::error());
    } catch(Exception $e) {
    }

    return $res;
  }

}