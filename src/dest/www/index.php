<?php
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Cache-Control: post-check=0, pre-check=0', false);
header('Pragma: no-cache');

$app = "mysql";
$appname = "MySQL";
$appversion = "5.6.26";
$applogs = array("/tmp/DroboApps/".$app."/log.txt",
                 "/tmp/DroboApps/".$app."/access.log",
                 "/tmp/DroboApps/".$app."/error.log");
$appsite = "http://www.mysql.com/";
$apppage = "http://".$_SERVER['SERVER_ADDR'].":8033/";
$apphelp = "http://dev.mysql.com/doc/refman/5.6/en/";

exec("/bin/sh /usr/bin/DroboApps.sh sdk_version", $out, $rc);
if ($rc === 0) {
  $sdkversion = $out[0];
} else {
  $sdkversion = "2.0";
}

$op = $_REQUEST['op'];
switch ($op) {
  case "start":
    unset($out);
    exec("/bin/sh /usr/bin/DroboApps.sh start_app ".$app, $out, $rc);
    if ($rc === 0) {
      $opstatus = "okstart";
      sleep(1); // wait for pidfile
    } else {
      $opstatus = "nokstart";
    }
    break;
  case "stop":
    unset($out);
    exec("/bin/sh /usr/bin/DroboApps.sh stop_app ".$app, $out, $rc);
    if ($rc === 0) {
      $opstatus = "okstop";
    } else {
      $opstatus = "nokstop";
    }
    break;
  case "rootpass":
    unset($out);
    exec("/bin/sh /mnt/DroboFS/Shares/DroboApps/mysql/scripts/mysql_gen_root_pass.sh", $out, $rc);
    if ($rc === 0) {
      if ($_REQUEST['restart'] === "1") {
        unset($out);
        exec("/bin/sh /usr/bin/DroboApps.sh stop_app ".$app, $out, $rc);
        exec("/bin/sh /usr/bin/DroboApps.sh start_app ".$app, $out, $rc);
        sleep(1); // wait for pidfile
      }
      if ($rc === 0) {
        $opstatus = "okrootpass";
      } else {
        $opstatus = "nokrootpass";
      }
    } else {
      $opstatus = "nokrootpass";
    }
    break;
  case "logs":
    $opstatus = "logs";
    break;
  default:
    $opstatus = "noop";
    break;
}

$droboip = $_SERVER['SERVER_ADDR'];
$rootcnffile = "/mnt/DroboFS/Shares/DroboApps/mysql/data/.root.cnf";
$rootcnf = file_get_contents($rootcnffile);
$rootpass = shell_exec("/usr/bin/awk -F= '$1 == \"password\" {print $2}' ".$rootcnffile);

unset($out);
exec("/usr/bin/DroboApps.sh status_app ".$app, $out, $rc);
if ($rc !== 0) {
  unset($out);
  exec("/mnt/DroboFS/Shares/DroboApps/".$app."/service.sh status", $out, $rc);
}
if (strpos($out[0], "running") !== FALSE) {
  $apprunning = TRUE;
} else {
  $apprunning = FALSE;
}
?>
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta http-equiv="cache-control" content="no-cache" />
  <meta http-equiv="expires" content="-1" />
  <meta http-equiv="pragma" content="no-cache" />
  <title><?php echo $appname; ?> DroboApp</title>
  <link rel="stylesheet" type="text/css" media="screen" href="css/bootstrap.min.css" />
  <link rel="stylesheet" type="text/css" media="screen" href="css/custom.css" />
  <script src="js/jquery.min.js"></script>
  <script src="js/bootstrap.min.js"></script>
</head>

<body>
<nav class="navbar navbar-default navbar-fixed-top">
  <div class="container-fluid">
    <div class="navbar-header">
      <a class="navbar-brand" href="<?php echo $appsite; ?>" target="_new"><img alt="<?php echo $appname; ?>" src="img/app_logo.png" /></a>
    </div>
    <div class="collapse navbar-collapse" id="navbar">
      <ul class="nav navbar-nav navbar-right">
        <li><a class="navbar-brand" href="http://www.drobo.com/" target="_new"><img alt="Drobo" src="img/drobo_logo.png" /></a></li>
      </ul>
    </div>
  </div>
</nav>

<div class="container top-toolbar">
  <div role="toolbar" class="btn-toolbar">
    <div role="group" class="btn-group">
      <p class="title">About <?php echo $app; ?> <?php echo $appversion; ?></p>
    </div>
    <div role="group" class="btn-group pull-right">
