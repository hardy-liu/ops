<?php
require('/data/www/fanghubao/php/prop/dns.php');
require('/data/www/fanghubao/php/inc/conn.php');
//require('seconddomain.class_test.php');
//$a = new seconddomainaction;
//$result = $a->cnameadd('www','2','20','2');
//$record = $dns -> addrecord('ww1-liudianab-com.wyccdef.com', '8.8.8.8', 0, "A");
$record = $dns -> ssrecord('37114921');
print_r($record);
?>
