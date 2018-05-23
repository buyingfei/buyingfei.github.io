---
title: 系统监控之top 命令
date: 2018-05-23 17:42:05
tags: 测试 top 系统监控
categories:
- 操作系统
---
TOP命令是Linux下常用的性能分析工具，能够实时显示系统中各个进程的资源占用状况。可以根据top 命令初步判断系统发生问题
下面是对top 命令一些常用操作进行归总，方便分析系统问题
结果图示：默认以cpu 占用率倒序排列

![top 命令结果](/source/top.png)

**进程各字段含义：**
在top 命令在，按F 或者f 得到如下

![ top 各字段含义](/source/topprocname.png)

**得到帮助**
在top 命令在，按 h 得到如下

![ top help](/source/tophelp.png)

**根据内存使用情况倒序排列**
在top 命令在，按O后，按n，得到如下图示
![ top sort](/source/topsort.png)

结果如下
![ top sort result](/source/topsortresult.png)


**将当前所有系统进程，按内存占用情况倒序排列**
```bash
top -ab -n 1
```





