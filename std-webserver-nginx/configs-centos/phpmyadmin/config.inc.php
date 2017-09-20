<?php
$cfg['blowfish_secret'] = 'INSERT_HERE_GENERATED_BLOWFISH_SECRET';
$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';
$cfg['PmaNoRelation_DisableWarning'] = true;

$i = 1;
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = 'localhost';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowNoPassword'] = false;
?>