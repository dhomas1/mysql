<?php 
$app = "mysql";
$appname = "MySQL";
$appversion = "5.6.26";
$appsite = "http://www.mysql.com/";
$apphelp = "http://dev.mysql.com/doc/refman/5.6/en/";

$applogs = array("/tmp/DroboApps/".$app."/log.txt",
                 "/tmp/DroboApps/".$app."/access.log",
                 "/tmp/DroboApps/".$app."/error.log");

$appprotos = array("http", "tcp");
$appports = array("8033", "3306");
$droboip = $_SERVER['SERVER_ADDR'];
$apppage = $appprotos[0]."://".$droboip.":".$appports[0]."/";
if ($publicip != "") {
  $publicurl = $appprotos[0]."://".$publicip.":".$appports[0]."/";
} else {
  $publicurl = $appprotos[0]."://public.ip.address.here:".$appports[0]."/";
}
$portscansite = "http://mxtoolbox.com/SuperTool.aspx?action=scan%3a".$publicip."&run=toolpage";

$rootcnffile = "/mnt/DroboFS/Shares/DroboApps/mysql/data/.root.cnf";
$rootcnf = file_get_contents($rootcnffile);
$rootpass = shell_exec("/usr/bin/awk -F= '$1 == \"password\" {print $2}' ".$rootcnffile);
?>