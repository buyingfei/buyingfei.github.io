---
title: 简单 golang 接口限流
date: 2018-05-11 15:49:13
tags: 限制流量 golang 高并发
categories:
- golang
---

曾经在一个[大神的博客](http://jinnianshilongnian.iteye.com/blog/2305117)里看到这样一句话：在开发高并发系统时，有三把利器用来保护系统：缓存、降级和限流。那么何为限流呢？顾名思义，限流就是限制流量，就像你宽带包了1个G的流量，用完了就没了。通过限流，我们可以很好地控制系统的qps，从而达到保护系统的目的。本篇文章将会介绍一下计数器限流算法并用golang 实现。

***计数器法***

计数器法是限流算法里最简单也是最容易实现的一种算法。比如我们规定，对于A接口来说，我们1分钟的访问次数不能超过100个。那么我们可以这么做：在一开始的时候，我们可以设置一个计数器counter，每当一个请求过来的时候，counter就加1，如果counter的值大于100并且该请求与第一个请求的间隔时间还在1分钟之内，那么说明请求数过多；如果该请求与第一个请求的间隔时间大于1分钟，且counter的值还在限流范围内，那么就重置counter，具体算法的示意图如下：
![计数器算法](/source/limitqps.png)

伪代码 如下：
```golang
public class CounterDemo {
    public long timeStamp = getNowTime();
    public int reqCount = 0;
    public final int limit = 100; // 时间窗口内最大请求数
    public final long interval = 1000; // 时间窗口ms
    public boolean grant() {
        long now = getNowTime();
        if (now < timeStamp + interval) {
            // 在时间窗口内
            reqCount++;
            // 判断当前时间窗口内是否超过最大请求控制数
            return reqCount <= limit;
        }
        else {
            timeStamp = now;
            // 超时后重置
            reqCount = 1;
            return true;
        }
    }
}
```

实现代码：
```golang
package main

import (
	"fmt"
	"io"
	"net/http"
	"sync"
	"time"
	"strings"
)

type RequestLimitStruct struct {
	RequestCnt map[string] int
	Lock     sync.Mutex
}

type RequestLimitService struct {
	Interval time.Duration
	MaxCount int
	RequestLimit RequestLimitStruct
}

func NewRequestLimitService(interval time.Duration, maxCnt int) *RequestLimitService {
	reqLimit := &RequestLimitService{
		Interval: interval,
		MaxCount: maxCnt,
	}
	reqLimit.RequestLimit.RequestCnt = make(map[string]int)

	go func() {
		ticker := time.NewTicker(interval)
		for {
			<-ticker.C
			reqLimit.RequestLimit.Lock.Lock()
			fmt.Println("Reset Count...")
			for key,_ := range reqLimit.RequestLimit.RequestCnt {
				reqLimit.RequestLimit.RequestCnt[key] = 0
			}
			reqLimit.RequestLimit.Lock.Unlock()
		}
	}()

	return reqLimit
}

func (reqLimit *RequestLimitService) Increase(r *http.Request) {
	reqLimit.RequestLimit.Lock.Lock()
	defer reqLimit.RequestLimit.Lock.Unlock()

	remoteIP := strings.Split(r.RemoteAddr, ":")[0]
	requestUri := r.RequestURI
	key := remoteIP + string(':') + requestUri
	if v, exists := reqLimit.RequestLimit.RequestCnt[key]; exists {
		reqLimit.RequestLimit.RequestCnt[key] = v + 1
	} else {
		reqLimit.RequestLimit.RequestCnt[key] = 1
	}
	fmt.Println("请求" + key + " " + string(reqLimit.RequestLimit.RequestCnt[key]))
}

func (reqLimit *RequestLimitService) IsAvailable(r *http.Request) bool {
	remoteIP := strings.Split(r.RemoteAddr, ":")[0]
	requestUri := r.RequestURI
	key := remoteIP + string(':') + requestUri
	reqLimit.RequestLimit.Lock.Lock()
	defer reqLimit.RequestLimit.Lock.Unlock()
	if v, exists := reqLimit.RequestLimit.RequestCnt[key]; exists {
		reqLimit.RequestLimit.RequestCnt[key] = v + 1
	}
	return reqLimit.RequestLimit.RequestCnt[key] < reqLimit.MaxCount
}

var RequestLimit = NewRequestLimitService(10*time.Second, 5)

func HttpHander(w http.ResponseWriter, r *http.Request) {
	remoteIP := strings.Split(r.RemoteAddr, ":")[0]
	requestUri := r.RequestURI
	key := remoteIP + string(':') + requestUri
	if RequestLimit.IsAvailable(r) {
		RequestLimit.Increase(r)
		fmt.Println(RequestLimit.RequestLimit.RequestCnt[key])
		io.WriteString(w, "Hello world!\n")
	} else {
		fmt.Println("Reach request limiting!")
		io.WriteString(w, "Reach request limit!\n")
	}
}

func main() {
	fmt.Println("Server Started!")
	http.HandleFunc("/", HttpHander)
	http.ListenAndServe(":8000", nil)
}

```


发送请求：
```bash
seq 100 | xargs -P10 -I% curl localhost:8000
```

相应结果：

![相应结果](/source/qpslimitresult.png)



