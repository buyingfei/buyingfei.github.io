---
title: tcpdump 抓包及Wireshark 解析包实例
date: 2018-05-07 10:17:45
tags:
- 网络抓包
categories:
- 操作系统
---
 项目发布生产环境，很多都会使用到nginx 反向代理，开发过程中nginx 没有反向代理，
 前2 天发布到线上由于对生产环境不熟悉，造成websocket 中代理这块出现问题，然后
 自己在开发环境nginx 这里也做了nginx 反向代理，所有websocket 请求，反向代理到
 我们测试环境，模拟线上环境（nginx 代理转发），乘次机会也对抓包做一次总结。
 

 项目要求，不开放websocket 端口对外，访问websocket ，要请求nginx 对外开放对口，
 及nginx server 模块中 listen 对应对口，然后nginx 做代理转发，转发到后台服务端口
 注:线上有两天nginx服务器，一台做代理机，一台做服务机,
 此时自己开发机器[192.168.132.128]作为代理机，测试服务器[172.16.0.56] 作为服务机
 
 自己开发机器[192.168.132.128]nginx 配置
 
 ```nginx

upstream websocket {
    server 127.0.0.1:9501;
}


upstream globalWebsocket {
    # 转发到测试机
    server 172.16.0.56:9588;
}

map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

server
    {
        listen 12345;
        #listen [::]:80;
        server_name tickets.2345.com ;
	charset utf-8;
        index index.html index.htm index.php default.html default.htm default.php;
        root  /home/buyf/quest/backend/web;

        #include /home/buyf/quest.2345.com/backend/web.conf;
        #error_page   404   /404.html;

        # Deny access to PHP files in specific directory
        #location ~ /(wp-content|uploads|wp-includes|images)/.*\.php$ { deny all; }
	location = /tickets {
        rewrite .* /index.html last;
    }

    location = /tickets/ {
        rewrite .* /index.html last;
    }

    location ~ /tickets {

        rewrite ^/tickets(/.*) $1 last;
    }

    location / {
        client_max_body_size    1000m;
        set $new_uri $uri;
        add_header Access-Control-Allow-Origin  '*';
        add_header Access-Control-Allow-Methods 'GET,POST,OPTIONS';
        try_files $uri $uri/ /index.php?$query_string;
    }
    #location = /tickets/websocket {
       # proxy_pass ws://tickets.2345.com:9501 ;
    #}
    location ~ /appManage(/.*) {
		set $root_path appManage;
		root /opt/case/dkwapp.2345.com/dkwapp/web;
		set $new_uri $1;
		try_files $1 $1/ /index.php?$query_string;
	}

	location ~ /websocket {
		proxy_pass http://websocket;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
	}


	location ~ /globalWebsocket {
         #   proxy_pass http://tickets.2345.com:9588;
		proxy_pass http://globalWebsocket;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "Upgrade";
	}
        #include enable-php.conf;

   location ~ \.php$ {
        fastcgi_pass  unix:/tmp/php-cgi.sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include        fastcgi_params;
        fastcgi_param REQUEST_URI $new_uri;
        fastcgi_intercept_errors off;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }


     

        location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$
        {
            add_header Access-Control-Allow-Origin  'http://tickets.2345.com:8090';
            add_header Access-Control-Allow-Methods 'GET,POST,OPTIONS';
            expires      30d;
        }

        location ~ .*\.(js|css|json)?$
        {
            expires      12h;
        }

        location ~ /.well-known {
            allow all;
        }

        location ~ /\.
        {
            deny all;
        }

        access_log  /home/wwwlogs/quest.2345.com.access.log;
        error_log  /home/wwwlogs/quest.2345.com.error.log notice;
    }



```

服务机[172.16.0.56] nginx 配置
``` nginx
upstream websocket {
	server 127.0.0.1:9501;
}
upstream globalWebsocket {
    server 127.0.0.1:9588;
}


log_format  post  '$remote_addr - $remote_user [$time_local] "$request" '
				 '$status $body_bytes_sent $request_time $upstream_response_time "$http_referer" '
				 '"$http_user_agent" "$http_x_forwarded_for" body: $request_body';

server {
    listen       12345;
    server_name  quest.2345.com 172.16.0.56 www.waptianqi.com;
    index index.html index.htm index.php;
	access_log logs/quest.2345.com_access.log main;
	error_log logs/quest.2345.com_error.log notice;
	set $next_root /opt/case/quest.2345.com/backend/web;

	charset  utf-8;
	
	if ($request_uri ~ '/appManage') {
		set $next_root /opt/case/dkwapp.2345.com/web;
	}
	
	root $next_root;

	location = /appManage {
		rewrite .* /index.html last;
	}

	location = /appManage/ {
		rewrite .* /index.html last;
	}

	location = /appManage/index.html {
		rewrite .* /index.html last;
	}

	location /appManage {
		rewrite ^/appManage(/.*) $1 last;
	}

	location = /tickets {
		rewrite .* /index.html last;
	}

	location = /tickets/ {
		rewrite .* /index.html last;
	}
	
	location = /tickets/index.html {
		rewrite .* /index.html last;
	}

	location /tickets {
		rewrite ^/tickets(/.*) $1 last;
	}

	# websocket
	location = /websocket {
	    proxy_pass http://websocket;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_read_timeout 3600s;
	}
	location ~ /globalWebsocket {
		proxy_pass http://globalWebsocket;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "Upgrade";
	}

	
	location / {
		set $new_uri $uri;
		try_files $uri $uri/ /index.php?$query_string;
	}

	location ~ \.php$ {
		fastcgi_pass   127.0.0.1:9002;
		fastcgi_index  index.php;
		fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
		include        fastcgi_params;
		fastcgi_param REQUEST_URI $new_uri;

		if ($request_method = 'POST') {
			access_log logs/quest.2345.com_access.log post;
		}

		# 开发使用
		fastcgi_intercept_errors off;
		fastcgi_connect_timeout 300;
		fastcgi_send_timeout 300;
		fastcgi_read_timeout 300;
	}
}

```

进行对9588 websocket 端口进行抓包
```bash
sudo  tcpdump -i eth0  port 9588 -w /tmp/buyf.cap
```
![websocket 请求](https://buyingfei.github.io/img/websocket.png)

使用Wireshark 进行网络分析
![packets 详情](https://buyingfei.github.io/img/packets.png)
进而可以分析出整个通信过程。





 
 
  
 
