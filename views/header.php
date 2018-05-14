<?php

use sn\core\App;

?>
<header class="site-header">
  <div class="header-topnav">
    <div class="container">
      <div class="row">
        <div class="col-md-4 hidden-xs hidden-sm">
          <span class="welcome-message">Bank</span>
        </div>
        <div class="col-md-8">
          <ul class="nav navbar-nav navbar-right">
          </ul>
        </div>
      </div>
    </div>
  </div>
  <nav class="site-navigation navbar navbar-default " role="navigation" itemscope="itemscope">
    <div class="container">
      <div class="header-block">
        <div class="col-logo">
          <div class="row">
            <div class="navbar-header">
              <a data-waitloader class="navbar-brand" href="<?= App::$app->router()->UrlTo('/'); ?>">
                <div class="site-with-image">
                  <img class="site-logo" src="<?= App::$app->router()->UrlTo('images/logo.png'); ?>" alt=""/>
                </div>
              </a>
            </div>
          </div>
        </div>
        <?= $menu ?>
      </div>
    </div>
  </nav>
</header>
