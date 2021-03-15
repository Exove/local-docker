FROM xoxoxo/php-drupal:7.4-1.0

# Configure PHP for local development.
COPY ./conf.d/90-mailhog.ini /usr/local/etc/php/conf.d/90-mailhog.ini

# Configure PHP to send all mail to Mailhog.
COPY ./conf.d/95-drupal-development.ini /usr/local/etc/php/conf.d/95-drupal-development.ini

# Add some aliases to Bash
COPY ./bash/bashrc /root/.bashrc
