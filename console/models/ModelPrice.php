<?php

namespace console\models;

use sn\core\App;
use sn\core\model\ModelBase;

/**
 * Class ModelPrice
 * @package console\models
 */
class ModelPrice extends ModelBase{

  /**
   * @param $price
   * @param int $inventory
   * @param int $piece
   * @return float
   */
  public static function getPrice($price, $inventory = 0, $piece = 0){
    if($piece == 1 && $inventory > 0) {
      $price = $price * $inventory;
    }

    return round($price, 2);
  }

  /**
   * @param $discount_category
   * @param $rPrice
   * @param $rShip
   * @param $shipType
   * @param $discountIds
   * @return float|int
   * @throws \Exception
   */
  public static function calculateDiscount($discount_category, $rPrice, $rShip, $shipType, &$discountIds){

    #make sure that the user is entering a coupon code when we are checking for a coupon
    if(($discount_category == DISCOUNT_CATEGORY_COUPON)) {
      return 0;
    }

    $rDiscount = 0;
    $rMultDiscount = 0;
    $rPrice = preg_replace('/[^\.|\d]/', '', $rPrice);
    $rShip = preg_replace('/[^\.|\d]/', '', $rShip);

    /*
        user_type = 1 - All users
        user_type = 2 - All new users
        user_type = 3 - All registered users
        user_type = 4 - All selected users

        discount_amount_type = 1 - $
        discount_amount_type = 2 - %

        discount_type = 1 - total
        discount_type = 2 - shipping

        required_type 1 purchases - 2 total amount
        required_type 1 purchases - 2 total amount

    */

    #check the discounts for the users
    $sSQL = "SELECT DISTINCT s.sid, s.required_type, s.required_amount, s.date_start, s.promotion_type," .
      " s.discount_type, s.shipping_type, s.discount_amount, s.discount_amount_type, s.product_type," .
      " s.allow_multiple, s.coupon_code " .
      "FROM shop_specials s " .
      "LEFT OUTER JOIN shop_specials_users su ON su.sid=s.sid " .
      "LEFT OUTER JOIN shop_specials_products sp ON s.sid = sp.sid " .
      "WHERE (s.user_type=1";
    $sSQL .= ")";

    #CHANGED PRODUCT DISCOUNT SHOWN IN PRICE, NO LONGER CALCULATED HERE
    $sPds = '';
    $sSQL .= " AND (s.product_type = 1)";

    #add a check to ensure the function only checks shipping discounts
    if($discount_category == DISCOUNT_CATEGORY_SHIPPING) {
      $sSQL .= sprintf(" AND (s.discount_type = %u)", DISCOUNT_TYPE_SHIPPING);

      #add the shipping type restriction
      if($shipType == 3) {            #ground shipping
        $sSQL .= ' AND (s.shipping_type = 2 OR s.shipping_type = 1)';
      } else if($shipType == 1) {    #express shipping
        $sSQL .= ' AND (s.shipping_type = 3 OR s.shipping_type = 1)';
      }
    } else if(($discount_category != DISCOUNT_CATEGORY_ALL) && ($discount_category != DISCOUNT_CATEGORY_COUPON)) {
      $sSQL .= sprintf(" AND (s.discount_type != %u)", DISCOUNT_TYPE_SHIPPING);
    }

    $sSQL .= sprintf(" AND ((s.coupon_code='') OR (s.coupon_code IS NULL))");

    $iNow = mktime(0, 0, 0, date('m'), date('d'), date('Y'));
    $sSQL .= sprintf(" AND (s.enabled=1) AND (s.date_start<=%u) AND (s.date_end>=%u)", $iNow, $iNow);
    $sSQL .= " ORDER BY allow_multiple;";

    $result = static::query($sSQL) or die(static::error());
    if(static::num_rows($result) > 0) {
      while($rs = static::fetch_assoc($result)) {
        $bDoDiscount = self::checkDiscountApplies($rs, $rPrice);
        if($bDoDiscount) {
          $tmpDiscount = self::discountIt($rPrice, $rShip, $rs['discount_amount'], $rs['discount_amount_type'], $rs['discount_type']);
          if($discount_category == DISCOUNT_CATEGORY_SHIPPING) {
            $rShip -= $tmpDiscount;
          } else $rPrice -= $tmpDiscount;
          #determine whether we are using a multiple or single discount
          #the system will take the highest not multiple discount and add it to the sum of all the multiple discounts
          if((int)$rs['allow_multiple'] == 1) {
            $rMultDiscount += $tmpDiscount;
            $discountIds[] = $rs['sid'];
            #check if we need to return a string here
          } else if($tmpDiscount > $rDiscount) {
            if($rDiscount == 0) {
              $discountIds[] = $rs['sid'];
            } else {
              $discountIds[count($discountIds) - 1] = $rs['sid'];
            }
            $rDiscount = $tmpDiscount;
          }
        }
      }
      static::free_result($result);
    }
    #check if we need to return a string here
    $rDiscount = $rDiscount + $rMultDiscount;

    return $rDiscount;
  }

