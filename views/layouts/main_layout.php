<?php

use sn\core\App;

/**
 * @var \sn\core\View $this
 */
?>

<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title><?= isset($meta['title']) ? $meta['title'] : ''; ?></title>
  <meta name="Description" content="<?= isset($meta['description']) ? $meta['description'] : ''; ?>">
  <meta name="KeyWords" content="<?= isset($meta['keywords']) ? $meta['keywords'] : ''; ?>">
  <meta name="apple-mobile-web-app-capable" content="yes"/>
  <meta name="apple-mobile-web-app-status-bar-style" content="black"/>
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <?php if(isset($canonical_url)): ?>
    <link rel="canonical" href="<?= $canonical_url ?>"/>
  <?php endif; ?>

  <style>
    .loader {background: #fff; position: fixed; top: 0; left: 0; width: 100%; height: 100%; z-index: 1000000000000;}
    .loader i {position: relative; left: 50vw; color: #000; top: 50vh; margin-left: -28px; margin-top: -28px;}
  </style>
  <?php $this->registerCSSFile(App::$app->router()->UrlTo('css/all_common.min.css')); ?>
  <?= $this->renderCssLinks(); ?>

  <?php  $this->registerJSFile(App::$app->router()->UrlTo('js/all.min.js')); ?>

</head>

<body>
<input type="hidden" id="base_url" value="<?= App::$app->router()->UrlTo('/'); ?>">

<?php include("loader.php"); ?>

<div class="scroll">
  <div class="site-container">
    <div class="main-content main-content-shop">
      <?php include(APP_PATH . "/views/header.php"); ?>
      <?= isset($content) ? $content : ''; ?>
    </div>
  </div>

  <footer class="site-footer">
    <?php include(APP_PATH . '/views/footer.php') ?>
  </footer>
</div>

<?= $this->renderJsLinks(); ?>

</body>
</html>