upstream php {
    server {{ getenv "NGINX_BACKEND_HOST" }}:9000;
}

map $http_x_forwarded_proto $fastcgi_https {
    default $https;
    http '';
    https on;
}

server {
    server_name {{ getenv "NGINX_SERVER_NAME" "redaxo" }};
    listen 80 default_server{{ if getenv "NGINX_HTTP2" }} http2{{ end }};

    root {{ getenv "NGINX_SERVER_ROOT" "/var/www/html/" }};
    index {{ getenv "NGINX_INDEX_FILE" "index.php" }};

    include fastcgi.conf;
    include healthz.conf;
    include pagespeed.conf;

    if (!-d $request_filename) {
        rewrite ^/(.+)/$ /$1 permanent;
    }

    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        fastcgi_pass php;
        track_uploads uploads 60s;
    }

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    rewrite ^/sitemap\.xml$                           /index.php?rex_yrewrite_func=sitemap last;
    rewrite ^/robots\.txt$                            /index.php?rex_yrewrite_func=robots last;
    rewrite ^/media[0-9]*/imagetypes/([^/]*)/([^/]*)  /index.php?rex_media_type=$1&rex_media_file=$2&$args;
    rewrite ^/images/([^/]*)/([^/]*)                  /index.php?rex_media_type=$1&rex_media_file=$2&$args;
    rewrite ^/imagetypes/([^/]*)/([^/]*)              /index.php?rex_media_type=$1&rex_media_file=$2;

    if ($uri !~ "^redaxo/.*") {
        set $rule_6 4$rule_6;
    }

    if ($uri !~ "^media/.*"){
        set $rule_6 5$rule_6;
    }

    #!!! WICHTIG !!! Falls Let's Encrypt fehlschlägt, diese Zeile auskommentieren (sollte jedoch funktionieren)
    location ~ /\. { deny  all; }

    # Zugriff auf diese Verzeichnisse verbieten
    location ^~ /redaxo/src { deny  all; }
    location ^~ /redaxo/data { deny  all; }
    location ^~ /redaxo/cache { deny  all; }
    location ^~ /redaxo/bin { deny  all; }

    # In einigen Fällen könnte folgende Anweisung zusätlich sinnvoll sein.
    location ~ /\.(ttf|eot|woff|woff2)$ {
        add_header Access-Control-Allow-Origin *;
        expires 604800s;
    }

{{ if getenv "NGINX_SERVER_EXTRA_CONF_FILEPATH" }}
    include {{ getenv "NGINX_SERVER_EXTRA_CONF_FILEPATH" }};
{{ end }}
}
