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