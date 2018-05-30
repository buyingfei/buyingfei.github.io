---
title: 压力测试之ab 找到系统qps及负载
date: 2018-05-24 10:33:20
tags: 
- 压力测试
- ab 
categories:
- 压力测试
---
ab(Apache benchmark)是一款常用的压力测试工具。

**安装**
```bash
sudo yum install httpd-tools
```

**命令参数**
```bash

$ ab -h
Usage: ab [options] [http[s]://]hostname[:port]/path
Options are:
    -n requests     Number of requests to perform
    -c concurrency  [并发数 常用] Number of multiple requests to make 
    -t timelimit    [持续请求时间 常用]Seconds to max. wait for responses
    -b windowsize   Size of TCP send/receive buffer, in bytes
    -p postfile     File containing data to POST. Remember also to set -T
    -u putfile      File containing data to PUT. Remember also to set -T
    -T content-type Content-type header for POSTing, eg.
                    'application/x-www-form-urlencoded'
                    Default is 'text/plain'
    -v verbosity    How much troubleshooting info to print
    -w              Print out results in HTML tables
    -i              Use HEAD instead of GET
    -x attributes   String to insert as table attributes
    -y attributes   String to insert as tr attributes
    -z attributes   String to insert as td or th attributes
    -C attribute    Add cookie, eg. 'Apache=1234. (repeatable)
    -H attribute    Add Arbitrary header line, eg. 'Accept-Encoding: gzip'
                    Inserted after all normal header lines. (repeatable)
    -A attribute    Add Basic WWW Authentication, the attributes
                    are a colon separated username and password.
    -P attribute    Add Basic Proxy Authentication, the attributes
                    are a colon separated username and password.
    -X proxy:port   Proxyserver and port number to use
    -V              Print version number and exit
    -k              Use HTTP KeepAlive feature
    -d              Do not show percentiles served table.
    -S              Do not show confidence estimators and warnings.
    -g filename     Output collected data to gnuplot format file.
    -e filename     Output CSV file with percentages served
    -r              Don't exit on socket receive errors.
    -h              Display usage information (this message)
    -Z ciphersuite  Specify SSL/TLS cipher suite (See openssl ciphers)
    -f protocol     Specify SSL/TLS protocol (SSL2, SSL3, TLS1, or ALL)

```
本次测试以是否发生错误为准[nginx 报错以及ab 返回结果是否有错误]，测试环境为本地虚拟机centos 系统

测试接口(以get 方式)
http://tickets.2345.com:12345/tickets/m/help/getRootCategory?product=1&type=0

** 1 先并发200 同时请求**
```bash
$ ab -t 10 -c 200 'http://tickets.2345.com:12345/tickets/m/help/getRootCategory?product=1&type=0'
This is ApacheBench, Version 2.3 <$Revision: 655654 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking tickets.2345.com (be patient)
Completed 5000 requests
Completed 10000 requests
Completed 15000 requests
Completed 20000 requests
Completed 25000 requests
Completed 30000 requests
Finished 34664 requests


Server Software:        nginx [web服务器软件及版本]
Server Hostname:        tickets.2345.com [表示请求的URL中的主机部分名称]
Server Port:            12345 [被测试的Web服务器的监听端口]

Document Path:          /tickets/m/help/getRootCategory?product=1&type=0 [ 请求的页面路径]
Document Length:        298 bytes [页面大小]

Concurrency Level:      200 [并发数]
Time taken for tests:   10.000 seconds [测试总共花费的时间]
Complete requests:      34664 [完成的请求数]
Failed requests:        34136 [失败的请求数，这里的失败是指请求的连接服务器、发送数据、接收数据等环节发生异常，以及无响应后超时的情况。对于超时时间的设置可以用ab的-t参数。如果接受到的http响应数据的头信息中含有2xx以外的状态码，则会在测试结果显示另一个名为“Non-2xx responses”的统计项，用于统计这部分请求数，这些请求并不算是失败的请求。
只要出现Failed requests就会多一行数据来统计失败的原因，分别有Connect、Length、Exceptions。
Connect 无法送出要求、目标主机连接失败、要求的过程中被中断。
Length 响应的内容长度不一致 ( 以 Content-Length 头值为判断依据 )。
Exception 发生无法预期的错误。]
   (Connect: 0, Receive: 0, Length: 34136, Exceptions: 0)
Write errors:           0 [ 写入错误]
Non-2xx responses:      34136
Total transferred:      11432992 bytes [总共传输字节数，包含http的头信息等。使用ab的-v参数即可查看详细的http头信息。]
HTML transferred:       5823920 bytes [html字节数，实际的页面传递字节数。也就是减去了Total transferred中http响应数据中头信息的长度。]
Requests per second:    3466.37 [#/sec] (mean) [每秒处理的请求数，服务器的吞吐量]
Time per request:       57.697 [ms] (mean) [用户平均请求等待时间]
Time per request:       0.288 [ms] (mean, across all concurrent requests) [服务器平均处理时间]
Transfer rate:          1116.49 [Kbytes/sec] received [平均传输速率（每秒收到的速率）。可以很好的说明服务器在处理能力达到限制时，其出口带宽的需求量。]

Connection Times (ms) [压力测试时的连接处理时间。]
              min  mean[+/-sd] median   max
Connect:        0    0   1.2      0      17
Processing:     7   53 276.4     20    2617
Waiting:        7   53 276.4     20    2617
Total:          9   53 276.7     20    2617

Percentage of the requests served within a certain time (ms)
  50%     20
  66%     21
  75%     22
  80%     23
  90%     24
  95%     27
  98%     34
  99%   2443
 100%   2617 (longest request)
```
结果分析：
当并发数为200 时，34664 个请求，34136 个错误，放弃这次结果