  /**
   * @param $rs
   * @param $rPrice
   * @return bool
   */
  public static function checkDiscountApplies($rs, $rPrice){
    $bDoDiscount = false;
    $iType = (int)$rs['promotion_type'];
    if($iType == 1) {
      if($rPrice >= $rs['required_amount']) {
        $bDoDiscount = true;
      }
    }

    return $bDoDiscount;
  }

  /**
   * @param $id
   * @param $price
   * @param $discountIds
   * @return bool
   * @throws \Exception
   */
  public static function checkProductDiscount($id, &$price, &$discountIds){

    if((int)$id == 0) {
      return false;
    }

    $bol = false;
    $iNow = mktime(0, 0, 0, date('m'), date('d'), date('Y'));
    $tempPrice = $price;

    /*
        discount_amount_type = 1 - $
        discount_amount_type = 2 - %

        discount_type = 1 - sub total
        discount_type = 2 - shipping
        discount_type = 3 - total
    */

    #check the discounts for the users
    $q = "SELECT DISTINCT" .
      " s.discount_type, s.discount_amount, s.discount_amount_type," .
      " IF(s.product_type = 2, p.priceyard, IF(s.product_type = 3,cp.priceyard, mp.priceyard)) as price," .
      " s.sid" . " FROM shop_specials s" .
      " LEFT JOIN shop_specials_users su ON su.sid=s.sid" .
      " LEFT JOIN shop_specials_products sp ON s.sid = sp.sid AND (s.product_type = sp.stype)" .
      " LEFT JOIN shop_products p ON sp.pid = p.pid AND (s.product_type = 2)" .
      " LEFT JOIN shop_product_categories c ON sp.pid = c.cid AND (s.product_type = 3)" .
      " LEFT JOIN shop_products cp ON c.pid = cp.pid" .
      " LEFT JOIN shop_products mp ON sp.pid = mp.manufacturerId  AND (s.product_type = 4)" .
      " WHERE" .
      " (s.user_type=1) AND" .
      " (((s.product_type = 2) AND (sp.pid IN (%u))) OR ((s.product_type = 3) AND (cp.pid IN (%u))) OR ((s.product_type = 4) AND (mp.pid IN (%u)))) AND" .
      " ((s.coupon_code='') OR (s.coupon_code IS NULL)) AND" .
      " (s.enabled=1) AND" .
      " (s.date_start<=%u) AND" .
      " (s.date_end>=%u) AND" .
      " (required_type = 0) AND" .
      " (promotion_type=1)";

    $sql = sprintf($q, $id, $id, $id, $iNow, $iNow);
    $result = static::query($sql) or die(static::error());
    if(static::num_rows($result) > 0) {
      while($rs = static::fetch_assoc($result)) {
        $amt = $rs['discount_amount'];
        if($rs['discount_amount_type'] == 1) {
          $tempPrice = $tempPrice - $amt;
        } else {
          $tempPrice = $tempPrice * (1 - ($amt / 100));
        }

        if($tempPrice != $price) {
          $bol = true;
          $price = $tempPrice;
          $discountIds[] = $rs['sid'];
        }
      }
      static::free_result($result);
    }

    return $bol;
  }

