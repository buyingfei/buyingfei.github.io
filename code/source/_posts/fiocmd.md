---
title: 压力测试 之系统io 性能
date: 2018-05-21 20:49:08
tags: 测试 fio 系统监控
categories:
- 压力测试
---

**fio 工具简介**
Linux系统上采用fio工具来对硬盘进行的IO测试。

**sysstat 安装**
```bash
sudo yum -y install fio
```
```bash
可以使用fio -help查看每个参数，具体的参数左右可以在官网查看how to文档，如下为几个常见的参数描述
filename=/tmp/fio　支持文件系统或者裸设备，-filename=/dev/sda2或-filename=/dev/sdb
direct=1                 测试过程绕过机器自带的buffer，使测试结果更真实
rw=randwread             测试随机读的I/O
rw=randwrite             测试随机写的I/O
rw=randrw                测试随机混合写和读的I/O
rw=read                  测试顺序读的I/O
rw=write                 测试顺序写的I/O
rw=rw                    测试顺序混合写和读的I/O
bs=4k                    单次io的块文件大小为4k
bsrange=512-2048         同上，提定数据块的大小范围
size=5g                  本次的测试文件大小为5g，以每次4k的io进行测试
numjobs=30               本次的测试线程为30
runtime=1000             测试时间为1000秒，如果不写则一直将5g文件分4k每次写完为止
ioengine=psync           io引擎使用pync方式，如果要使用libaio引擎，需要yum install libaio-devel包
rwmixwrite=30            在混合读写的模式下，写占30%
group_reporting          关于显示结果的，汇总每个进程的信息
此外
lockmem=1g               只使用1g内存进行测试
zero_buffers             用0初始化系统buffer
nrfiles=8                每个进程生成文件的数量

```
**fio测试场景及生成报告详解**
```bash
#100%随机，100%读， 4K
fio -filename=/tmp/fio -direct=1 -iodepth 1 -thread -rw=randread -ioengine=psync -bs=4k -size=1000G -numjobs=10 -runtime=30 -group_reporting -name=fiotest

#100%随机，100%写， 4K
fio -filename=/tmp/fio -direct=1 -iodepth 1 -thread -rw=randwrite -ioengine=psync -bs=4k -size=1000G -numjobs=10 -runtime=30 -group_reporting -name=fiotest

#100%顺序，100%读 ，4K
fio -filename=/tmp/fio -direct=1 -iodepth 1 -thread -rw=read -ioengine=psync -bs=4k -size=1000G -numjobs=10 -runtime=30 -group_reporting -name=fiotest

#100%顺序，100%写 ，4K
fio -filename=/tmp/fio -direct=1 -iodepth 1 -thread -rw=write -ioengine=psync -bs=4k -size=1000G -numjobs=10 -runtime=30 -group_reporting -name=fiotest

#100%随机，70%读，30%写 4K
fio -filename=/tmp/fio -direct=1 -iodepth 1 -thread -rw=randrw -rwmixread=70 -ioengine=psync -bs=4k -size=1000G -numjobs=10 -runtime=30 -group_reporting -name=fiotest
```


运行一下命令，进行分析
```bash
fio -filename=/tmp/fio -direct=1 -iodepth 1 -thread -rw=randrw -rwmixread=70 -ioengine=psync -bs=4k -size=1000G -numjobs=10 -runtime=30 -group_reporting -name=fiotest
```

结果图示：
![fio](/source/fio.png)

```bash

io=执行了多少M的IO

bw=平均IO带宽
iops=IOPS
runt=线程运行时间
slat=提交延迟
clat=完成延迟
lat=响应时间
bw=带宽
cpu=利用率
IO depths=io队列
IO submit=单个IO提交要提交的IO数
IO complete=Like the above submit number, but for completions instead.
IO issued=The number of read/write requests issued, and how many of them were short.
IO latencies=IO完延迟的分布

io=总共执行了多少size的IO
aggrb=group总带宽
minb=最小.平均带宽.
maxb=最大平均带宽.
mint=group中线程的最短运行时间.
maxt=group中线程的最长运行时间.

ios=所有group总共执行的IO数.
merge=总共发生的IO合并数.
ticks=Number of ticks we kept the disk busy.
io_queue=花费在队列上的总共时间.
util=磁盘利用率

```