** 2 并发120 同时请求**
```bash
$ ab -t 10 -c 120 'http://tickets.2345.com:12345/tickets/m/help/getRootCategory?product=1&type=0'
This is ApacheBench, Version 2.3 <$Revision: 655654 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking tickets.2345.com (be patient)
Finished 903 requests


Server Software:        nginx
Server Hostname:        tickets.2345.com
Server Port:            12345

Document Path:          /tickets/m/help/getRootCategory?product=1&type=0
Document Length:        298 bytes

Concurrency Level:      120
Time taken for tests:   10.010 seconds
Complete requests:      903
Failed requests:        0
Write errors:           0
Total transferred:      521031 bytes
HTML transferred:       269094 bytes
Requests per second:    90.21 [#/sec] (mean)
Time per request:       1330.250 [ms] (mean)
Time per request:       11.085 [ms] (mean, across all concurrent requests)
Transfer rate:          50.83 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    2   4.6      0      15
Processing:    28 1243 307.5   1283    1678
Waiting:       17 1243 307.6   1283    1678
Total:         29 1245 303.8   1284    1678

Percentage of the requests served within a certain time (ms)
  50%   1283
  66%   1306
  75%   1319
  80%   1335
  90%   1645
  95%   1660
  98%   1669
  99%   1671
 100%   1678 (longest request)

```
结果分析：
当并发数为120 时，903 个请求，0 个错误，这次结果待考证，是否能承载更大负载

**3 并发130 同时请求**

```bash

$ ab -t 10 -c 130 'http://tickets.2345.com:12345/tickets/m/help/getRootCategory?product=1&type=0'
This is ApacheBench, Version 2.3 <$Revision: 655654 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking tickets.2345.com (be patient)
Finished 1063 requests


Server Software:        nginx
Server Hostname:        tickets.2345.com
Server Port:            12345

Document Path:          /tickets/m/help/getRootCategory?product=1&type=0
Document Length:        298 bytes

Concurrency Level:      130
Time taken for tests:   10.007 seconds
Complete requests:      1063
Failed requests:        149
   (Connect: 0, Receive: 0, Length: 149, Exceptions: 0)
Write errors:           0
Non-2xx responses:      149
Total transferred:      575952 bytes
HTML transferred:       297106 bytes
Requests per second:    106.22 [#/sec] (mean)
Time per request:       1223.859 [ms] (mean)
Time per request:       9.414 [ms] (mean, across all concurrent requests)
Transfer rate:          56.20 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    1   3.2      0      10
Processing:     0 1133 538.7   1398    1557
Waiting:        0 1133 538.8   1398    1557
Total:          0 1134 537.9   1398    1557

Percentage of the requests served within a certain time (ms)
  50%   1398
  66%   1416
  75%   1423
  80%   1429
  90%   1535
  95%   1543
  98%   1549
  99%   1552
 100%   1557 (longest request)


```

结果分析：
当并发数为130 时，1063 个请求，149 个错误，这次结果待考证，此时请求QPS 在90~100 之间

这是否达到系统极限那？
通过sar -q、sar -u、sar -r 分析
系统cpu 占用还不到50%，IO 没有等待时长、内存也在系统承受范围之内，此时需要调整nginx 、php-fpm 等相关配置，来充分发挥系统性能。



