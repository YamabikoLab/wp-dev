<?php

add_filter('wp_mail_from', static fn(): string => 'wordpress@example.test');

add_filter('wp_mail_from_name', static fn(): string => 'WordPress Development');