<?php if ($apprunning) { ?>
<?php if ($sdkversion != "2.0") { ?>
      <a role="button" class="btn btn-primary" href="?op=stop" onclick="$('#pleaseWaitDialog').modal(); return true"><span class="glyphicon glyphicon-stop"></span> Stop</a>
<?php } ?>
      <a role="button" class="btn btn-primary" href="<?php echo $apppage; ?>" target="_new"><span class="glyphicon glyphicon-globe"></span> Go to App</a>
<?php } else { ?>
<?php if ($sdkversion != "2.0") { ?>
      <a role="button" class="btn btn-primary" href="?op=start" onclick="$('#pleaseWaitDialog').modal(); return true"><span class="glyphicon glyphicon-play"></span> Start</a>
<?php } ?>
      <a role="button" class="btn btn-primary disabled" href="<?php echo $apppage; ?>" target="_new"><span class="glyphicon glyphicon-globe"></span> Go to App</a>
<?php } ?>
      <a role="button" class="btn btn-primary" href="<?php echo $apphelp; ?>" target="_new"><span class="glyphicon glyphicon-question-sign"></span> Help</a>
    </div>
  </div>
</div>

<div role="dialog" id="pleaseWaitDialog" class="modal animated bounceIn" tabindex="-1" aria-labelledby="myModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-body">
        <p id="myModalLabel">Operation in progress... please wait.</p>
        <div class="progress">
          <div class="progress-bar progress-bar-striped active" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100" style="width: 100%">
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="container">
  <div class="row">
    <div class="col-xs-3"></div>
    <div class="col-xs-6">
<?php switch ($opstatus) { ?>
<?php case "okstart": ?>
      <div class="alert alert-success fade in" id="opstatus">
        <a href="#" class="close" data-dismiss="alert" aria-label="close">&times;</a>
        <?php echo $appname; ?> was successfully started.
      </div>
<?php break; case "nokstart": ?>
      <div class="alert alert-error fade in" id="opstatus">
        <a href="#" class="close" data-dismiss="alert" aria-label="close">&times;</a>
        <?php echo $appname; ?> failed to start. See logs below for more information.
      </div>
<?php break; case "okstop": ?>
      <div class="alert alert-success fade in" id="opstatus">
        <a href="#" class="close" data-dismiss="alert" aria-label="close">&times;</a>
        <?php echo $appname; ?> was successfully stopped.
      </div>
<?php break; case "nokstop": ?>
      <div class="alert alert-error fade in" id="opstatus">
        <a href="#" class="close" data-dismiss="alert" aria-label="close">&times;</a>
        <?php echo $appname; ?> failed to stop. See logs below for more information.
      </div>
<?php break; case "okrootpass": ?>
      <div class="alert alert-success fade in" id="opstatus">
        <a href="#" class="close" data-dismiss="alert" aria-label="close">&times;</a>
        New root password successfully generated.
      </div>
<?php break; case "nokrootpass": ?>
      <div class="alert alert-error fade in" id="opstatus">
        <a href="#" class="close" data-dismiss="alert" aria-label="close">&times;</a>
        Failed to generate a new root password. See logs below for more information.
      </div>
<?php break; } ?>
      <script>
      window.setTimeout(function() {
        $("#opstatus").fadeTo(500, 0).slideUp(500, function() {
          $(this).remove(); 
        });
      }, 2000);
      </script>
    </div><!-- col -->
    <div class="col-xs-3"></div>
  </div><!-- row -->

  <div class="row">
    <div class="col-xs-12">

  <!-- description -->
  <div class="panel-group" id="description">
    <div class="panel panel-default">
      <div class="panel-heading">
        <h4 class="panel-title"><a data-toggle="collapse" data-parent="#description" href="#descriptionbody">Description</a></h4>
      </div>
      <div id="descriptionbody" class="panel-collapse collapse in">
        <div class="panel-body">
          <p>This DroboApp packages a complete SQL database solution for your Drobo. It includes:</p>
          <ul>
            <li><a href="http://www.mysql.com/" target="_new">MySQL</a>, the world&apos;s most popular open source database.</li>
            <li><a href="http://mywebsql.net/" target="_new">MyWebSQL</a>, a fast, intuitive and modern web based database client for MySQL.</li>
          </ul>
          <p>This DroboApp is used as the backend storage for web apps that run on the Drobo, and as such it is usually automatically installed as a dependency.</p>
        </div>
      </div>
    </div>
  </div>

  <!-- shorthelp -->
  <div class="panel-group" id="shorthelp">
    <div class="panel panel-default">
      <div class="panel-heading">
        <h4 class="panel-title"><a data-toggle="collapse" data-parent="#shorthelp" href="#shorthelpbody">Getting started</a></h4>
      </div>
      <div id="shorthelpbody" class="panel-collapse collapse in">
        <div class="panel-body">
          <p>To access MySQL on your Drobo click the &quot;Go to App&quot; button above.</p>
          <p>The admin login and password are:</p>
          <form class="form-horizontal">
            <div class="form-group">
              <label for="admin_login" class="col-sm-2 control-label">User ID:</label>
              <div class="col-sm-8">
                <input type="text" class="form-control" id="admin_login" value="root" readonly />
              </div>
            </div>
            <div class="form-group">
              <label for="admin_password" class="col-sm-2 control-label">Password:</label>
              <div class="col-sm-8">
                <input type="text" class="form-control" id="admin_password" value="<?php echo $rootpass; ?>" readonly />
              </div>
            </div>
          </form>
          <p><strong>Please do not change the root password manually or using MyWebSQL.</strong> Other apps rely on the root password being system-defined, and it will be reset to the system-defined value when MySQL is started.</p>