  /**
   * @param $price
   * @param $discountIds
   * @return float|int
   * @throws \Exception
   */
  public static function calculateProductSalePrice($price, &$discountIds){

    #set the return price to the current price, the return price will be changed if needed
    $ret = $price;

    #get the shipping
    $shipping = DEFAULT_SHIPPING;
    $shipcost = 0;

    $rSystemDiscount = self::calculateDiscount(DISCOUNT_CATEGORY_PRODUCT, $price, $shipcost, $shipping, $discountIds);
    if($rSystemDiscount > 0) $ret = $price - $rSystemDiscount;

    return $ret;
  }

  /**
   * @param $rAmt
   * @param $rDis
   * @param $iType
   * @return float|int
   */
  public static function doDiscount($rAmt, $rDis, $iType){

    $rRet = 0;

    //discount_amount_type = 1 - $ off
    //discount_amount_type = 2 - % off
    if($iType == 1) {
      $rRet = $rDis;
    } else if($iType == 2) {
      $rRet = $rAmt * ($rDis / 100);
    }

    return $rRet;
  }

  /**
   * @param $rTtl
   * @param $rShip
   * @param $rDis
   * @param $iDisAmntType
   * @param $iDisType
   * @return float|int
   */
  public static function discountIt($rTtl, $rShip, $rDis, $iDisAmntType, $iDisType){

    $rDis = preg_replace('/[^\.|\d]/', '', $rDis);

    //discount_type = 1 - total wo shipping	- default
    //discount_type = 2 - shipping
    //discount_type = 3 - total w/ shipping

    $rate_handling = (!is_null(App::$app->keyStorage()->shop_rate_handling) ? App::$app->keyStorage()->shop_rate_handling : RATE_HANDLING);

    if($iDisType == 2) {
      $rRet = self::doDiscount($rShip, $rDis, $iDisAmntType);
    } else if($iDisType == 3) {
      $rRet = self::doDiscount(($rTtl + $rShip + $rate_handling), $rDis, $iDisAmntType);
    } else {
      $rRet = self::doDiscount($rTtl, $rDis, $iDisAmntType);
    }

    return $rRet;
  }

  /**
   * @param $aPrd
   * @param $iSid
   * @param $sPds
   * @return float|int
   * @throws \Exception
   */
  public static function getProductsTotal($aPrd, $iSid, $sPds){

    #make sure we receive an special id and a list of the product ids
    if(((int)$iSid == 0) && (strlen($sPds) > 0)) {
      return 0;
    }

    #define the total
    $rTtl = 0;

    #get the list of all the products that this special applies to, narrow down to only those that may be in the cart
    $sql = sprintf("SELECT sp.pid, p.priceyard FROM shop_specials_products sp INNER JOIN shop_products p ON sp.pid = p.pid WHERE sp.sid=%u AND sp.pid IN (%s);", $iSid, $sPds);

    $result = static::query($sql) or die(static::error());

    while($rs = static::fetch_array($result)) {

      $iPid = (int)$rs[0];
      $iPrice = (real)$rs[1];

      #examine the products array and return the qty for that product
      $idx = array_search($iPid, $aPrd);

      #make sure that the product id was found
      if($idx === false) {
        continue;
      }

      $qty = (int)$aPrd[++$idx];

      #calculate the subtotal for this product
      $rTtl += $iPrice * $qty;
    }

    static::free_result($result);

    return $rTtl;
  }

}