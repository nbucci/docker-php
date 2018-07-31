FROM php:7.2-stretch

LABEL maintainer="Nicola Bucci <nicola.bucci82@gmail.com>" \
      php_version="7.2"

# Set environment variables
ENV IMAGE_USER=localuser
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/$IMAGE_USER
ENV COMPOSER_HOME=$HOME/.composer

USER root

# Install required packages
RUN dpkg-reconfigure -f noninteractive tzdata \ 
	&& bash -c 'echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup' \
	&& bash -c 'echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache' \
      	&& DEBIAN_FRONTEND=noninteractive apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      	apt-transport-https \
      	openssh-client \
      	unzip \
      	git \
      	curl \
      	libc-client-dev \
      	zlib1g-dev \
      	apt-utils \
      	rsync \
      	sudo \
      	gnupg2 \
        gettext \
      	python \
      	python-dev \
      	default-libmysqlclient-dev \
      	libbz2-dev \
      	libsasl2-dev \
      	libfreetype6-dev \
      	libicu-dev \
      	libjpeg-dev \
      	libldap2-dev \
      	libmemcachedutil2 \
      	libmemcached-dev \
      	libpng-dev \
      	libpq-dev \
      	libxml2-dev \
      	libmagickwand-dev \
      	imagemagick \
      	libssl-dev \
	libkrb5-dev \
        libxext6 \
        libxrender1 \
        libfontconfig1 \
        wget \
        xvfb \
	xfonts-75dpi \
        xfonts-base \
        wkhtmltopdf \
        python3 \
        python3-dev 

# Install PHP libs
RUN docker-php-ext-install -j$(nproc) exif xml xmlrpc pcntl bcmath bz2 calendar iconv intl mbstring mysqli opcache pdo_mysql pdo_pgsql pgsql soap zip \
    	&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    	&& docker-php-ext-install -j$(nproc) gd \
   	&& docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
   	&& docker-php-ext-install -j$(nproc) ldap \
    	&& docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    	&& docker-php-ext-install -j$(nproc) imap \
    	&& git clone --branch REL3_0 https://github.com/php-memcached-dev/php-memcached /usr/src/php/ext/memcached/ \
    	&& docker-php-ext-install memcached \
    	&& docker-php-ext-enable memcached \
    	&& pecl channel-update pecl.php.net \
    	&& pecl install redis apcu mongodb imagick xdebug \
    	&& docker-php-ext-enable redis apcu mongodb imagick xdebug \
    	&& docker-php-source delete \
    	&& rm -r /var/lib/apt/lists/*

# Create local user
RUN adduser --disabled-password --gecos "" $IMAGE_USER && \
       echo "$IMAGE_USER  ALL = ( ALL ) NOPASSWD: ALL" >> /etc/sudoers && \
       mkdir -p /var/www/html && \
       chown -R $IMAGE_USER:$IMAGE_USER /var/www $HOME /tmp

# Composer
COPY --from=composer:1.6 /usr/bin/composer /usr/bin/composer

RUN echo "memory_limit = 4096M" >> /usr/local/etc/php/conf.d/memory-limit.ini

USER $IMAGE_USER

WORKDIR $HOME

# AWS Cli
RUN curl -O https://bootstrap.pypa.io/get-pip.py \
	&& python3 get-pip.py --user \
	&& $HOME/.local/bin/pip install awscli --upgrade --user \
	&& sudo ln -s $HOME/.local/bin/aws /usr/bin/aws