<?php if ($sdkversion != "2.0") { ?>
          <p>If you need to change the root password, you can generate a new one by clicking the button below.<?php if ($apprunning) { ?> Keep in mind that changing the root password <strong>will restart mysql</strong>.<?php } ?></p>
          <a class="btn btn-default" href="?op=rootpass<?php if ($apprunning) echo '&restart=1' ?>" onclick="$('#pleaseWaitDialog').modal(); return true"><span class="glyphicon glyphicon-asterisk"></span> Regenerate root password</a>
<?php } else { ?>
          <p>If you need to change the root password, please stop mysql, reopen this page, and click this button:</p>
          <a class="btn btn-default disabled" href="?op=rootpass" onclick="$('#pleaseWaitDialog').modal(); return true"><span class="glyphicon glyphicon-asterisk"></span> Regenerate root password</a>
<?php } ?>
        </div>
      </div>
    </div>
  </div>

  <!-- troubleshooting -->
  <div class="panel-group" id="troubleshooting">
    <div class="panel panel-default">
      <div class="panel-heading">
        <h4 class="panel-title"><a data-toggle="collapse" data-parent="#troubleshooting" href="#troubleshootingbody">Troubleshooting</a></h4>
      </div>
      <div id="troubleshootingbody" class="panel-collapse collapse">
        <div class="panel-body">
          <?php if (! $apprunning) { ?><p><strong>I cannot connect to MySQL on the Drobo.</strong></p>
          <p>Make sure that mysql is running. Currently it seems to be <strong>stopped</strong>.</p><?php } ?>
          <p><strong>I cannot install web-based DroboApps.</strong></p>
          <p>Make sure that mysql&apos;s root password is the system-defined one. Restart mysql to be sure.</p>
          <p><strong>I cannot connect to mysql from my desktop machine using the root account.</strong></p>
          <p>The default configuration prevents remote access from the root account. Please use the web interface to change that. Keep in mind that this is a security liability.</p>
        </div>
      </div>
    </div>
  </div>

  <!-- logfile -->
  <div class="panel-group" id="logfile">
    <div class="panel panel-default">
      <div class="panel-heading">
        <h4 class="panel-title"><a data-toggle="collapse" data-parent="#logfile" href="#logfilebody">Log information</a></h4>
      </div>
      <div id="logfilebody" class="panel-collapse collapse <?php if ($opstatus == "logs") { ?>in<?php } ?>">
        <div class="panel-body">
          <div role="toolbar" class="btn-toolbar">
            <div role="group" class="btn-group  pull-right">
              <a role="button" class="btn btn-default" href="?op=logs" onclick="$('#pleaseWaitDialog').modal(); return true"><span class="glyphicon glyphicon-refresh"></span> Reload logs</a>
            </div>
          </div>
<?php foreach ($applogs as $applog) { ?>
          <p>This is the content of <code><?php echo $applog; ?></code>:</p>
          <pre class="pre-scrollable">
<?php if (substr($applog, 0, 1) === ":") {
  echo shell_exec(substr($applog, 1));
} else {
  echo file_get_contents($applog);
} ?>
          </pre>
<?php } ?>
        </div>
      </div>
    </div>
  </div>

  <!-- summary -->
  <div class="panel-group" id="summary">
    <div class="panel panel-default">
      <div class="panel-heading">
        <h4 class="panel-title"><a data-toggle="collapse" data-parent="#summary" href="#summarybody">Summary of changes</a></h4>
      </div>
      <div id="summarybody" class="panel-collapse collapse">
        <div class="panel-body">
          <p>Changes from 5.6.13:</p>
          <ol>
            <li>Upgraded to MySQL 5.6.26 (<a href="http://dev.mysql.com/doc/relnotes/mysql/5.6/en/" target="_new">full changelog</a>)</li>
            <li>Removed perl dependency</li>
            <li>Included MyWebSQL 3.6</li>
            <li>Added configuration/about page</li>
          </ol>
        </div>
      </div>
    </div>
  </div>

    </div><!-- col -->
  </div><!-- row -->
</div><!-- container -->

<footer>
  <div class="container">
    <div class="pull-right">
      <small>All copyrighted materials and trademarks are the property of their respective owners.</small>
    </div>
  </div>
</footer>
</body>
</html>
