---
title: php-fpm 性能调优
date: 2018-05-30 10:11:56
tags: 
- 测试 
- 系统监控
categories:
- 压力测试
- 操作系统
---

前段时间，针对公司项目做了压力测试，本次做一次总结，并以本地环境和测试环境进行一次模拟,测试工具采用apache ab命令,测试过程注意观察nginx 错误日志，及php-fpm 错误日志，上线标准以不报错为准，并需要考虑系统需要为其它接口提供服务，进行斟酌
系统配置：
* 数据库放置在测试环境 双核cpu，4G内存
* 测试服务器在本机：单核CPU，2G内存

主要配置针对php-fpm 选项
```bash
user = buyf
group = buyf
pm = dynamic
pm.max_children = 1024
pm.start_servers = 1
pm.min_spare_servers = 1
pm.max_spare_servers = 8
```
**调整之前**
开始前php-fpm 配置
```bash
[global]
pid = /usr/local/php/var/run/php-fpm.pid
error_log = /usr/local/php/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi.sock
listen.backlog = 4096
listen.allowed_clients = 127.0.0.1
listen.owner = buyf
listen.group = buyf
listen.mode = 0666
user = buyf
group = buyf
pm = dynamic
pm.max_children = 1024
pm.start_servers = 1
pm.min_spare_servers = 1
pm.max_spare_servers = 8
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = /var/log/slow.log

```

采用130 个并发，此时测试结果
```bash
 ab -c 130 -t 100 'http://tickets.2345.com:12345/tickets/m/help/getRootCategory?product=1&type=0'
This is ApacheBench, Version 2.3 <$Revision: 655654 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking tickets.2345.com (be patient)
Completed 5000 requests
Finished 7450 requests


Server Software:        nginx
Server Hostname:        tickets.2345.com
Server Port:            12345

Document Path:          /tickets/m/help/getRootCategory?product=1&type=0
Document Length:        298 bytes

Concurrency Level:      130
Time taken for tests:   100.019 seconds
Complete requests:      7450
Failed requests:        0
Write errors:           0
Total transferred:      4298650 bytes
HTML transferred:       2220100 bytes
Requests per second:    74.49 [#/sec] (mean)
Time per request:       1745.297 [ms] (mean)
Time per request:       13.425 [ms] (mean, across all concurrent requests)
Transfer rate:          41.97 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   3.4      0      35
Processing:    29 1729 270.2   1706    4722
Waiting:       23 1729 270.3   1706    4722
Total:         30 1730 269.5   1706    4722

Percentage of the requests served within a certain time (ms)
  50%   1706
  66%   1753
  75%   1791
  80%   1821
  90%   1938
  95%   2254
  98%   2451
  99%   2563
 100%   4722 (longest request)

```

此时所有请求都被正确处理，nginx 没有错误日志产生，php-fpm 有warn 报错：如下
```bash
[30-May-2018 10:29:11] WARNING: [pool www] seems busy (m.start_servers, or pm.min/max_spare_servers), spawningidle, and 82 total children

```
此时系统负载，cpu 占用率很高，但内存还有很大空余
```bash
top - 10:32:26 up 5 days, 17:56,  6 users,  load aver
Tasks: 142 total,  21 running, 121 sleeping,   0 stop
Cpu(s): 75.6%us, 20.1%sy,  0.0%ni,  0.0%id,  0.0%wa, 
Mem:   1906912k total,   829696k used,  1077216k free
Swap:  2031612k total,    89856k used,  1941756k free
```

此时调整并发为140，nginx 有大量错误日志产品，说明此时qps为130

**调整之后**

调整fpm参数为
```bash
pm = dynamic
pm.max_children = 1024
pm.start_servers = 108
pm.min_spare_servers = 108
pm.max_spare_servers = 1024

```
此时采用400 并发
测试结果如下
```bash
ab -c 400 -t 2 'http://tickets.2345.com:12345/tickets/m/help/getRootCategory?product=1&type=0'
This is ApacheBench, Version 2.3 <$Revision: 655654 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking tickets.2345.com (be patient)
Finished 27 requests


Server Software:        nginx
Server Hostname:        tickets.2345.com
Server Port:            12345

Document Path:          /tickets/m/help/getRootCategory?product=1&type=0
Document Length:        298 bytes

Concurrency Level:      400
Time taken for tests:   3.161 seconds
Complete requests:      27
Failed requests:        0
Write errors:           0
Total transferred:      15579 bytes
HTML transferred:       8046 bytes
Requests per second:    8.54 [#/sec] (mean)
Time per request:       46832.267 [ms] (mean)
Time per request:       117.081 [ms] (mean, across all concurrent requests)
Transfer rate:          4.81 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0  214  42.7    222     222
Processing:    38 1536 399.1   1540    2913
Waiting:       22 1535 401.3   1540    2913
Total:         38 1749 432.0   1762    3135

Percentage of the requests served within a certain time (ms)
  50%   1762
  66%   1763
  75%   1764
  80%   1765
  90%   1765
  95%   1765
  98%   3135
  99%   3135
 100%   3135 (longest request)

```

如果并发420 ，产生大量nginx 错误日志
```bash
2018/05/30 10:46:03 [error] 86422#0: *1844747 connect() to unix:/tmp/php-cgi.sock failed (11: Resource temporarily unavailable) while connecting to upstream, client: 127.0.0.1, server: tickets.2345.com, request: "GET /tickets/m/help/getRootCategory?product=1&type=0 HTTP/1.0", upstream: "fastcgi://unix:/tmp/php-cgi.sock:", host: "tickets.2345.com:12345"

```

此时系统负载
```bash
top - 10:47:35 up 5 days, 18:11,  6 users,  load average: 28.15, 12.47, 7.81
Tasks: 482 total,  56 running, 426 sleeping,   0 stopped,   0 zombie
Cpu(s): 71.1%us, 23.1%sy,  0.0%ni,  0.0%id,  0.0%wa,  1.2%hi,  4.7%si,  0.0%st
Mem:   1906912k total,  1834432k used,    72480k free,    48024k buffers
Swap:  2031612k total,    96184k used,  1935428k free,   168776k cached

```
测试cpu、内存基本占用都已100%，达到系统瓶颈

**调整后qps 从130 到400 ，效率提高了3、4倍，可见是有质的提升。**

### 进一步提升系统性能
1 采用opcache 进行缓存
2 增加机器，进行代理转发
3 采用swoole ，此时不需要进行php-fpm 转发，减少中间环节








